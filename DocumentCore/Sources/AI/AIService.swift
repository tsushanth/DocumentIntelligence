import Foundation

/// OpenAI API client for document intelligence
public final class AIService {

    public static let shared = AIService()

    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"
    private let model = "gpt-4"

    private let session: URLSession

    public init(apiKey: String = "") {
        self.apiKey = apiKey
        self.session = URLSession.shared
    }

    /// Configure API key
    public func configure(apiKey: String) {
        // In production, update this to store securely
    }

    /// Send a chat completion request to OpenAI
    public func chatCompletion(messages: [ChatMessage], temperature: Double = 0.7) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIServiceError.apiKeyNotSet
        }

        let endpoint = "\(baseURL)/chat/completions"
        guard let url = URL(string: endpoint) else {
            throw AIServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ChatCompletionRequest(
            model: model,
            messages: messages,
            temperature: temperature
        )

        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw AIServiceError.apiError(errorResponse.error.message)
            }
            throw AIServiceError.httpError(httpResponse.statusCode)
        }

        let completionResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)

        guard let content = completionResponse.choices.first?.message.content else {
            throw AIServiceError.noContent
        }

        return content
    }

    /// Extract structured data using function calling
    public func extractStructuredData<T: Codable>(
        from text: String,
        schema: T.Type,
        systemPrompt: String
    ) async throws -> T {
        let messages = [
            ChatMessage(role: .system, content: systemPrompt),
            ChatMessage(role: .user, content: text)
        ]

        let response = try await chatCompletion(messages: messages, temperature: 0.3)

        // Parse JSON response
        guard let data = response.data(using: .utf8) else {
            throw AIServiceError.invalidJSON
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Models

public struct ChatMessage: Codable {
    public let role: Role
    public let content: String

    public enum Role: String, Codable {
        case system
        case user
        case assistant
    }

    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
}

struct ChatCompletionResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: ChatMessage
    }
}

struct OpenAIErrorResponse: Codable {
    let error: OpenAIError

    struct OpenAIError: Codable {
        let message: String
    }
}

// MARK: - Errors

public enum AIServiceError: LocalizedError {
    case apiKeyNotSet
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case noContent
    case invalidJSON

    public var errorDescription: String? {
        switch self {
        case .apiKeyNotSet:
            return "OpenAI API key is not set"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "API error: \(message)"
        case .noContent:
            return "No content in response"
        case .invalidJSON:
            return "Invalid JSON response"
        }
    }
}
