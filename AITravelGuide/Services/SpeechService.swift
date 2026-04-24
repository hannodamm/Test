import AVFoundation
import MediaPlayer
import SwiftUI

@MainActor
final class SpeechService: NSObject, ObservableObject {
    @Published var isSpeaking = false
    @Published var isPaused = false

    private let synthesizer = AVSpeechSynthesizer()
    private var delegateHandler: SpeechDelegateHandler?
    private var audioPlayer: AVAudioPlayer?
    private var audioPlayerDelegate: AudioPlayerDelegateHandler?
    private var cachedVoice: AVSpeechSynthesisVoice?
    private var isUsingOpenAI = false
    private var cachedNarrations: [String: String] = [:]
    private var preloadTasks: [String: Task<String?, Never>] = [:]
    private var currentTempFileURL: URL?

    // Streaming narration state: while a stream is active, `isSpeaking` is held
    // true across the queue of per-sentence utterances rather than bouncing on
    // every `didFinish`.
    private var streamingUtterancesInFlight = 0
    private var streamingIsReceiving = false
    private var streamingTask: Task<Void, Never>?

    // Lock-screen / AirPods remote-command callbacks supplied by the tour view.
    private var onRemoteNext: (() -> Void)?
    private var onRemotePrevious: (() -> Void)?
    private var remoteCommandsConfigured = false

    /// Reads voice-enabled preference from UserDefaults (toggled in Settings)
    var voiceEnabled: Bool {
        UserDefaults.standard.object(forKey: "voiceEnabled") as? Bool ?? true
    }

    private var speechRateValue: Float {
        let index = UserDefaults.standard.integer(forKey: "speechRateIndex")
        switch index {
        case 0: return 0.35  // slow — relaxed pace
        case 2: return 0.45  // fast — brisk but still clear
        default: return 0.40 // normal — conversational
        }
    }

    /// Finds the best available English voice, preferring premium > enhanced > default
    private var preferredVoice: AVSpeechSynthesisVoice? {
        if let cached = cachedVoice { return cached }

        let voices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }

        // Try premium first, then enhanced, then fall back to default en-US
        let voice = voices.first(where: { $0.quality == .premium })
            ?? voices.first(where: { $0.quality == .enhanced })
            ?? AVSpeechSynthesisVoice(language: "en-US")

        cachedVoice = voice
        return voice
    }

    override init() {
        super.init()
        delegateHandler = SpeechDelegateHandler { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                if self.streamingUtterancesInFlight > 0 {
                    self.streamingUtterancesInFlight -= 1
                }
                // Only clear speaking state once the stream has finished
                // delivering chunks AND all queued utterances are done.
                if !self.streamingIsReceiving && self.streamingUtterancesInFlight == 0 {
                    self.isSpeaking = false
                    self.isPaused = false
                }
            }
        }
        synthesizer.delegate = delegateHandler

        audioPlayerDelegate = AudioPlayerDelegateHandler { [weak self] in
            Task { @MainActor in
                self?.isSpeaking = false
                self?.isPaused = false
                self?.isUsingOpenAI = false
            }
        }

        configureRemoteCommands()
    }

    // MARK: - Lock-screen / AirPods controls

    /// Called once at init. Lock-screen controls need to be registered before
    /// audio first plays, otherwise they won't appear on the first narration.
    private func configureRemoteCommands() {
        guard !remoteCommandsConfigured else { return }
        remoteCommandsConfigured = true

        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.resume() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.isPaused { self.resume() } else if self.isSpeaking { self.pause() }
            }
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.onRemoteNext?() }
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.onRemotePrevious?() }
            return .success
        }

        center.nextTrackCommand.isEnabled = false
        center.previousTrackCommand.isEnabled = false
    }

    /// Wire tour-navigation callbacks so AirPods triple-tap / lock-screen next
    /// advances tour stops. Clears when callbacks are set to nil.
    func setRemoteTourCallbacks(next: (() -> Void)?, previous: (() -> Void)?) {
        onRemoteNext = next
        onRemotePrevious = previous
        let center = MPRemoteCommandCenter.shared()
        center.nextTrackCommand.isEnabled = next != nil
        center.previousTrackCommand.isEnabled = previous != nil
    }

    /// Publish what the user is listening to on the lock screen and Control Center.
    func updateNowPlaying(title: String, subtitle: String?) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0
        ]
        if let subtitle { info[MPMediaItemPropertyArtist] = subtitle }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Public API

    func speak(_ text: String) {
        stop()
        guard voiceEnabled, !text.isEmpty else { return }

        if APIKeyManager.shared.hasOpenAIKey {
            isUsingOpenAI = true
            isSpeaking = true
            Task { await speakWithOpenAI(text) }
        } else {
            speakWithAVSpeech(text)
        }
    }

    func pause() {
        if isUsingOpenAI {
            audioPlayer?.pause()
        } else {
            synthesizer.pauseSpeaking(at: .word)
        }
        isPaused = true
        isSpeaking = false
    }

    func resume() {
        if isUsingOpenAI {
            audioPlayer?.play()
        } else {
            synthesizer.continueSpeaking()
        }
        isPaused = false
        isSpeaking = true
    }

    func stop() {
        streamingTask?.cancel()
        streamingTask = nil
        streamingIsReceiving = false
        streamingUtterancesInFlight = 0
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        audioPlayer?.stop()
        audioPlayer = nil
        if let tempFile = currentTempFileURL {
            try? FileManager.default.removeItem(at: tempFile)
            currentTempFileURL = nil
        }
        isSpeaking = false
        isPaused = false
        isUsingOpenAI = false
    }

    func toggle(_ text: String) {
        if isPaused {
            resume()
        } else if isSpeaking {
            pause()
        } else {
            speak(text)
        }
    }

    // MARK: - OpenAI TTS

    private func speakWithOpenAI(_ text: String) async {
        guard let apiKey = APIKeyManager.shared.openAIAPIKey else {
            speakWithAVSpeech(text)
            return
        }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/speech")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "tts-1",
            "voice": "nova",
            "input": text
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                // Fallback to AVSpeech on API error
                speakWithAVSpeech(text)
                return
            }

            // Clean up previous temp file before creating new one
            if let previous = currentTempFileURL {
                try? FileManager.default.removeItem(at: previous)
            }
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("tts_\(UUID().uuidString).mp3")
            try data.write(to: tempURL)
            currentTempFileURL = tempURL

            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)

            let player = try AVAudioPlayer(contentsOf: tempURL)
            player.delegate = audioPlayerDelegate
            self.audioPlayer = player
            self.isUsingOpenAI = true
            self.isSpeaking = true
            player.play()
        } catch {
            // Fallback to AVSpeech on any error
            speakWithAVSpeech(text)
        }
    }

    // MARK: - AVSpeech (fallback)

    private func speakWithAVSpeech(_ text: String) {
        isUsingOpenAI = false

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speechRateValue
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.3
        utterance.postUtteranceDelay = 0.1
        utterance.volume = 0.9
        utterance.voice = preferredVoice
        isSpeaking = true
        isPaused = false
        synthesizer.speak(utterance)
    }

    // MARK: - Natural Narrations

    func speakStopDescription(_ stop: TourStop, guidePersona: GuidePersona? = nil) {
        var parts: [String] = []

        if guidePersona != nil {
            parts.append("So, this is \(stop.name).")
        } else {
            parts.append("Welcome to \(stop.name).")
        }
        parts.append(stop.description)

        if let note = stop.historicalNote {
            parts.append("Here's something interesting. \(note)")
        }
        if let tip = stop.tips {
            parts.append("One more thing. \(tip)")
        }

        speak(parts.joined(separator: " ... "))
    }

    /// Consume a sentence-chunk stream and enqueue each chunk as its own
    /// AVSpeechUtterance. AVSpeechSynthesizer queues utterances natively with
    /// imperceptible gap, so the listener hears continuous narration.
    /// Streaming forces the AVSpeech path — the OpenAI TTS route is incompatible
    /// with per-sentence streaming without per-sentence round-trips.
    func speakStreaming(
        _ stream: AsyncThrowingStream<String, Error>,
        fallbackText: String?
    ) async {
        stop()
        guard voiceEnabled else { return }

        streamingIsReceiving = true
        streamingUtterancesInFlight = 0
        isUsingOpenAI = false
        isSpeaking = true
        isPaused = false

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)

        do {
            for try await chunk in stream {
                enqueueStreamedUtterance(chunk)
            }
            streamingIsReceiving = false
            // No chunks arrived at all — fall back to a one-shot narration.
            if streamingUtterancesInFlight == 0, let fallback = fallbackText {
                speakWithAVSpeech(fallback)
            } else if streamingUtterancesInFlight == 0 {
                isSpeaking = false
            }
        } catch {
            streamingIsReceiving = false
            // Stream failed before any audio played — fall back.
            if streamingUtterancesInFlight == 0, let fallback = fallbackText {
                speakWithAVSpeech(fallback)
            } else if streamingUtterancesInFlight == 0 {
                isSpeaking = false
            }
            // If some utterances already queued, let them play out and stop there.
        }
    }

    private func enqueueStreamedUtterance(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speechRateValue
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0
        utterance.postUtteranceDelay = 0.15
        utterance.volume = 0.9
        utterance.voice = preferredVoice
        streamingUtterancesInFlight += 1
        synthesizer.speak(utterance)
    }

    /// Preload narration text for a stop (call while user reviews tour preview)
    func preloadStopNarration(_ stop: TourStop, tour: Tour?) async {
        guard APIKeyManager.shared.hasAPIKey else { return }
        guard cachedNarrations[stop.name] == nil else { return }
        guard preloadTasks[stop.name] == nil else { return }

        let context = buildMinimalContext(stop: stop, tour: tour)
        let persona = tour?.guidePersona

        let task = Task<String?, Never> {
            let claudeAPI = ClaudeAPIService()
            return await claudeAPI.narrateStop(
                stop: stop,
                locationContext: context,
                guidePersona: persona
            )
        }
        preloadTasks[stop.name] = task

        if let narration = await task.value {
            cachedNarrations[stop.name] = narration
        }
        preloadTasks[stop.name] = nil
    }

    /// Clear preloaded narration cache (call on tour discard/end)
    func clearNarrationCache() {
        cachedNarrations.removeAll()
        preloadTasks.values.forEach { $0.cancel() }
        preloadTasks.removeAll()
    }

    /// AI-powered narration with fallback to template text. When an API key is
    /// set and no preloaded cache hit exists, streams narration from Claude so
    /// the first audio lands in ~500ms instead of 2–5 s.
    func speakStopNarration(_ stop: TourStop, tour: Tour?) async {
        let persona = tour?.guidePersona
        updateNowPlaying(title: stop.name, subtitle: stopSubtitle(stop, tour: tour))

        // Use cached narration if available (preloaded during preview)
        if let cached = cachedNarrations[stop.name] {
            speak(cached)
            return
        }

        // If a preload is in progress, await it instead of streaming a second time
        if let preloadTask = preloadTasks[stop.name] {
            if let narration = await preloadTask.value {
                cachedNarrations[stop.name] = narration
                speak(narration)
                return
            }
        }

        if APIKeyManager.shared.hasAPIKey {
            let context = buildMinimalContext(stop: stop, tour: tour)
            let claudeAPI = ClaudeAPIService()
            let fallback = templateNarration(for: stop, persona: persona)

            if let stream = claudeAPI.streamNarrateStop(
                stop: stop,
                locationContext: context,
                guidePersona: persona
            ) {
                await speakStreaming(stream, fallbackText: fallback)
                return
            }
        }

        // No API key — fall back to the template narration.
        speakStopDescription(stop, guidePersona: persona)
    }

    private func stopSubtitle(_ stop: TourStop, tour: Tour?) -> String? {
        guard let tour,
              let idx = tour.stops.firstIndex(where: { $0.id == stop.id }) else { return nil }
        return "Stop \(idx + 1) of \(tour.stops.count) · \(tour.name)"
    }

    private func templateNarration(for stop: TourStop, persona: GuidePersona?) -> String {
        var parts: [String] = []
        parts.append(persona != nil ? "So, this is \(stop.name)." : "Welcome to \(stop.name).")
        parts.append(stop.description)
        if let note = stop.historicalNote { parts.append("Here's something interesting. \(note)") }
        if let tip = stop.tips { parts.append("One more thing. \(tip)") }
        return parts.joined(separator: " ... ")
    }

    private func buildMinimalContext(stop: TourStop, tour: Tour?) -> LocationContext {
        LocationContext(
            city: tour?.locationName != "the area" ? tour?.locationName : nil,
            country: nil,
            neighborhood: nil,
            coordinate: stop.coordinate,
            nearbyPOINames: [],
            nearbyPOICategories: [],
            currentTourName: tour?.name,
            currentTourCategory: tour?.category.rawValue
        )
    }

    func speakTourOverview(_ tour: Tour) {
        let stopWord = tour.stops.count == 1 ? "stop" : "stops"
        speak("Welcome to \(tour.name). \(tour.description) You'll be visiting \(tour.stops.count) \(stopWord) over about \(tour.formattedDuration), covering \(tour.formattedDistance). Let's get started!")
    }

    func speakNavigation(to stop: TourStop, eta: String?) {
        var text = "Your next stop is \(stop.name)."
        if let eta {
            text += " It's about \(eta) away."
        }
        speak(text)
    }

    func speakArrival(at stop: TourStop, persona: GuidePersona? = nil, direction: String? = nil) {
        if let persona {
            let phrases: [String]
            if let direction, direction == "ahead" {
                phrases = [
                    "Right ahead — \(stop.name)!",
                    "And here we are, \(stop.name) — right in front of you.",
                    "You made it — \(stop.name) is right ahead."
                ]
            } else if let direction {
                phrases = [
                    "Here we are — \(stop.name), \(direction).",
                    "And this is \(stop.name), \(direction).",
                    "\(stop.name), \(direction) — we made it."
                ]
            } else {
                phrases = [
                    "Here we are — \(stop.name)!",
                    "And this is \(stop.name).",
                    "Alright, we've made it to \(stop.name)!",
                    "Welcome to \(stop.name)."
                ]
            }
            speak(phrases.randomElement()!)
        } else {
            if let direction, direction == "ahead" {
                speak("You've arrived at \(stop.name), right ahead. Let me tell you about this place.")
            } else if let direction {
                speak("You've arrived at \(stop.name), \(direction). Let me tell you about this place.")
            } else {
                speak("You've arrived at \(stop.name). Let me tell you about this place.")
            }
        }
    }

    func speakWalkingNarration(_ narration: String, persona: GuidePersona? = nil) {
        var text = narration
        if persona != nil {
            let transitions = ["Alright, ", "Now, ", "So, "]
            text = transitions.randomElement()! + text
        }
        speak(text)
    }

    func speakApproachTeaser(for stop: TourStop, persona: GuidePersona? = nil, direction: String? = nil) {
        // Don't interrupt an in-progress narration
        guard !isSpeaking && !isPaused else { return }

        let templates: [String]
        if persona != nil {
            if let direction, direction == "ahead" {
                templates = [
                    "Coming up ahead is \(stop.name).",
                    "We're almost at \(stop.name) — right ahead.",
                    "Just a bit further — \(stop.name) is straight ahead."
                ]
            } else if let direction {
                templates = [
                    "\(stop.name) is coming up \(direction).",
                    "Keep an eye out — \(stop.name) is \(direction).",
                    "Almost there — \(stop.name) is \(direction)."
                ]
            } else {
                templates = [
                    "Coming up ahead is \(stop.name).",
                    "We're almost at \(stop.name). You're going to like this one.",
                    "Just a bit further — \(stop.name) is right ahead."
                ]
            }
        } else {
            if let direction, direction == "ahead" {
                templates = [
                    "Coming up ahead is \(stop.name).",
                    "You're approaching \(stop.name), right ahead.",
                    "\(stop.name) is straight ahead."
                ]
            } else if let direction {
                templates = [
                    "\(stop.name) is coming up \(direction).",
                    "You're approaching \(stop.name), \(direction).",
                    "Look \(direction) — \(stop.name) is just ahead."
                ]
            } else {
                templates = [
                    "Coming up ahead is \(stop.name).",
                    "You're approaching \(stop.name).",
                    "Almost there — \(stop.name) is just ahead."
                ]
            }
        }

        var text = templates.randomElement()!
        if let tip = stop.tips {
            text += " Quick tip: \(tip)"
        }
        speak(text)
    }

    func speakDirectionSummary(to stop: TourStop, steps: [String], distance: String?) {
        var text = "Walking to \(stop.name)."
        if let distance {
            text += " The walk is about \(distance)."
        }
        if let first = steps.first {
            text += " To start, \(first.lowercased())."
        }
        speak(text)
    }

    /// Reset cached voice when user changes language preferences
    func clearVoiceCache() {
        cachedVoice = nil
    }
}

// MARK: - Delegate Handler (bridges non-isolated callbacks to MainActor)

private class SpeechDelegateHandler: NSObject, AVSpeechSynthesizerDelegate {
    let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onFinish()
    }
}

// MARK: - Audio Player Delegate Handler

private class AudioPlayerDelegateHandler: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        onFinish()
    }
}
