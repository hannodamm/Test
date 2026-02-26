import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var tourViewModel: TourViewModel

    @FocusState private var isInputFocused: Bool
    @Namespace private var bottomAnchor

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Location context bar
                locationBar

                // Messages
                messagesScrollView

                // Suggested questions
                if viewModel.messages.count <= 2 {
                    suggestedQuestionsView
                }

                // Input area
                inputArea
            }
            .navigationTitle("AI Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            viewModel.clearChat()
                        } label: {
                            Label("Clear Chat", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            viewModel.updateContext(
                pois: [],
                tour: tourViewModel.currentTour
            )
        }
    }

    // MARK: - Location Bar

    private var locationBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "location.fill")
                .font(.caption)
                .foregroundStyle(.blue)
            Text(locationManager.locationDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            if tourViewModel.isOnTour {
                Label("On Tour", systemImage: "figure.walk")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.blue.opacity(0.15), in: Capsule())
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - Messages

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        ChatBubble(message: message)
                    }

                    if viewModel.isTyping {
                        TypingIndicator()
                    }

                    if viewModel.lastMessageWasError {
                        Button {
                            // Re-send the last user message
                            if let lastUserMsg = viewModel.messages.last(where: { $0.role == .user }) {
                                viewModel.inputText = lastUserMsg.content
                                sendMessage()
                            }
                        } label: {
                            Label("Retry", systemImage: "arrow.clockwise")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.1), in: Capsule())
                        }
                        .padding(.top, 4)
                    }

                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: viewModel.isTyping) { _, _ in
                withAnimation {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Suggested Questions

    private var suggestedQuestionsView: some View {
        QuickQuestionsBar(questions: viewModel.suggestedQuestions) { question in
            viewModel.inputText = question
            sendMessage()
        }
    }

    // MARK: - Input Area

    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("Ask about this area...", text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit { sendMessage() }

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .accent)
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isTyping)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func sendMessage() {
        Task {
            await viewModel.sendMessage(
                location: locationManager.currentLocation,
                placemark: locationManager.currentPlacemark
            )
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animationPhase: Int = 0

    var body: some View {
        HStack(alignment: .bottom) {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 7, height: 7)
                        .offset(y: animationPhase == index ? -4 : 0)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground), in: ChatBubbleShape(isUser: false))
            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                animationPhase = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                    animationPhase = 1
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                    animationPhase = 2
                }
            }
        }
    }
}
