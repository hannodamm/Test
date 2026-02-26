import Foundation
import CoreLocation
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isTyping: Bool = false
    @Published var isUsingAI: Bool = false
    @Published var lastMessageWasError: Bool = false

    private let claudeAPI = ClaudeAPIService()
    private let tourGuideService = TourGuideService()
    private var nearbyPOIs: [PointOfInterest] = []
    private var currentTour: Tour?

    init() {
        let hasKey = APIKeyManager.shared.hasAPIKey
        isUsingAI = hasKey
        let greeting = hasKey
            ? "Hello! I'm your AI travel guide powered by Claude. Here's what I can help with:\n\n- Local attractions & hidden gems\n- Restaurant & cafe recommendations\n- History & culture of the area\n- Transport & navigation tips\n- Safety advice & local customs\n\nAsk me anything about where you are!"
            : "Hello! I'm your travel guide. Add a Claude API key in Settings to unlock AI-powered responses. I can still help with basic questions about the area!"
        messages.append(ChatMessage.assistantMessage(greeting))
    }

    func updateContext(pois: [PointOfInterest], tour: Tour?) {
        self.nearbyPOIs = pois
        self.currentTour = tour
    }

    func sendMessage(
        location: CLLocation?,
        placemark: CLPlacemark?
    ) async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userMessage = ChatMessage.userMessage(text)
        messages.append(userMessage)
        inputText = ""
        isTyping = true

        let response: String

        if APIKeyManager.shared.hasAPIKey {
            // Use real Claude API with full location context
            isUsingAI = true
            let context = tourGuideService.buildLocationContext(
                location: location,
                placemark: placemark,
                nearbyPOIs: nearbyPOIs,
                currentTour: currentTour
            )
            response = await claudeAPI.ask(
                question: text,
                conversationHistory: messages,
                locationContext: context
            )
        } else {
            // Fall back to offline template responses
            isUsingAI = false
            response = tourGuideService.generateFallbackResponse(
                to: text,
                location: location,
                placemark: placemark,
                nearbyPOIs: nearbyPOIs,
                currentTour: currentTour
            )
        }

        lastMessageWasError = response.hasPrefix("I'm having trouble connecting")
            || response.hasPrefix("Please add your Claude API key")
        let assistantMessage = ChatMessage.assistantMessage(response)
        messages.append(assistantMessage)
        isTyping = false
    }

    func clearChat() {
        messages = [
            ChatMessage.assistantMessage(
                "Chat cleared. I'm still here to help you explore! What would you like to know?"
            )
        ]
    }

    var suggestedQuestions: [String] {
        var suggestions = [
            "What's worth seeing nearby?",
            "Where should I eat around here?",
            "Tell me about the history of this area"
        ]

        if currentTour != nil {
            suggestions.insert("Tell me more about the current tour stop", at: 0)
        }

        return suggestions
    }
}
