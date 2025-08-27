import Foundation
@testable import MenubarGPT

/// Mock OpenAI client for testing
class MockOpenAIClient: ObservableObject {
    var shouldSucceed = true
    var mockResponse = "Mock response from AI"
    var mockError: OpenAIClient.APIError?
    var lastMessages: [Message] = []
    var lastModel: OpenAIModel?
    
    private let delay: TimeInterval
    
    init(delay: TimeInterval = 0.1) {
        self.delay = delay
    }
    
    func sendChatCompletion(
        messages: [Message],
        model: OpenAIModel = .gpt4oMini,
        temperature: Double = 0.7,
        maxTokens: Int? = nil
    ) async throws -> String {
        
        // Store the parameters for verification
        lastMessages = messages
        lastModel = model
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        if let error = mockError {
            throw error
        }
        
        if shouldSucceed {
            return mockResponse
        } else {
            throw OpenAIClient.APIError.serverError(500)
        }
    }
    
    func sendStreamingChatCompletion(
        messages: [Message],
        model: OpenAIModel = .gpt4oMini,
        temperature: Double = 0.7,
        maxTokens: Int? = nil,
        onPartialContent: @escaping (String) -> Void
    ) async throws -> String {
        
        // Store the parameters for verification
        lastMessages = messages
        lastModel = model
        
        if let error = mockError {
            throw error
        }
        
        if shouldSucceed {
            // Simulate streaming by sending chunks
            let chunks = mockResponse.components(separatedBy: " ")
            var accumulatedResponse = ""
            
            for chunk in chunks {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                let chunkWithSpace = chunk + " "
                onPartialContent(chunkWithSpace)
                accumulatedResponse += chunkWithSpace
            }
            
            return accumulatedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            throw OpenAIClient.APIError.serverError(500)
        }
    }
    
    func testApiKey(_ apiKey: String) async throws -> Bool {
        if let error = mockError {
            throw error
        }
        return shouldSucceed
    }
    
    // Helper methods for testing
    func setSuccessResponse(_ response: String) {
        shouldSucceed = true
        mockResponse = response
        mockError = nil
    }
    
    func setError(_ error: OpenAIClient.APIError) {
        shouldSucceed = false
        mockError = error
    }
    
    func reset() {
        shouldSucceed = true
        mockResponse = "Mock response from AI"
        mockError = nil
        lastMessages = []
        lastModel = nil
    }
}
