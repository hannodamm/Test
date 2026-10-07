import Foundation
import CoreLocation

// Foundation Models ships in the iOS 26 SDK (Xcode 26+). Guarding the import
// with `canImport` lets this file still compile on older toolchains — it just
// reports `isAvailable == false` there.
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Generates guide narration and chat replies using Apple's on-device
/// Foundation Models LLM. Mirrors the shape of `ClaudeAPIService` so call sites
/// can swap between them, but needs no API key and runs fully offline.
///
/// All methods return `nil` when the on-device model is unavailable or errors,
/// so callers can fall back to `canned` template text.
@MainActor
final class OnDeviceGuideService: ObservableObject {

    /// True only on iOS 26+ Apple-Intelligence-capable hardware with the model
    /// downloaded and enabled. Safe to call on any OS/toolchain — returns false
    /// where Foundation Models isn't present.
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            if case .available = SystemLanguageModel.default.availability {
                return true
            }
        }
        #endif
        return false
    }

    // MARK: - Chat

    /// Answer a user question with live location context. Returns nil if the
    /// on-device model is unavailable or generation fails.
    func ask(
        question: String,
        conversationHistory: [ChatMessage],
        locationContext: LocationContext,
        guidePersona: GuidePersona? = nil
    ) async -> String? {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            // Tour persona takes precedence; otherwise honor the user's global
            // persona choice (matches ClaudeAPIService.ask).
            let effectivePersona = guidePersona ?? GuidePreferences.selectedPersona
            let instructions = Self.chatInstructions(context: locationContext, persona: effectivePersona)
            let prompt = Self.chatPrompt(history: conversationHistory, question: question)
            return await Self.generate(instructions: instructions, prompt: prompt)
        }
        #endif
        return nil
    }

    // MARK: - Stop Narration

    /// Generate spoken narration for a tour stop. Returns nil if unavailable.
    func narrateStop(
        stop: TourStop,
        locationContext: LocationContext,
        guidePersona: GuidePersona? = nil
    ) async -> String? {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            let (instructions, prompt) = Self.stopNarrationPrompt(
                stop: stop,
                locationContext: locationContext,
                guidePersona: guidePersona
            )
            return await Self.generate(instructions: instructions, prompt: prompt)
        }
        #endif
        return nil
    }

    // MARK: - Generation

    #if canImport(FoundationModels)
    @available(iOS 26, *)
    private static func generate(instructions: String, prompt: String) async -> String? {
        let session = LanguageModelSession {
            instructions
        }
        do {
            let response = try await session.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        } catch {
            return nil
        }
    }
    #endif

    // MARK: - Prompt Construction
    //
    // Prompts are intentionally leaner than ClaudeAPIService's: the on-device
    // model is smaller, so tighter instructions produce more reliable output.

    private static func chatInstructions(context: LocationContext, persona: GuidePersona?) -> String {
        var parts: [String] = []
        if let persona {
            parts.append("You are \(persona.name), \(persona.tagline). Your style: \(persona.voiceStyle). Stay in character.")
        } else {
            parts.append("You are an expert local travel guide helping a visitor explore in real time.")
        }
        parts.append("Be friendly, concise, and specific. If you are unsure about a place, say so honestly instead of inventing details.")

        if let city = context.city { parts.append("City: \(city).") }
        if let neighborhood = context.neighborhood { parts.append("Neighborhood: \(neighborhood).") }
        if !context.nearbyPOINames.isEmpty {
            parts.append("Nearby places: \(context.nearbyPOINames.prefix(8).joined(separator: ", ")).")
        }
        if let tourName = context.currentTourName {
            parts.append("The visitor is on the tour \"\(tourName)\".")
        }

        let modifier = GuidePreferences.systemPromptModifier
        if !modifier.isEmpty { parts.append(modifier) }

        return parts.joined(separator: " ")
    }

    private static func chatPrompt(history: [ChatMessage], question: String) -> String {
        // Fold the last few turns into the prompt for continuity, since each
        // call uses a fresh stateless session.
        var recent = Array(history.suffix(6).filter { $0.role != .system })
        // `history` already ends with the raw user message, while `question`
        // may be an enriched version of it (tour/stop sheets). Drop the raw
        // turn so the question isn't sent twice.
        if recent.last?.role == .user {
            recent.removeLast()
        }
        guard !recent.isEmpty else { return question }

        var lines: [String] = ["Conversation so far:"]
        for msg in recent {
            let speaker = msg.role == .user ? "Visitor" : "Guide"
            lines.append("\(speaker): \(msg.content)")
        }
        lines.append("Visitor: \(question)")
        lines.append("Guide:")
        return lines.joined(separator: "\n")
    }

    private static func stopNarrationPrompt(
        stop: TourStop,
        locationContext: LocationContext,
        guidePersona: GuidePersona?
    ) -> (instructions: String, prompt: String) {
        var instructionParts: [String] = []
        if let persona = guidePersona {
            instructionParts.append("You are \(persona.name), a travel guide with this style: \(persona.voiceStyle). Speak in character.")
        } else {
            instructionParts.append("You are an expert travel guide narrating a walking tour.")
        }
        instructionParts.append("Speak aloud to someone standing right here: natural, conversational, vivid.")
        instructionParts.append("Keep it under 150 words. No markdown, bullets, or headings — just flowing spoken text.")
        let modifier = GuidePreferences.systemPromptModifier
        if !modifier.isEmpty { instructionParts.append(modifier) }

        var promptParts: [String] = [
            "Narrate this tour stop for a visitor:",
            "Name: \(stop.name)",
            "Description: \(stop.description)",
            "Location: \(locationContext.city ?? "Unknown"), \(locationContext.country ?? "Unknown")"
        ]
        let facts = stop.effectiveFacts
        if !facts.isEmpty {
            let factLines = facts.map { fact -> String in
                let year = fact.year.map { "(\($0)) " } ?? ""
                return "- \(year)\(fact.title): \(fact.content)"
            }
            promptParts.append("Facts to weave in naturally:\n" + factLines.joined(separator: "\n"))
        }
        if let tip = stop.tips { promptParts.append("Tip: \(tip)") }
        if let narration = stop.walkingNarration { promptParts.append("Walking context: \(narration)") }

        return (instructionParts.joined(separator: " "), promptParts.joined(separator: "\n"))
    }
}
