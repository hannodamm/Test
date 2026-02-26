import SwiftUI
import CoreLocation

struct GuideChatSheet: View {
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

    private var tourLocationDescription: String {
        if tour.locationName != "the area" {
            return tour.locationName
        }
        return locationManager.locationDescription
    }

    private var quickQuestions: [String] {
        [
            "Where should I eat nearby?",
            "Is this area safe at night?",
            "How do I get to the city center?",
            "What's the best coffee shop around here?",
            "Any hidden gems nearby?",
            "What's the local specialty food?"
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: tour.guidePersona != nil ? "person.circle.fill" : "globe.americas.fill")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text(tour.guidePersona.map { "\($0.name)" } ?? "AI Travel Guide")
                            .font(.subheadline.bold())
                        Text(tour.guidePersona?.tagline ?? tourLocationDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Label("On Tour", systemImage: "figure.walk")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.blue.opacity(0.15), in: Capsule())
                        .foregroundStyle(.blue)
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
                    TextField("Ask anything about the area...", text: $inputText, axis: .vertical)
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
                            .foregroundStyle(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .blue)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isTyping)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.bar)
            }
            .navigationTitle("Travel Guide")
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
            if let persona = tour.guidePersona {
                messages.append(ChatMessage.assistantMessage(persona.greeting))
            } else {
                let city = tour.locationName != "the area" ? tour.locationName : (locationManager.currentCity ?? "the area")
                messages.append(ChatMessage.assistantMessage(
                    "I'm your travel guide for \(city). Ask me anything — restaurant recommendations, transport tips, safety advice, local customs, or whatever's on your mind!"
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
            let tourLocation = CLLocation(latitude: tour.centerLatitude, longitude: tour.centerLongitude)

            if APIKeyManager.shared.hasAPIKey {
                let context = tourGuideService.buildLocationContext(
                    location: tourLocation,
                    placemark: nil,
                    nearbyPOIs: [],
                    currentTour: tour
                )
                let enrichedQuestion = "I'm on a tour in \(tour.locationName). \(text)"
                response = await claudeAPI.ask(
                    question: enrichedQuestion,
                    conversationHistory: messages,
                    locationContext: context,
                    guidePersona: tour.guidePersona
                )
            } else {
                response = tourGuideService.generateFallbackResponse(
                    to: text,
                    location: tourLocation,
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
