import Foundation

/// AI Service that connects to your proxy server (not directly to OpenAI)
/// This is more secure as API keys stay on your server
public final class AIService {

    public static let shared = AIService()

    /// Your GCP Cloud Run proxy URL
    private var proxyBaseURL = "https://docint-proxy-917362189743.us-central1.run.app"

    /// App API key to authenticate with YOUR proxy
    private var appApiKey = "docint-f8a3b2c1-4d5e-6f7a-8b9c-0d1e2f3a4b5c"

    /// Bundle ID for additional verification
    private let bundleId = Bundle.main.bundleIdentifier ?? ""

    private let session: URLSession
    private let model = "gpt-4"

    public init() {
        self.session = URLSession.shared
    }

    /// Configure the proxy URL and app API key
    /// Call this on app launch with your deployed proxy URL
    public func configure(proxyURL: String, appApiKey: String) {
        self.proxyBaseURL = proxyURL
        self.appApiKey = appApiKey
    }

    /// Send a chat completion request through the proxy
    public func chatCompletion(messages: [ChatMessage], temperature: Double = 0.7) async throws -> String {
        let endpoint = "\(proxyBaseURL)/api/chat/completions"
        guard let url = URL(string: endpoint) else {
            throw AIServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(appApiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(bundleId, forHTTPHeaderField: "X-Bundle-ID")
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
            if let errorResponse = try? JSONDecoder().decode(ProxyErrorResponse.self, from: data) {
                throw AIServiceError.apiError(errorResponse.error)
            }
            throw AIServiceError.httpError(httpResponse.statusCode)
        }

        let completionResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)

        guard let content = completionResponse.choices.first?.message.content else {
            throw AIServiceError.noContent
        }

        return content
    }

    /// Analyze document using the convenience endpoint
    public func analyzeDocument(text: String, task: AnalysisTask) async throws -> String {
        let endpoint = "\(proxyBaseURL)/api/analyze"
        guard let url = URL(string: endpoint) else {
            throw AIServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(appApiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(bundleId, forHTTPHeaderField: "X-Bundle-ID")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["text": text, "task": task.rawValue]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AIServiceError.invalidResponse
        }

        let result = try JSONDecoder().decode(AnalyzeResponse.self, from: data)
        return result.result
    }

    /// Ask a question about a document
    public func askQuestion(document: String, question: String) async throws -> String {
        let endpoint = "\(proxyBaseURL)/api/ask"
        guard let url = URL(string: endpoint) else {
            throw AIServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(appApiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(bundleId, forHTTPHeaderField: "X-Bundle-ID")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["document": document, "question": question]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AIServiceError.invalidResponse
        }

        let result = try JSONDecoder().decode(AskResponse.self, from: data)
        return result.answer
    }

    public enum AnalysisTask: String {
        case summarize
        case categorize
        case title
        case extract
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

struct ProxyErrorResponse: Codable {
    let error: String
}

struct AnalyzeResponse: Codable {
    let result: String
}

struct AskResponse: Codable {
    let answer: String
}

// MARK: - Errors

public enum AIServiceError: LocalizedError {
    case proxyNotConfigured
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case noContent
    case invalidJSON

    public var errorDescription: String? {
        switch self {
        case .proxyNotConfigured:
            return "AI proxy is not configured"
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
