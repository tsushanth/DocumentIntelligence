import Foundation
import SwiftUI

/// Represents a scanned or imported document
public struct Document: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var pages: [DocumentPage]
    public var createdAt: Date
    public var modifiedAt: Date
    public var folderId: UUID?
    public var tags: [String]
    public var ocrText: String?
    public var aiSummary: String?
    public var extractedFields: [ExtractedField]?
    public var category: DocumentCategory?

    public init(
        id: UUID = UUID(),
        title: String,
        pages: [DocumentPage] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        folderId: UUID? = nil,
        tags: [String] = [],
        ocrText: String? = nil,
        aiSummary: String? = nil,
        extractedFields: [ExtractedField]? = nil,
        category: DocumentCategory? = nil
    ) {
        self.id = id
        self.title = title
        self.pages = pages
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.folderId = folderId
        self.tags = tags
        self.ocrText = ocrText
        self.aiSummary = aiSummary
        self.extractedFields = extractedFields
        self.category = category
    }

    /// Total page count
    public var pageCount: Int {
        pages.count
    }
}

/// Represents a single page in a document
public struct DocumentPage: Identifiable, Codable, Hashable {
    public let id: UUID
    public var imageData: Data
    public var thumbnailData: Data?
    public var ocrText: String?
    public var pageNumber: Int
    public var filter: ImageFilter

    public init(
        id: UUID = UUID(),
        imageData: Data,
        thumbnailData: Data? = nil,
        ocrText: String? = nil,
        pageNumber: Int,
        filter: ImageFilter = .original
    ) {
        self.id = id
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.ocrText = ocrText
        self.pageNumber = pageNumber
        self.filter = filter
    }
}

/// Image filter types for document enhancement
public enum ImageFilter: String, Codable, CaseIterable {
    case original = "Original"
    case blackAndWhite = "Black & White"
    case grayscale = "Grayscale"
    case highContrast = "High Contrast"
    case colorEnhanced = "Color Enhanced"

    public var displayName: String {
        rawValue
    }
}

/// Extracted field from document analysis
public struct ExtractedField: Identifiable, Codable, Hashable {
    public let id: UUID
    public var fieldType: FieldType
    public var value: String
    public var confidence: Double

    public init(
        id: UUID = UUID(),
        fieldType: FieldType,
        value: String,
        confidence: Double = 1.0
    ) {
        self.id = id
        self.fieldType = fieldType
        self.value = value
        self.confidence = confidence
    }
}

/// Types of fields that can be extracted from documents
public enum FieldType: String, Codable, CaseIterable {
    case date = "Date"
    case amount = "Amount"
    case total = "Total"
    case vendorName = "Vendor"
    case invoiceNumber = "Invoice #"
    case dueDate = "Due Date"
    case accountNumber = "Account #"
    case address = "Address"
    case phoneNumber = "Phone"
    case email = "Email"
    case taxAmount = "Tax"
    case subtotal = "Subtotal"
}

/// Document categories for organization
public enum DocumentCategory: String, Codable, CaseIterable {
    case receipt = "Receipt"
    case invoice = "Invoice"
    case bill = "Bill"
    case contract = "Contract"
    case form = "Form"
    case letter = "Letter"
    case report = "Report"
    case identification = "ID"
    case medical = "Medical"
    case financial = "Financial"
    case other = "Other"

    public var icon: String {
        switch self {
        case .receipt: return "receipt"
        case .invoice: return "doc.text"
        case .bill: return "dollarsign.circle"
        case .contract: return "signature"
        case .form: return "doc.plaintext"
        case .letter: return "envelope"
        case .report: return "chart.bar.doc.horizontal"
        case .identification: return "person.text.rectangle"
        case .medical: return "cross.case"
        case .financial: return "banknote"
        case .other: return "doc"
        }
    }
}
