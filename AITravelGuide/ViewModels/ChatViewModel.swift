import Foundation
import CoreLocation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isTyping: Bool = false

    private let tourGuideService = TourGuideService()
    private var nearbyPOIs: [PointOfInterest] = []
    private var currentTour: Tour?

    init() {
        messages.append(
            ChatMessage.assistantMessage(
                "Hello! I'm your AI travel guide. I can help you explore the area, answer questions about local attractions, history, food, and more. What would you like to know?"
            )
        )
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

        let response = await tourGuideService.generateResponse(
            to: text,
            location: location,
            placemark: placemark,
            nearbyPOIs: nearbyPOIs,
            currentTour: currentTour,
            conversationHistory: messages
        )

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
