import Foundation

/// Represents a chat message in the conversation
struct Message: Identifiable, Codable, Equatable {
    let id: UUID
    let role: Role
    var content: String
    let createdAt: Date
    let sessionId: String

    init(
        id: UUID = UUID(),
        role: Role,
        content: String,
        createdAt: Date = Date(),
        sessionId: String
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.sessionId = sessionId
    }

    /// Message role in the conversation
    enum Role: String, Codable, CaseIterable {
        case user = "user"
        case assistant = "assistant"
        case system = "system"

        var displayName: String {
            switch self {
            case .user:
                return "You"
            case .assistant:
                return "Assistant"
            case .system:
                return "System"
            }
        }
    }
}

// MARK: - Validation
extension Message {
    /// Validate message content
    var isValid: Bool {
        return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               content.count <= 32000 // OpenAI token limit approximation
    }

    /// Get content word count
    var wordCount: Int {
        return content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
}

// MARK: - OpenAI API Compatibility
extension Message {
    /// Convert to OpenAI API format
    var openAIFormat: [String: Any] {
        return [
            "role": role.rawValue,
            "content": content
        ]
    }
}

// MARK: - Preview Data
#if DEBUG
extension Message {
    static let preview = Message(
        role: .user,
        content: "Hello, how are you?",
        sessionId: "preview-session"
    )

    static let previewAssistant = Message(
        role: .assistant,
        content: "I'm doing well, thank you! How can I help you today?",
        sessionId: "preview-session"
    )

    static let previewMessages = [
        Message(role: .user, content: "What is SwiftUI?", sessionId: "preview-session"),
        Message(role: .assistant, content: "SwiftUI is Apple's modern framework for building user interfaces across all Apple platforms. It uses a declarative syntax that makes it easy to create complex UIs with less code.", sessionId: "preview-session"),
        Message(role: .user, content: "Can you show me a simple example?", sessionId: "preview-session"),
        Message(role: .assistant, content: """
        Here's a simple SwiftUI view:

        ```swift
        struct ContentView: View {
            var body: some View {
                VStack {
                    Text("Hello, World!")
                        .font(.title)
                    Button("Tap me") {
                        print("Button tapped!")
                    }
                }
                .padding()
            }
        }
        ```

        This creates a vertical stack with text and a button.
        """, sessionId: "preview-session")
    ]
}
#endif
