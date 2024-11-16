import Foundation
import Combine

/// Store for persisting chat history and sessions
final class HistoryStore: ObservableObject {
    
    @Published var sessions: [Session] = []
    @Published var currentSessionId: String?
    @Published var messages: [Message] = []
    
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    /// Maximum number of messages to keep per session
    private let maxMessagesPerSession = 100
    
    /// Maximum number of sessions to keep
    private let maxSessions = 20
    
    static let shared = HistoryStore()
    
    private init() {
        setupEncoder()
        loadData()
    }
    
    private func setupEncoder() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - File Paths
    
    private var applicationSupportURL: URL {
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportURL = urls.first!.appendingPathComponent("MenubarGPT")
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        
        return appSupportURL
    }
    
    private var sessionsFileURL: URL {
        applicationSupportURL.appendingPathComponent("sessions.json")
    }
    
    private func messagesFileURL(for sessionId: String) -> URL {
        applicationSupportURL.appendingPathComponent("messages_\(sessionId).json")
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        loadSessions()
        if let currentId = currentSessionId {
            loadMessages(for: currentId)
        }
    }
    
    private func loadSessions() {
        guard fileManager.fileExists(atPath: sessionsFileURL.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: sessionsFileURL)
            let loadedSessions = try decoder.decode([Session].self, from: data)
            
            DispatchQueue.main.async {
                self.sessions = loadedSessions.sorted { $0.lastMessageAt > $1.lastMessageAt }
                self.currentSessionId = self.sessions.first?.id
            }
        } catch {
            print("Failed to load sessions: \(error)")
        }
    }
    
    private func loadMessages(for sessionId: String) {
        let fileURL = messagesFileURL(for: sessionId)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            DispatchQueue.main.async {
                self.messages = []
            }
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let loadedMessages = try decoder.decode([Message].self, from: data)
            
            DispatchQueue.main.async {
                self.messages = loadedMessages.sorted { $0.createdAt < $1.createdAt }
            }
        } catch {
            print("Failed to load messages for session \(sessionId): \(error)")
            DispatchQueue.main.async {
                self.messages = []
            }
        }
    }
    
    // MARK: - Session Management
    
    /// Create a new chat session
    func createSession(with firstMessage: String) -> String {
        let title = Session.generateTitle(from: firstMessage)
        let session = Session(title: title)
        
        sessions.insert(session, at: 0)
        currentSessionId = session.id
        messages = []
        
        // Limit number of sessions
        if sessions.count > maxSessions {
            let sessionsToRemove = sessions.suffix(sessions.count - maxSessions)
            for session in sessionsToRemove {
                deleteSessionFiles(sessionId: session.id)
            }
            sessions = Array(sessions.prefix(maxSessions))
        }
        
        saveSessions()
        return session.id
    }
    
    /// Add a new message to the current session
    func addMessage(_ message: Message) {
        messages.append(message)
        
        // Update session's last message time
        if let sessionIndex = sessions.firstIndex(where: { $0.id == message.sessionId }) {
            sessions[sessionIndex].lastMessageAt = message.createdAt
            
            // Move session to top
            let session = sessions.remove(at: sessionIndex)
            sessions.insert(session, at: 0)
        }
        
        saveMessages(for: message.sessionId)
        saveSessions()
    }
    
    /// Update the content of the last message (for streaming)
    func updateLastMessage(content: String) {
        guard let lastIndex = messages.indices.last else { return }
        messages[lastIndex].content = content
        
        // Save every few characters to avoid too frequent I/O
        if content.count % 10 == 0 {
            if let sessionId = currentSessionId {
                saveMessages(for: sessionId)
            }
        }
    }
    
    /// Get recent messages for a session (up to last 20 for context)
    func getRecentMessages(for sessionId: String, limit: Int = 20) -> [Message] {
        let sessionMessages = messages.filter { $0.sessionId == sessionId }
            .sorted { $0.createdAt < $1.createdAt }
        
        return Array(sessionMessages.suffix(limit))
    }
    
    /// Clear all messages in the current session
    func clearMessages() {
        guard let currentId = currentSessionId else { return }
        
        // Remove messages from the array
        messages.removeAll { $0.sessionId == currentId }
        
        // Delete the messages file
        deleteSessionFiles(sessionId: currentId)
        
        // Create a new session for future messages
        currentSessionId = nil
    }
    
    // MARK: - Data Saving
    
    private func saveSessions() {
        do {
            let data = try encoder.encode(sessions)
            try data.write(to: sessionsFileURL)
        } catch {
            print("Failed to save sessions: \(error)")
        }
    }
    
    private func saveMessages(for sessionId: String) {
        let sessionMessages = messages.filter { $0.sessionId == sessionId }
        let fileURL = messagesFileURL(for: sessionId)
        
        do {
            let data = try encoder.encode(sessionMessages)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save messages for session \(sessionId): \(error)")
        }
    }
    
    private func deleteSessionFiles(sessionId: String) {
        let fileURL = messagesFileURL(for: sessionId)
        try? fileManager.removeItem(at: fileURL)
    }
}

// MARK: - Session Model
struct Session: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let createdAt: Date
    var lastMessageAt: Date
    
    init(
        id: String = UUID().uuidString,
        title: String,
        createdAt: Date = Date(),
        lastMessageAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.lastMessageAt = lastMessageAt
    }
    
    /// Generate a title from the first user message
    static func generateTitle(from firstMessage: String) -> String {
        let trimmed = firstMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Take first 50 characters and ensure we don't cut off in the middle of a word
        if trimmed.count <= 50 {
            return trimmed
        }
        
        let truncated = String(trimmed.prefix(50))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "..."
        } else {
            return truncated + "..."
        }
    }
}

// MARK: - Preview/Test Support
#if DEBUG
extension HistoryStore {
    /// Create a store with sample data for previews
    static func preview() -> HistoryStore {
        let store = HistoryStore()
        store.sessions = [
            Session(title: "SwiftUI Discussion", createdAt: Date().addingTimeInterval(-3600))
        ]
        store.messages = Message.previewMessages
        store.currentSessionId = "preview-session"
        return store
    }
}
#endif