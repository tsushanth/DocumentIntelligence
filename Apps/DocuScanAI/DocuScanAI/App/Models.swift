import SwiftUI

/// Represents a scanned document
struct ScannedDocument: Identifiable, Codable {
    let id: UUID
    var title: String
    var pageCount: Int
    var createdAt: Date
    var updatedAt: Date
    var thumbnailData: Data?
    var aiTitle: String?
    var ocrText: String?
    var summary: String?
    var extractedFields: ExtractedDocumentFields?
    var fileName: String // relative filename within Documents/Scans/
    var folderId: UUID?

    init(id: UUID = UUID(), title: String, pageCount: Int, fileName: String = "", createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.pageCount = pageCount
        self.fileName = fileName
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }

    var thumbnail: UIImage? {
        guard let data = thumbnailData else { return nil }
        return UIImage(data: data)
    }

    var fileURL: URL? {
        guard !fileName.isEmpty else { return nil }
        return DocumentStore.scansDirectory.appendingPathComponent(fileName)
    }

    var displayTitle: String {
        aiTitle ?? title
    }

    var hasAIInsights: Bool {
        aiTitle != nil || summary != nil || extractedFields != nil
    }

    var formattedDate: String {
        createdAt.formatted(date: .abbreviated, time: .omitted)
    }
}

/// Represents a folder for organizing documents
struct DocumentFolder: Identifiable, Codable {
    let id: UUID
    var name: String
    var color: String?
    var createdAt: Date
    var documentIds: [UUID]

    init(id: UUID = UUID(), name: String, color: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.color = color
        self.createdAt = createdAt
        self.documentIds = []
    }

    var documentCount: Int {
        documentIds.count
    }
}
