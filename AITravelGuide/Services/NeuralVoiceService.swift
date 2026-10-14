import AVFoundation
import NaturalLanguage
import OSLog
import SherpaOnnx

/// On-device neural TTS via sherpa-onnx: Kokoro v1.0 for English, Italian,
/// French and Spanish. Other languages (German included) stay on AVSpeech.
///
/// Spike: model files are side-loaded into `Application Support/Voices/<dir>`.
/// The shipping feature will download them per language on demand.
///
/// Text is split into sentences; each sentence is synthesized on a background
/// queue and scheduled on an `AVAudioPlayerNode` as soon as it is ready, so the
/// first sentence plays while the next ones are still being generated.
@MainActor
final class NeuralVoiceService {
    static let shared = NeuralVoiceService()

    /// UserDefaults flag behind the Settings toggle (default on when installed).
    static let enabledKey = "neuralVoiceEnabled"

    /// Voice per app language. Kokoro speaker IDs come from the model's speaker table.
    private static let voices: [String: Voice] = [
        "en": .kokoro(languageID: "en", speakerID: 3),   // af_heart
        "it": .kokoro(languageID: "it", speakerID: 35),  // if_sara
        "fr": .kokoro(languageID: "fr", speakerID: 30),  // ff_siwis
        "es": .kokoro(languageID: "es", speakerID: 28)   // ef_dora
    ]

    /// When nothing is playing, a first sentence longer than this is split at
    /// its first comma so a short phrase can start playing sooner.
    private static let quickStartLength = 60

    private let log = Logger(subsystem: "com.hannodamm.aitravelguide", category: "NeuralVoice")
    private let synth = Synthesizer()
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var connectedFormat: AVAudioFormat?

    /// Bumped on `stop()` so audio synthesized for a cancelled request is dropped.
    private var generation = 0
    /// Sentences enqueued but not yet played back.
    private var pendingSentences = 0

    private init() {
        engine.attach(player)
    }

    /// True when the voice for this language is installed and the user hasn't
    /// turned neural speech off.
    func supports(languageID: String) -> Bool {
        let enabled = UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
        return enabled && Self.voices[languageID]?.isInstalled == true
    }

    /// Loads the model in the background so the first narration doesn't pay
    /// the load cost.
    func prewarm(languageID: String) {
        guard supports(languageID: languageID), let voice = Self.voices[languageID] else { return }
        let log = log
        synth.queue.async { [synth] in
            synth.load(voice, log: log)
        }
    }

    /// Speaks `text`, queued after anything already playing. `onFinish` runs
    /// once the last sentence has played (not called if `stop()` intervenes).
    func enqueue(_ text: String, languageID: String, speed: Float, onFinish: @escaping @MainActor () -> Void) {
        var sentences = Self.sentences(in: text)
        guard !sentences.isEmpty, let voice = Self.voices[languageID] else {
            onFinish()
            return
        }
        if pendingSentences == 0 {
            sentences = Self.splitForQuickStart(sentences)
        }
        pendingSentences += sentences.count

        let gen = generation
        let log = log
        let requestedAt = Date()
        let count = sentences.count

        synth.queue.async { [synth] in
            synth.load(voice, log: log)
            for (index, sentence) in sentences.enumerated() {
                let audio = synth.generate(sentence, speakerID: voice.speakerID, speed: speed, log: log)
                let isLast = index == count - 1
                DispatchQueue.main.async {
                    MainActor.assumeIsolated {
                        guard gen == self.generation else { return }
                        guard let (samples, sampleRate) = audio else {
                            // Skip a sentence that failed, but never leave the caller hanging.
                            self.pendingSentences -= 1
                            if isLast { onFinish() }
                            return
                        }
                        self.schedule(samples: samples, sampleRate: sampleRate, generation: gen,
                                      onPlayed: isLast ? onFinish : nil)
                        if index == 0 {
                            let ms = Int(Date().timeIntervalSince(requestedAt) * 1000)
                            log.info("first audio scheduled after \(ms) ms")
                        }
                    }
                }
            }
        }
    }

    func pause() { player.pause() }

    func resume() { player.play() }

    func stop() {
        generation += 1
        pendingSentences = 0
        player.stop()
    }

    // MARK: - Playback

    private func schedule(samples: [Float], sampleRate: Int, generation gen: Int,
                          onPlayed: (@MainActor () -> Void)?) {
        let finished = { [weak self] in
            guard let self, gen == self.generation else { return }
            self.pendingSentences -= 1
            onPlayed?()
        }

        guard let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else {
            finished()
            return
        }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { src in
            buffer.floatChannelData![0].update(from: src.baseAddress!, count: samples.count)
        }

        do {
            try startEngine(format: format)
        } catch {
            log.error("audio engine failed to start: \(error.localizedDescription)")
            finished()
            return
        }

        player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { _ in
            // A stop() fires completion handlers for flushed buffers; `finished` ignores those.
            DispatchQueue.main.async {
                MainActor.assumeIsolated { finished() }
            }
        }
        if !player.isPlaying { player.play() }
    }

    private func startEngine(format: AVAudioFormat) throws {
        if connectedFormat != format {
            engine.stop()
            engine.disconnectNodeOutput(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            connectedFormat = format
        }
        if !engine.isRunning {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
        }
    }

    private static func sentences(in text: String) -> [String] {
        // Narration templates join parts with " ... "; treat those as breaks too.
        let normalized = speakable(text).replacingOccurrences(of: " ... ", with: ". ")
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = normalized
        return tokenizer.tokens(for: normalized.startIndex..<normalized.endIndex)
            .map { normalized[$0].trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Splits a long first sentence at its first comma (past a few words), so
    /// the opening phrase is synthesized and heard sooner.
    private static func splitForQuickStart(_ sentences: [String]) -> [String] {
        guard let first = sentences.first, first.count > quickStartLength,
              let comma = first.dropFirst(20).firstIndex(of: ","),
              first.distance(from: comma, to: first.endIndex) > 20 else { return sentences }
        let head = String(first[...comma])
        let tail = first[first.index(after: comma)...].trimmingCharacters(in: .whitespaces)
        return [head, tail] + sentences.dropFirst()
    }

    /// Strips markdown from model output. AVSpeech skips these symbols, but
    /// Kokoro (via espeak-ng) reads them aloud ("asterisk", "hash").
    static func speakable(_ text: String) -> String {
        var s = text
        let rules: [(String, String)] = [
            (#"\[([^\]]+)\]\([^)]*\)"#, "$1"),       // [label](url) -> label
            (#"(?m)^\s{0,3}#{1,6}\s*"#, ""),         // headings
            (#"(?m)^\s*(?:[-*+•]|\d+[.)])\s+"#, ""), // list bullets / numbers
            (#"(?m)^\s*>\s?"#, ""),                  // block quotes
            (#"[*_`~#|]+"#, ""),                     // emphasis, code, tables
            (#"[ \t]{2,}"#, " ")
        ]
        for (pattern, template) in rules {
            s = s.replacingOccurrences(of: pattern, with: template, options: .regularExpression)
        }
        // Line breaks (e.g. after a list item) should pause, not run on.
        return s.replacingOccurrences(of: #"([^.!?:;,\s])\s*\n+\s*"#, with: "$1. ", options: .regularExpression)
    }
}

// MARK: - Synthesizer (confined to its own serial queue)

/// Owns the sherpa-onnx engine. Every method runs on `queue`; the wrapper is
/// not thread-safe, so it never leaves this queue.
private final class Synthesizer: @unchecked Sendable {
    let queue = DispatchQueue(label: "com.hannodamm.aitravelguide.neuralvoice", qos: .userInitiated)
    private var tts: SherpaOnnxOfflineTtsWrapper?
    private var loaded: Voice?

    func load(_ voice: Voice, log: Logger) {
        dispatchPrecondition(condition: .onQueue(queue))
        guard loaded != voice else { return }
        tts = nil  // free the previous model before loading the next

        let start = Date()
        let dir = voice.directory
        let path = { (name: String) in dir.appending(path: name).path }
        let threads = min(4, max(1, ProcessInfo.processInfo.activeProcessorCount - 2))

        // English uses Kokoro's lexicon; other languages go through espeak-ng.
        let kokoro = sherpaOnnxOfflineTtsKokoroModelConfig(
            model: path("model.onnx"),
            voices: path("voices.bin"),
            tokens: path("tokens.txt"),
            dataDir: path("espeak-ng-data"),
            lexicon: voice.languageID == "en" ? path("lexicon-us-en.txt") : "",
            lang: voice.languageID == "en" ? "" : voice.languageID
        )
        var config = sherpaOnnxOfflineTtsConfig(
            model: sherpaOnnxOfflineTtsModelConfig(kokoro: kokoro, numThreads: threads))
        let wrapper = SherpaOnnxOfflineTtsWrapper(config: &config)
        guard wrapper.tts != nil else {
            log.error("failed to load voice from \(dir.path)")
            loaded = nil
            return
        }
        tts = wrapper
        loaded = voice

        let ms = Int(Date().timeIntervalSince(start) * 1000)
        log.info("loaded \(dir.lastPathComponent) (\(String(describing: voice))) in \(ms) ms, \(threads) threads, footprint \(Self.footprintMB()) MB")
    }

    func generate(_ text: String, speakerID: Int, speed: Float, log: Logger) -> ([Float], Int)? {
        dispatchPrecondition(condition: .onQueue(queue))
        guard let tts else { return nil }
        let start = Date()
        let audio = tts.generate(text: text, sid: speakerID, speed: speed)
        let samples = audio.samples
        guard !samples.isEmpty else { return nil }

        let elapsed = Date().timeIntervalSince(start)
        let duration = Double(samples.count) / Double(audio.sampleRate)
        log.info("sentence: \(String(format: "%.2f", elapsed)) s for \(String(format: "%.2f", duration)) s audio (RTF \(String(format: "%.2f", elapsed / duration)))")
        return (samples, Int(audio.sampleRate))
    }

    private static func footprintMB() -> Int {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Int(info.phys_footprint / 1_048_576) : -1
    }
}

// MARK: - Voice catalog

private enum Voice: Equatable, Sendable {
    /// One multilingual Kokoro model; the language and speaker pick the voice.
    case kokoro(languageID: String, speakerID: Int)

    var languageID: String {
        switch self { case .kokoro(let languageID, _): return languageID }
    }

    var speakerID: Int {
        switch self { case .kokoro(_, let speakerID): return speakerID }
    }

    var directory: URL {
        URL.applicationSupportDirectory
            .appending(path: "Voices", directoryHint: .isDirectory)
            .appending(path: "kokoro-multi-lang-v1_0", directoryHint: .isDirectory)
    }

    var isInstalled: Bool {
        FileManager.default.fileExists(atPath: directory.appending(path: "model.onnx").path)
    }
}
