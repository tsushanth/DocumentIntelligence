import Foundation

/// Extracts structured fields from documents
public final class FieldExtractor {

    private let aiService: AIService

    public init(aiService: AIService = .shared) {
        self.aiService = aiService
    }

    /// Extract key fields from document text
    public func extractFields(from text: String) async throws -> ExtractedFields {
        let messages = [
            ChatMessage(role: .system, content: Prompts.fieldExtractionSystem),
            ChatMessage(role: .user, content: text)
        ]

        let response = try await aiService.chatCompletion(messages: messages, temperature: 0.3)

        // Parse JSON response
        guard let data = response.data(using: .utf8) else {
            throw AIServiceError.invalidJSON
        }

        return try JSONDecoder().decode(ExtractedFields.self, from: data)
    }

    /// Extract invoice-specific fields
    public func extractInvoiceFields(from text: String) async throws -> InvoiceFields {
        let messages = [
            ChatMessage(role: .system, content: Prompts.invoiceExtractionSystem),
            ChatMessage(role: .user, content: text)
        ]

        let response = try await aiService.chatCompletion(messages: messages, temperature: 0.2)

        guard let data = response.data(using: .utf8) else {
            throw AIServiceError.invalidJSON
        }

        return try JSONDecoder().decode(InvoiceFields.self, from: data)
    }

    /// Extract receipt-specific fields
    public func extractReceiptFields(from text: String) async throws -> ReceiptFields {
        let messages = [
            ChatMessage(role: .system, content: Prompts.receiptExtractionSystem),
            ChatMessage(role: .user, content: text)
        ]

        let response = try await aiService.chatCompletion(messages: messages, temperature: 0.2)

        guard let data = response.data(using: .utf8) else {
            throw AIServiceError.invalidJSON
        }

        return try JSONDecoder().decode(ReceiptFields.self, from: data)
    }
}

// MARK: - Extracted Field Models

public struct ExtractedFields: Codable {
    public let date: Date?
    public let vendorName: String?
    public let totalAmount: Double?
    public let currency: String?
    public let invoiceNumber: String?
    public let parties: [String]?
    public let subject: String?
    public let accountName: String?
    public let emails: [String]?
    public let phoneNumbers: [String]?
    public let addresses: [String]?

    public init(
        date: Date? = nil,
        vendorName: String? = nil,
        totalAmount: Double? = nil,
        currency: String? = nil,
        invoiceNumber: String? = nil,
        parties: [String]? = nil,
        subject: String? = nil,
        accountName: String? = nil,
        emails: [String]? = nil,
        phoneNumbers: [String]? = nil,
        addresses: [String]? = nil
    ) {
        self.date = date
        self.vendorName = vendorName
        self.totalAmount = totalAmount
        self.currency = currency
        self.invoiceNumber = invoiceNumber
        self.parties = parties
        self.subject = subject
        self.accountName = accountName
        self.emails = emails
        self.phoneNumbers = phoneNumbers
        self.addresses = addresses
    }
}

public struct InvoiceFields: Codable {
    public let invoiceNumber: String?
    public let invoiceDate: Date?
    public let dueDate: Date?
    public let vendorName: String?
    public let vendorAddress: String?
    public let vendorEmail: String?
    public let vendorPhone: String?
    public let customerName: String?
    public let customerAddress: String?
    public let lineItems: [LineItem]?
    public let subtotal: Double?
    public let tax: Double?
    public let total: Double?
    public let currency: String?
    public let paymentTerms: String?

    public struct LineItem: Codable {
        public let description: String
        public let quantity: Double?
        public let unitPrice: Double?
        public let amount: Double

        public init(description: String, quantity: Double?, unitPrice: Double?, amount: Double) {
            self.description = description
            self.quantity = quantity
            self.unitPrice = unitPrice
            self.amount = amount
        }
    }

    public init(
        invoiceNumber: String? = nil,
        invoiceDate: Date? = nil,
        dueDate: Date? = nil,
        vendorName: String? = nil,
        vendorAddress: String? = nil,
        vendorEmail: String? = nil,
        vendorPhone: String? = nil,
        customerName: String? = nil,
        customerAddress: String? = nil,
        lineItems: [LineItem]? = nil,
        subtotal: Double? = nil,
        tax: Double? = nil,
        total: Double? = nil,
        currency: String? = nil,
        paymentTerms: String? = nil
    ) {
        self.invoiceNumber = invoiceNumber
        self.invoiceDate = invoiceDate
        self.dueDate = dueDate
        self.vendorName = vendorName
        self.vendorAddress = vendorAddress
        self.vendorEmail = vendorEmail
        self.vendorPhone = vendorPhone
        self.customerName = customerName
        self.customerAddress = customerAddress
        self.lineItems = lineItems
        self.subtotal = subtotal
        self.tax = tax
        self.total = total
        self.currency = currency
        self.paymentTerms = paymentTerms
    }
}

public struct ReceiptFields: Codable {
    public let merchantName: String?
    public let merchantAddress: String?
    public let date: Date?
    public let time: String?
    public let items: [Item]?
    public let subtotal: Double?
    public let tax: Double?
    public let tip: Double?
    public let total: Double?
    public let paymentMethod: String?
    public let lastFourDigits: String?

    public struct Item: Codable {
        public let description: String
        public let quantity: Double?
        public let price: Double

        public init(description: String, quantity: Double?, price: Double) {
            self.description = description
            self.quantity = quantity
            self.price = price
        }
    }

    public init(
        merchantName: String? = nil,
        merchantAddress: String? = nil,
        date: Date? = nil,
        time: String? = nil,
        items: [Item]? = nil,
        subtotal: Double? = nil,
        tax: Double? = nil,
        tip: Double? = nil,
        total: Double? = nil,
        paymentMethod: String? = nil,
        lastFourDigits: String? = nil
    ) {
        self.merchantName = merchantName
        self.merchantAddress = merchantAddress
        self.date = date
        self.time = time
        self.items = items
        self.subtotal = subtotal
        self.tax = tax
        self.tip = tip
        self.total = total
        self.paymentMethod = paymentMethod
        self.lastFourDigits = lastFourDigits
    }
}
