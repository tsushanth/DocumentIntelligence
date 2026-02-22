import Foundation

/// Analyzes documents using AI to extract insights
public final class DocumentAnalyzer {

    private let aiService: AIService

    public init(aiService: AIService = .shared) {
        self.aiService = aiService
    }

    /// Generate a summary of the document
    public func summarize(text: String, maxLength: Int = 200) async throws -> String {
        let messages = [
            ChatMessage(role: .system, content: Prompts.summarizeSystem),
            ChatMessage(role: .user, content: "Summarize this document in under \(maxLength) words:\n\n\(text)")
        ]

        return try await aiService.chatCompletion(messages: messages, temperature: 0.5)
    }

    /// Categorize the document
    public func categorize(text: String) async throws -> DocumentCategory {
        let messages = [
            ChatMessage(role: .system, content: Prompts.categorizeSystem),
            ChatMessage(role: .user, content: text)
        ]

        let response = try await aiService.chatCompletion(messages: messages, temperature: 0.3)

        return DocumentCategory(rawValue: response.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
            ?? .other
    }

    /// Answer a question about the document
    public func answerQuestion(text: String, question: String) async throws -> String {
        let messages = [
            ChatMessage(role: .system, content: Prompts.questionAnsweringSystem),
            ChatMessage(role: .user, content: "Document:\n\(text)\n\nQuestion: \(question)")
        ]

        return try await aiService.chatCompletion(messages: messages, temperature: 0.7)
    }

    /// Extract key points from the document
    public func extractKeyPoints(text: String) async throws -> [String] {
        let messages = [
            ChatMessage(role: .system, content: Prompts.keyPointsSystem),
            ChatMessage(role: .user, content: text)
        ]

        let response = try await aiService.chatCompletion(messages: messages, temperature: 0.5)

        // Parse bullet points
        return response
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.hasPrefix("-") || $0.hasPrefix("•") || $0.hasPrefix("*") }
            .map { $0.replacingOccurrences(of: "^[-•*]\\s*", with: "", options: .regularExpression) }
            .filter { !$0.isEmpty }
    }

    /// Analyze a contract for key clauses
    public func analyzeContract(text: String) async throws -> ContractAnalysis {
        let messages = [
            ChatMessage(role: .system, content: Prompts.contractAnalysisSystem),
            ChatMessage(role: .user, content: text)
        ]

        let response = try await aiService.chatCompletion(messages: messages, temperature: 0.3)

        // Parse the response as JSON
        guard let data = response.data(using: .utf8) else {
            throw AIServiceError.invalidJSON
        }

        return try JSONDecoder().decode(ContractAnalysis.self, from: data)
    }
}

// MARK: - Supporting Types

public struct ContractAnalysis: Codable {
    public let parties: [String]
    public let effectiveDate: String?
    public let expirationDate: String?
    public let keyClauses: [String]
    public let obligations: [String]
    public let risks: [String]

    public init(
        parties: [String],
        effectiveDate: String?,
        expirationDate: String?,
        keyClauses: [String],
        obligations: [String],
        risks: [String]
    ) {
        self.parties = parties
        self.effectiveDate = effectiveDate
        self.expirationDate = expirationDate
        self.keyClauses = keyClauses
        self.obligations = obligations
        self.risks = risks
    }
}
