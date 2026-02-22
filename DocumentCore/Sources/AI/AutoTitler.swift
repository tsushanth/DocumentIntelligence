import Foundation

/// Generates smart titles for documents
public final class AutoTitler {

    private let aiService: AIService

    public init(aiService: AIService = .shared) {
        self.aiService = aiService
    }

    /// Generate a descriptive title for a document
    public func generateTitle(from text: String) async throws -> String {
        let messages = [
            ChatMessage(role: .system, content: Prompts.autoTitleSystem),
            ChatMessage(role: .user, content: text)
        ]

        let title = try await aiService.chatCompletion(messages: messages, temperature: 0.5)

        // Clean up the title
        return title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
            .prefix(100)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .description
    }

    /// Generate a title based on document category and extracted fields
    public func generateTitle(
        category: DocumentCategory,
        fields: ExtractedFields
    ) -> String {
        switch category {
        case .invoice:
            if let vendor = fields.vendorName, let date = fields.date {
                return "Invoice - \(vendor) - \(formatDate(date))"
            } else if let vendor = fields.vendorName {
                return "Invoice - \(vendor)"
            }
            return "Invoice - \(formatDate(Date()))"

        case .receipt:
            if let vendor = fields.vendorName, let total = fields.totalAmount {
                return "Receipt - \(vendor) - $\(String(format: "%.2f", total))"
            } else if let vendor = fields.vendorName {
                return "Receipt - \(vendor)"
            }
            return "Receipt - \(formatDate(Date()))"

        case .contract:
            if let parties = fields.parties, !parties.isEmpty {
                return "Contract - \(parties.joined(separator: " & "))"
            }
            return "Contract - \(formatDate(Date()))"

        case .bill:
            if let vendor = fields.vendorName, let date = fields.date {
                return "Bill - \(vendor) - \(formatDate(date))"
            } else if let vendor = fields.vendorName {
                return "Bill - \(vendor)"
            }
            return "Bill - \(formatDate(Date()))"

        case .financial:
            if let accountName = fields.accountName, let date = fields.date {
                return "Statement - \(accountName) - \(formatDate(date))"
            }
            return "Financial - \(formatDate(Date()))"

        case .letter, .report, .form, .identification, .medical, .other:
            if let subject = fields.subject {
                return subject
            }
            return "\(category.displayName) - \(formatDate(Date()))"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}
