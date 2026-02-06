import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date

    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }

    static func userMessage(_ content: String) -> ChatMessage {
        ChatMessage(role: .user, content: content)
    }

    static func assistantMessage(_ content: String) -> ChatMessage {
        ChatMessage(role: .assistant, content: content)
    }

    static func systemMessage(_ content: String) -> ChatMessage {
        ChatMessage(role: .system, content: content)
    }
}

enum MessageRole: String, Equatable {
    case user
    case assistant
    case system
}
