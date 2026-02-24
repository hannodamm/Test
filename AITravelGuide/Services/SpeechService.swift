import AVFoundation
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
                self?.isSpeaking = false
                self?.isPaused = false
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
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        audioPlayer?.stop()
        audioPlayer = nil
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

            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("tts_\(UUID().uuidString).mp3")
            try data.write(to: tempURL)

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

    /// AI-powered narration with fallback to template text
    func speakStopNarration(_ stop: TourStop, tour: Tour?) async {
        let persona = tour?.guidePersona

        // Use cached narration if available (preloaded during preview)
        if let cached = cachedNarrations[stop.name] {
            speak(cached)
            return
        }

        // If a preload is in progress, await it instead of speaking filler
        if let preloadTask = preloadTasks[stop.name] {
            if let narration = await preloadTask.value {
                cachedNarrations[stop.name] = narration
                speak(narration)
                return
            }
        }

        if APIKeyManager.shared.hasAPIKey {
            // Speak a short intro while waiting for AI narration
            speak("Let me tell you about \(stop.name).")

            let context = buildMinimalContext(stop: stop, tour: tour)
            let claudeAPI = ClaudeAPIService()
            if let narration = await claudeAPI.narrateStop(
                stop: stop,
                locationContext: context,
                guidePersona: persona
            ) {
                speak(narration)
                return
            }
        }

        // Fallback to template narration
        speakStopDescription(stop, guidePersona: persona)
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

    func speakArrival(at stop: TourStop, persona: GuidePersona? = nil) {
        if let persona {
            let phrases = [
                "Here we are — \(stop.name)!",
                "And this is \(stop.name).",
                "Alright, we've made it to \(stop.name)!",
                "Welcome to \(stop.name)."
            ]
            speak(phrases.randomElement()!)
        } else {
            speak("You've arrived at \(stop.name). Let me tell you about this place.")
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
