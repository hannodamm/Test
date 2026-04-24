import SwiftUI
import CoreLocation

struct StopChatSheet: View {
    let stop: TourStop
    let tour: Tour
    let locationManager: LocationManager

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var speechService: SpeechService
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isTyping: Bool = false
    @FocusState private var isInputFocused: Bool

    private let claudeAPI = ClaudeAPIService()
    private let tourGuideService = TourGuideService()

    private var quickQuestions: [String] {
        [
            "Tell me more about \(stop.name)",
            "What's the history of this place?",
            "Any tips for visiting here?",
            "What should I see nearby?"
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: stop.imageSystemName)
                        .foregroundStyle(.accent)
                    VStack(alignment: .leading) {
                        Text(stop.name)
                            .font(.subheadline.bold())
                        Text("Stop \(stop.orderIndex + 1) on \(tour.name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                            }
                            if isTyping {
                                TypingIndicator()
                            }
                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                }

                if messages.count <= 1 {
                    QuickQuestionsBar(questions: quickQuestions) { question in
                        inputText = question
                        sendMessage()
                    }
                }

                HStack(spacing: 12) {
                    TextField("Ask about \(stop.name)...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...3)
                        .focused($isInputFocused)
                        .submitLabel(.send)
                        .onSubmit { sendMessage() }

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .accent)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isTyping)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.bar)
            }
            .navigationTitle("Ask About This Stop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        speechService.stop()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            if tour.guidePersona != nil {
                messages.append(ChatMessage.assistantMessage(
                    "So, you're at \(stop.name). \(stop.description) What would you like to know?"
                ))
            } else {
                messages.append(ChatMessage.assistantMessage(
                    "You're at \(stop.name). \(stop.description) Ask me anything about this stop, its history, or what to do here!"
                ))
            }
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(ChatMessage.userMessage(text))
        inputText = ""
        isTyping = true

        Task {
            let response: String
            let stopLocation = CLLocation(latitude: stop.latitude, longitude: stop.longitude)

            if APIKeyManager.shared.hasAPIKey {
                let context = tourGuideService.buildLocationContext(
                    location: stopLocation,
                    placemark: nil,
                    nearbyPOIs: [],
                    currentTour: tour
                )
                let factsBlock = stop.effectiveFacts.map { "\($0.title): \($0.content)" }.joined(separator: " | ")
                let enrichedQuestion = "I'm in \(tour.locationName), currently at tour stop \"\(stop.name)\": \(stop.description). Facts about this stop: \(factsBlock) My question: \(text)"
                response = await claudeAPI.ask(
                    question: enrichedQuestion,
                    conversationHistory: messages,
                    locationContext: context,
                    guidePersona: tour.guidePersona
                )
            } else {
                response = tourGuideService.generateFallbackResponse(
                    to: text,
                    location: stopLocation,
                    placemark: nil,
                    nearbyPOIs: [],
                    currentTour: tour
                )
            }

            messages.append(ChatMessage.assistantMessage(response))
            isTyping = false
        }
    }
}
