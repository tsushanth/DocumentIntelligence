import CoreGraphics
import Foundation

/// Represents a block of recognized text with its location
public struct TextBlock: Codable, Identifiable {
    public let id: UUID
    public let text: String
    public let confidence: Float
    public let boundingBox: CGRect

    public init(text: String, confidence: Float, boundingBox: CGRect) {
        self.id = UUID()
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
    }

    /// Whether this text block has high confidence
    public var isHighConfidence: Bool {
        confidence >= 0.8
    }

    /// Whether this text block has medium confidence
    public var isMediumConfidence: Bool {
        confidence >= 0.5 && confidence < 0.8
    }

    /// Whether this text block has low confidence
    public var isLowConfidence: Bool {
        confidence < 0.5
    }

    /// Extract potential dates from the text
    public var potentialDates: [String] {
        let patterns = [
            "\\d{1,2}/\\d{1,2}/\\d{2,4}",  // MM/DD/YYYY or M/D/YY
            "\\d{1,2}-\\d{1,2}-\\d{2,4}",  // MM-DD-YYYY
            "\\d{4}-\\d{2}-\\d{2}",         // YYYY-MM-DD
            "[A-Za-z]+ \\d{1,2},? \\d{4}"  // January 1, 2026
        ]

        var dates: [String] = []
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(text.startIndex..., in: text)
                let matches = regex.matches(in: text, options: [], range: range)
                dates.append(contentsOf: matches.compactMap { match in
                    guard let range = Range(match.range, in: text) else { return nil }
                    return String(text[range])
                })
            }
        }
        return dates
    }

    /// Extract potential monetary amounts from the text
    public var potentialAmounts: [String] {
        let patterns = [
            "\\$\\s?\\d+(?:,\\d{3})*(?:\\.\\d{2})?",  // $1,234.56
            "\\d+(?:,\\d{3})*(?:\\.\\d{2})?\\s?(?:USD|EUR|GBP)",  // 1234.56 USD
        ]

        var amounts: [String] = []
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(text.startIndex..., in: text)
                let matches = regex.matches(in: text, options: [], range: range)
                amounts.append(contentsOf: matches.compactMap { match in
                    guard let range = Range(match.range, in: text) else { return nil }
                    return String(text[range])
                })
            }
        }
        return amounts
    }

    /// Extract potential email addresses from the text
    public var potentialEmails: [String] {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)

        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        }
    }

    /// Extract potential phone numbers from the text
    public var potentialPhoneNumbers: [String] {
        let patterns = [
            "\\(\\d{3}\\)\\s?\\d{3}-\\d{4}",  // (555) 123-4567
            "\\d{3}-\\d{3}-\\d{4}",            // 555-123-4567
            "\\d{10}",                          // 5551234567
        ]

        var phoneNumbers: [String] = []
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(text.startIndex..., in: text)
                let matches = regex.matches(in: text, options: [], range: range)
                phoneNumbers.append(contentsOf: matches.compactMap { match in
                    guard let range = Range(match.range, in: text) else { return nil }
                    return String(text[range])
                })
            }
        }
        return phoneNumbers
    }
}
