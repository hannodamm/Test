import Foundation

/// Parses Anthropic's Messages API server-sent-events stream into
/// sentence-sized text chunks, suitable for queued TTS playback.
///
/// Uses a 25-character minimum sentence length to defuse abbreviation
/// false-positives (e.g. "Mr.", "St.", "14 B.C.") without a full abbreviation list.
enum ClaudeStreamParser {
    static func sentences<S: AsyncSequence & Sendable>(
        from lines: S
    ) -> AsyncThrowingStream<String, Error> where S.Element == String {
        AsyncThrowingStream { continuation in
            let task = Task {
                var buffer = ""
                do {
                    for try await line in lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = line.dropFirst("data: ".count)
                        if payload == "[DONE]" { break }

                        guard let data = payload.data(using: .utf8),
                              let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let type = event["type"] as? String else { continue }

                        switch type {
                        case "content_block_delta":
                            if let delta = event["delta"] as? [String: Any],
                               delta["type"] as? String == "text_delta",
                               let text = delta["text"] as? String {
                                buffer += text
                                flushSentences(from: &buffer) { continuation.yield($0) }
                            }
                        case "message_stop":
                            flushRemainder(&buffer) { continuation.yield($0) }
                        case "error":
                            let message = (event["error"] as? [String: Any])?["message"] as? String
                                ?? "Stream error"
                            throw APIError.apiError(0, message)
                        default:
                            break
                        }
                    }
                    flushRemainder(&buffer) { continuation.yield($0) }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static let minChunkLength = 25
    private static let terminators: Set<Character> = [".", "!", "?", "…"]

    private static func flushSentences(
        from buffer: inout String,
        yield: (String) -> Void
    ) {
        while let boundary = findSentenceBoundary(in: buffer),
              buffer.distance(from: buffer.startIndex, to: boundary) + 1 >= minChunkLength {
            let end = buffer.index(after: boundary)
            let chunk = buffer[buffer.startIndex..<end]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !chunk.isEmpty { yield(chunk) }
            buffer.removeSubrange(buffer.startIndex..<end)
            // Drop any leading whitespace left over before the next sentence.
            while let first = buffer.first, first.isWhitespace || first.isNewline {
                buffer.removeFirst()
            }
        }
    }

    private static func flushRemainder(
        _ buffer: inout String,
        yield: (String) -> Void
    ) {
        let remainder = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !remainder.isEmpty { yield(remainder) }
        buffer.removeAll()
    }

    /// Returns the index of the last terminator in `buffer` whose following
    /// character is whitespace, newline, or end-of-buffer. Returning the *last*
    /// valid boundary lets us flush multiple sentences at once when they arrive
    /// in the same delta.
    private static func findSentenceBoundary(in buffer: String) -> String.Index? {
        var lastValid: String.Index?
        var i = buffer.startIndex
        while i < buffer.endIndex {
            if terminators.contains(buffer[i]) {
                let next = buffer.index(after: i)
                if next == buffer.endIndex
                    || buffer[next].isWhitespace
                    || buffer[next].isNewline {
                    lastValid = i
                }
            }
            i = buffer.index(after: i)
        }
        return lastValid
    }
}
