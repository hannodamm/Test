import AVFoundation
import SwiftUI

@MainActor
final class SpeechService: NSObject, ObservableObject {
    @Published var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()
    private var delegateHandler: SpeechDelegateHandler?

    /// Reads voice-enabled preference from UserDefaults (toggled in Settings)
    var voiceEnabled: Bool {
        UserDefaults.standard.object(forKey: "voiceEnabled") as? Bool ?? true
    }

    private var speechRateValue: Float {
        let index = UserDefaults.standard.integer(forKey: "speechRateIndex")
        switch index {
        case 0: return 0.42  // slow
        case 2: return 0.57  // fast
        default: return 0.50 // normal
        }
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

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenContent)
        try? AVAudioSession.sharedInstance().setActive(true)

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speechRateValue
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.1
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
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

    // MARK: - Convenience Narrations

    func speakStopDescription(_ stop: TourStop) {
        var text = "\(stop.name). \(stop.description)"
        if let note = stop.historicalNote {
            text += " \(note)"
        }
        if let tip = stop.tips {
            text += " Tip: \(tip)"
        }
        speak(text)
    }

    func speakTourOverview(_ tour: Tour) {
        speak("\(tour.name). \(tour.description). This tour has \(tour.stops.count) stops and takes about \(tour.formattedDuration).")
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
