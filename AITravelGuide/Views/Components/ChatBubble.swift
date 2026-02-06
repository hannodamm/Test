import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            if message.role == .assistant {
                guideAvatar
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.subheadline)
                    .foregroundStyle(message.role == .user ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(bubbleBackground, in: ChatBubbleShape(isUser: message.role == .user))

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }

    private var guideAvatar: some View {
        Image(systemName: "globe.americas.fill")
            .font(.caption)
            .foregroundStyle(.white)
            .padding(6)
            .background(.accent, in: Circle())
    }

    private var bubbleBackground: Color {
        switch message.role {
        case .user: return .accentColor
        case .assistant: return Color(.secondarySystemBackground)
        case .system: return Color(.tertiarySystemBackground)
        }
    }
}

struct ChatBubbleShape: Shape {
    let isUser: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 16
        let tailSize: CGFloat = 6

        var path = Path()

        if isUser {
            path.addRoundedRect(
                in: CGRect(x: rect.minX, y: rect.minY, width: rect.width - tailSize, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius)
            )
            // Tail on right
            path.move(to: CGPoint(x: rect.maxX - tailSize, y: rect.maxY - 16))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 8))
            path.addLine(to: CGPoint(x: rect.maxX - tailSize, y: rect.maxY - 4))
        } else {
            path.addRoundedRect(
                in: CGRect(x: rect.minX + tailSize, y: rect.minY, width: rect.width - tailSize, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius)
            )
            // Tail on left
            path.move(to: CGPoint(x: rect.minX + tailSize, y: rect.maxY - 16))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - 8))
            path.addLine(to: CGPoint(x: rect.minX + tailSize, y: rect.maxY - 4))
        }

        return path
    }
}
