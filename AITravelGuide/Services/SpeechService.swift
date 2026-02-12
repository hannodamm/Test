import AVFoundation
import SwiftUI

@MainActor
final class SpeechService: NSObject, ObservableObject {
    @Published var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()
    private var delegateHandler: SpeechDelegateHandler?
    private var cachedVoice: AVSpeechSynthesisVoice?

    /// Reads voice-enabled preference from UserDefaults (toggled in Settings)
    var voiceEnabled: Bool {
        UserDefaults.standard.object(forKey: "voiceEnabled") as? Bool ?? true
    }

    private var speechRateValue: Float {
        let index = UserDefaults.standard.integer(forKey: "speechRateIndex")
        switch index {
        case 0: return 0.38  // slow — relaxed pace
        case 2: return 0.48  // fast — brisk but still clear
        default: return 0.43 // normal — conversational
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
            }
        }
        synthesizer.delegate = delegateHandler
    }

    // MARK: - Public API

    func speak(_ text: String) {
        stop()
        guard voiceEnabled, !text.isEmpty else { return }

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speechRateValue
        utterance.pitchMultiplier = 1.05
        utterance.preUtteranceDelay = 0.2
        utterance.postUtteranceDelay = 0.1
        utterance.voice = preferredVoice
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    func toggle(_ text: String) {
        if isSpeaking {
            stop()
        } else {
            speak(text)
        }
    }

    // MARK: - Natural Narrations

    func speakStopDescription(_ stop: TourStop) {
        var parts: [String] = []
        parts.append("Welcome to \(stop.name).")
        parts.append(stop.description)

        if let note = stop.historicalNote {
            parts.append("Here's a bit of history. \(note)")
        }
        if let tip = stop.tips {
            parts.append("Quick tip: \(tip)")
        }

        speak(parts.joined(separator: " ... "))
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

    func speakArrival(at stop: TourStop) {
        speak("You've arrived at \(stop.name). Let me tell you about this place.")
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
