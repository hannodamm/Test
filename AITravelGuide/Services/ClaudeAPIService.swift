import Foundation
import CoreLocation

/// Calls the Anthropic Messages API to generate real AI responses
/// grounded in the user's live location and MapKit context.
@MainActor
final class ClaudeAPIService: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var lastError: String?

    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-sonnet-4-5-20250929"
    private let maxTokens = 1024

    // MARK: - Public API

    /// Send a user question with full location context and get an AI response.
    func ask(
        question: String,
        conversationHistory: [ChatMessage],
        locationContext: LocationContext
    ) async -> String {
        guard let apiKey = APIKeyManager.shared.claudeAPIKey, !apiKey.isEmpty else {
            return "Please add your Claude API key in Settings to enable AI-powered responses."
        }

        isLoading = true
        lastError = nil
        defer { isLoading = false }

        let systemPrompt = buildSystemPrompt(context: locationContext)
        let messages = buildMessages(history: conversationHistory, newQuestion: question)

        do {
            return try await callAPI(apiKey: apiKey, system: systemPrompt, messages: messages)
        } catch {
            lastError = error.localizedDescription
            return "I'm having trouble connecting: \(error.localizedDescription)"
        }
    }

    /// Generate a rich narration for a specific tour stop.
    func narrateStop(
        stop: TourStop,
        locationContext: LocationContext
    ) async -> String? {
        guard let apiKey = APIKeyManager.shared.claudeAPIKey, !apiKey.isEmpty else {
            return nil
        }

        let system = """
            You are an expert travel guide narrating a walking tour. Give a vivid, \
            engaging 2-3 paragraph description of this stop. Include historical context, \
            cultural significance, and practical tips. Be conversational and enthusiastic.
            """

        let userContent = """
            Narrate this tour stop for a visitor:
            Name: \(stop.name)
            Description: \(stop.description)
            Location: \(locationContext.city ?? "Unknown"), \(locationContext.country ?? "Unknown")
            Neighborhood: \(locationContext.neighborhood ?? "N/A")
            \(stop.historicalNote.map { "Historical note: \($0)" } ?? "")
            \(stop.tips.map { "Tip: \($0)" } ?? "")
            """

        let messages = [APIMessage(role: "user", content: userContent)]

        do {
            return try await callAPI(apiKey: apiKey, system: system, messages: messages)
        } catch {
            return nil
        }
    }

    /// Generate highlight descriptions for a point of interest.
    func describeHighlight(
        poi: PointOfInterest,
        locationContext: LocationContext
    ) async -> String? {
        guard let apiKey = APIKeyManager.shared.claudeAPIKey, !apiKey.isEmpty else {
            return nil
        }

        let system = """
            You are a knowledgeable local travel guide. Provide a concise, helpful \
            description (2-3 sentences) of this place for a tourist.
            """

        let userContent = """
            Describe this place for a visitor:
            Name: \(poi.name)
            Category: \(poi.category.rawValue)
            City: \(locationContext.city ?? "Unknown")
            \(poi.address.map { "Address: \($0)" } ?? "")
            """

        let messages = [APIMessage(role: "user", content: userContent)]

        do {
            return try await callAPI(apiKey: apiKey, system: system, messages: messages)
        } catch {
            return nil
        }
    }

    // MARK: - API Call

    private func callAPI(
        apiKey: String,
        system: String,
        messages: [APIMessage]
    ) async throws -> String {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body = APIRequest(
            model: model,
            max_tokens: maxTokens,
            system: system,
            messages: messages
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorBody = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw APIError.apiError(httpResponse.statusCode, errorBody.error.message)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)

        guard let text = apiResponse.content.first(where: { $0.type == "text" })?.text else {
            throw APIError.noContent
        }

        return text
    }

    // MARK: - Prompt Construction

    private func buildSystemPrompt(context: LocationContext) -> String {
        var parts: [String] = [
            "You are an expert AI travel guide helping a user explore their surroundings in real time.",
            "Be friendly, concise, and knowledgeable. Provide specific, actionable advice.",
            "When you don't know something specific about a place, say so honestly rather than guessing.",
            ""
        ]

        parts.append("CURRENT LOCATION CONTEXT:")
        if let city = context.city { parts.append("- City: \(city)") }
        if let country = context.country { parts.append("- Country: \(country)") }
        if let neighborhood = context.neighborhood { parts.append("- Neighborhood: \(neighborhood)") }
        if let coord = context.coordinate {
            parts.append("- Coordinates: \(String(format: "%.4f", coord.latitude)), \(String(format: "%.4f", coord.longitude))")
        }

        if !context.nearbyPOINames.isEmpty {
            parts.append("")
            parts.append("NEARBY PLACES (from Apple Maps):")
            for name in context.nearbyPOINames.prefix(10) {
                parts.append("- \(name)")
            }
        }

        if !context.nearbyPOICategories.isEmpty {
            parts.append("")
            parts.append("NEARBY CATEGORIES: \(context.nearbyPOICategories.joined(separator: ", "))")
        }

        if let tourName = context.currentTourName {
            parts.append("")
            parts.append("USER IS CURRENTLY ON TOUR: \"\(tourName)\"")
            if let cat = context.currentTourCategory {
                parts.append("Tour type: \(cat)")
            }
        }

        return parts.joined(separator: "\n")
    }

    private func buildMessages(history: [ChatMessage], newQuestion: String) -> [APIMessage] {
        // Include recent conversation history for context (last 10 messages)
        // The history already contains the latest user message, so we only
        // append newQuestion if it isn't the last entry.
        var apiMessages: [APIMessage] = []

        let recentHistory = history.suffix(10)
        for msg in recentHistory {
            switch msg.role {
            case .user:
                apiMessages.append(APIMessage(role: "user", content: msg.content))
            case .assistant:
                apiMessages.append(APIMessage(role: "assistant", content: msg.content))
            case .system:
                break
            }
        }

        // Only add the question if it wasn't already the last message in history
        let lastUserContent = apiMessages.last(where: { $0.role == "user" })?.content
        if lastUserContent != newQuestion {
            apiMessages.append(APIMessage(role: "user", content: newQuestion))
        }

        // Ensure messages start with a user message (API requirement)
        if let first = apiMessages.first, first.role == "assistant" {
            apiMessages.removeFirst()
        }

        return apiMessages
    }
}

// MARK: - Location Context (shared struct)

struct LocationContext {
    let city: String?
    let country: String?
    let neighborhood: String?
    let coordinate: CLLocationCoordinate2D?
    let nearbyPOINames: [String]
    let nearbyPOICategories: [String]
    let currentTourName: String?
    let currentTourCategory: String?
}

// MARK: - API Types

private struct APIRequest: Encodable {
    let model: String
    let max_tokens: Int
    let system: String
    let messages: [APIMessage]
}

struct APIMessage: Codable {
    let role: String
    let content: String
}

private struct APIResponse: Decodable {
    let content: [ContentBlock]

    struct ContentBlock: Decodable {
        let type: String
        let text: String?
    }
}

private struct APIErrorResponse: Decodable {
    let error: ErrorDetail

    struct ErrorDetail: Decodable {
        let message: String
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case apiError(Int, String)
    case noContent

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server."
        case .httpError(let code):
            return "Server returned status \(code)."
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        case .noContent:
            return "No content in response."
        }
    }
}
