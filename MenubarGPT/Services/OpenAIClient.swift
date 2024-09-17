import Foundation

/// Client for communicating with OpenAI API
final class OpenAIClient: ObservableObject {

    /// Errors that can occur during API communication
    enum APIError: Error, LocalizedError {
        case noApiKey
        case invalidURL
        case invalidResponse
        case unauthorized
        case rateLimited(retryAfter: Int?)
        case serverError(Int)
        case networkError(Error)
        case decodingError(Error)
        case streamingError(String)

        var errorDescription: String? {
            switch self {
            case .noApiKey:
                return "No API key found. Please add your OpenAI API key in settings."
            case .invalidURL:
                return "Invalid API endpoint URL."
            case .invalidResponse:
                return "Invalid response from OpenAI API."
            case .unauthorized:
                return "Invalid API key. Please check your OpenAI API key."
            case .rateLimited(let retryAfter):
                if let retryAfter = retryAfter {
                    return "Rate limit exceeded. Please try again in \(retryAfter) seconds."
                } else {
                    return "Rate limit exceeded. Please try again later."
                }
            case .serverError(let code):
                return "Server error (HTTP \(code)). Please try again later."
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .decodingError(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .streamingError(let message):
                return "Streaming error: \(message)"
            }
        }

        var shouldRetry: Bool {
            switch self {
            case .rateLimited:
                return true
            case .serverError(let code):
                return code >= 500
            case .networkError:
                return true
            default:
                return false
            }
        }
    }

    private let baseURL = "https://api.openai.com/v1"
    private let session: URLSession
    private let keychain = KeychainService.shared

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Send a chat completion request
    func sendChatCompletion(
        messages: [Message],
        model: OpenAIModel = .gpt4oMini,
        temperature: Double = 0.7,
        maxTokens: Int? = nil
    ) async throws -> String {

        guard let apiKey = try keychain.getApiKey() else {
            throw APIError.noApiKey
        }

        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw APIError.invalidURL
        }

        let requestBody = ChatCompletionRequest(
            model: model.rawValue,
            messages: messages.map { message in
                ChatMessage(role: message.role.rawValue, content: message.content)
            },
            temperature: temperature,
            maxTokens: maxTokens
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("promptd-mux/1.0", forHTTPHeaderField: "User-Agent")

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw APIError.decodingError(error)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            // Handle HTTP error codes
            switch httpResponse.statusCode {
            case 200...299:
                break // Success
            case 401:
                throw APIError.unauthorized
            case 429:
                // Extract retry-after header if available
                let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init)
                throw APIError.rateLimited(retryAfter: retryAfter)
            case 500...599:
                throw APIError.serverError(httpResponse.statusCode)
            default:
                throw APIError.serverError(httpResponse.statusCode)
            }

            let completionResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)

            guard let choice = completionResponse.choices.first,
                  let content = choice.message.content else {
                throw APIError.invalidResponse
            }

            return content.trimmingCharacters(in: .whitespacesAndNewlines)

        } catch let decodingError as DecodingError {
            throw APIError.decodingError(decodingError)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    /// Send a streaming chat completion request
    func sendStreamingChatCompletion(
        messages: [Message],
        model: OpenAIModel = .gpt4oMini,
        temperature: Double = 0.7,
        maxTokens: Int? = nil,
        onPartialContent: @escaping (String) -> Void
    ) async throws -> String {

        guard let apiKey = try keychain.getApiKey() else {
            throw APIError.noApiKey
        }

        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw APIError.invalidURL
        }

        let requestBody = StreamingChatCompletionRequest(
            model: model.rawValue,
            messages: messages.map { message in
                ChatMessage(role: message.role.rawValue, content: message.content)
            },
            temperature: temperature,
            maxTokens: maxTokens,
            stream: true
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("promptd-mux/1.0", forHTTPHeaderField: "User-Agent")

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw APIError.decodingError(error)
        }

        do {
            let (bytes, response) = try await session.bytes(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            // Handle HTTP error codes
            switch httpResponse.statusCode {
            case 200...299:
                break // Success
            case 401:
                throw APIError.unauthorized
            case 429:
                let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init)
                throw APIError.rateLimited(retryAfter: retryAfter)
            case 500...599:
                throw APIError.serverError(httpResponse.statusCode)
            default:
                throw APIError.serverError(httpResponse.statusCode)
            }

            var fullContent = ""

            for try await line in bytes.lines {
                if line.hasPrefix("data: ") {
                    let jsonString = String(line.dropFirst(6))

                    if jsonString == "[DONE]" {
                        break
                    }

                    guard let data = jsonString.data(using: .utf8) else {
                        continue
                    }

                    do {
                        let streamResponse = try JSONDecoder().decode(StreamingChatCompletionResponse.self, from: data)

                        if let delta = streamResponse.choices.first?.delta.content {
                            fullContent += delta
                            onPartialContent(delta)
                        }
                    } catch {
                        // Skip malformed chunks
                        continue
                    }
                }
            }

            return fullContent.trimmingCharacters(in: .whitespacesAndNewlines)

        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    /// Test the API key by making a lightweight request
    func testApiKey(_ apiKey: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/models") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("promptd-mux/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10.0

        do {
            let (_, response) = try await session.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    return true
                case 401:
                    return false
                default:
                    throw APIError.serverError(httpResponse.statusCode)
                }
            }

            return false
        } catch {
            if error is APIError {
                throw error
            }
            throw APIError.networkError(error)
        }
    }
}

// MARK: - Request/Response Models

private struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let maxTokens: Int?

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

private struct StreamingChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let maxTokens: Int?
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream
        case maxTokens = "max_tokens"
    }
}

private struct ChatMessage: Codable {
    let role: String
    let content: String?
}

private struct ChatCompletionResponse: Codable {
    let choices: [Choice]
    let usage: Usage?

    struct Choice: Codable {
        let message: ChatMessage
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }

    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

private struct StreamingChatCompletionResponse: Codable {
    let choices: [StreamingChoice]

    struct StreamingChoice: Codable {
        let delta: StreamingDelta
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case delta
            case finishReason = "finish_reason"
        }
    }

    struct StreamingDelta: Codable {
        let content: String?
        let role: String?
    }
}
// Fix: handle network timeout gracefully
// Feature: add retry mechanism
// Performance: reduce api call latency
// Feature: support new model versions
// Fix: handle api rate limits
