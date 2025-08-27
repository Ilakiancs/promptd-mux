import XCTest
import SwiftUI
@testable import MenubarGPT

/// Unit tests for chat functionality using mock OpenAI client
class ChatTests: XCTestCase {
    
    var historyStore: HistoryStore!
    var mockOpenAIClient: MockOpenAIClient!
    
    override func setUp() {
        super.setUp()
        historyStore = HistoryStore.shared
        mockOpenAIClient = MockOpenAIClient()
        
        // Clear any existing data
        historyStore.clearMessages()
        mockOpenAIClient.reset()
    }
    
    override func tearDown() {
        historyStore = nil
        mockOpenAIClient = nil
        super.tearDown()
    }
    
    // MARK: - Message Storage Tests
    
    func testAddMessage() {
        // Given
        let sessionId = "test-session"
        let message = Message(
            role: .user,
            content: "Hello, world!",
            sessionId: sessionId
        )
        
        // When
        historyStore.addMessage(message)
        
        // Then
        XCTAssertEqual(historyStore.messages.count, 1)
        XCTAssertEqual(historyStore.messages.first?.content, "Hello, world!")
        XCTAssertEqual(historyStore.messages.first?.role, .user)
    }
    
    func testGetRecentMessages() {
        // Given
        let sessionId = "test-session"
        let messages = [
            Message(role: .user, content: "Message 1", sessionId: sessionId),
            Message(role: .assistant, content: "Response 1", sessionId: sessionId),
            Message(role: .user, content: "Message 2", sessionId: sessionId),
            Message(role: .assistant, content: "Response 2", sessionId: sessionId)
        ]
        
        for message in messages {
            historyStore.addMessage(message)
        }
        
        // When
        let recentMessages = historyStore.getRecentMessages(for: sessionId, limit: 3)
        
        // Then
        XCTAssertEqual(recentMessages.count, 3)
        XCTAssertEqual(recentMessages.last?.content, "Response 2")
    }
    
    // MARK: - Mock OpenAI Client Tests
    
    func testSuccessfulAPICall() async throws {
        // Given
        mockOpenAIClient.setSuccessResponse("This is a test response")
        let messages = [
            Message(role: .user, content: "Hello", sessionId: "test")
        ]
        
        // When
        let response = try await mockOpenAIClient.sendChatCompletion(
            messages: messages,
            model: .gpt4oMini
        )
        
        // Then
        XCTAssertEqual(response, "This is a test response")
        XCTAssertEqual(mockOpenAIClient.lastMessages.count, 1)
        XCTAssertEqual(mockOpenAIClient.lastMessages.first?.content, "Hello")
        XCTAssertEqual(mockOpenAIClient.lastModel, .gpt4oMini)
    }
    
    func testFailedAPICall() async {
        // Given
        mockOpenAIClient.setError(.unauthorized)
        let messages = [
            Message(role: .user, content: "Hello", sessionId: "test")
        ]
        
        // When/Then
        do {
            _ = try await mockOpenAIClient.sendChatCompletion(messages: messages)
            XCTFail("Expected error to be thrown")
        } catch let error as OpenAIClient.APIError {
            XCTAssertEqual(error, .unauthorized)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testStreamingAPICall() async throws {
        // Given
        mockOpenAIClient.setSuccessResponse("Hello world from streaming")
        let messages = [
            Message(role: .user, content: "Test streaming", sessionId: "test")
        ]
        
        var partialContent: [String] = []
        
        // When
        let response = try await mockOpenAIClient.sendStreamingChatCompletion(
            messages: messages,
            model: .gpt4o
        ) { chunk in
            partialContent.append(chunk)
        }
        
        // Then
        XCTAssertEqual(response, "Hello world from streaming")
        XCTAssertGreaterThan(partialContent.count, 1) // Should have received multiple chunks
        XCTAssertEqual(mockOpenAIClient.lastModel, .gpt4o)
    }
    
    // MARK: - Error State Tests
    
    func testRateLimitError() async {
        // Given
        mockOpenAIClient.setError(.rateLimited(retryAfter: 60))
        let messages = [Message(role: .user, content: "Test", sessionId: "test")]
        
        // When/Then
        do {
            _ = try await mockOpenAIClient.sendChatCompletion(messages: messages)
            XCTFail("Expected error to be thrown")
        } catch let error as OpenAIClient.APIError {
            if case .rateLimited(let retryAfter) = error {
                XCTAssertEqual(retryAfter, 60)
            } else {
                XCTFail("Expected rate limited error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testServerError() async {
        // Given
        mockOpenAIClient.setError(.serverError(503))
        let messages = [Message(role: .user, content: "Test", sessionId: "test")]
        
        // When/Then
        do {
            _ = try await mockOpenAIClient.sendChatCompletion(messages: messages)
            XCTFail("Expected error to be thrown")
        } catch let error as OpenAIClient.APIError {
            if case .serverError(let code) = error {
                XCTAssertEqual(code, 503)
            } else {
                XCTFail("Expected server error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Message Persistence Tests
    
    func testMessagePersistence() {
        // Given
        let sessionId = historyStore.createSession(with: "Test session")
        let userMessage = Message(role: .user, content: "Test message", sessionId: sessionId)
        let assistantMessage = Message(role: .assistant, content: "Test response", sessionId: sessionId)
        
        // When
        historyStore.addMessage(userMessage)
        historyStore.addMessage(assistantMessage)
        
        // Then
        XCTAssertEqual(historyStore.messages.count, 2)
        XCTAssertEqual(historyStore.sessions.count, 1)
        XCTAssertEqual(historyStore.currentSessionId, sessionId)
    }
    
    func testUpdateLastMessage() {
        // Given
        let sessionId = historyStore.createSession(with: "Test session")
        let message = Message(role: .assistant, content: "Initial", sessionId: sessionId)
        historyStore.addMessage(message)
        
        // When
        historyStore.updateLastMessage(content: "Updated content")
        
        // Then
        XCTAssertEqual(historyStore.messages.last?.content, "Updated content")
    }
}

// MARK: - OpenAI API Error Equality

extension OpenAIClient.APIError: Equatable {
    public static func == (lhs: OpenAIClient.APIError, rhs: OpenAIClient.APIError) -> Bool {
        switch (lhs, rhs) {
        case (.noApiKey, .noApiKey),
             (.invalidURL, .invalidURL),
             (.invalidResponse, .invalidResponse),
             (.unauthorized, .unauthorized):
            return true
        case let (.rateLimited(lhsRetry), .rateLimited(rhsRetry)):
            return lhsRetry == rhsRetry
        case let (.serverError(lhsCode), .serverError(rhsCode)):
            return lhsCode == rhsCode
        case let (.streamingError(lhsMsg), .streamingError(rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}
