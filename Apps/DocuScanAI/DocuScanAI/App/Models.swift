import SwiftUI

/// Represents a scanned document
struct ScannedDocument: Identifiable {
    let id = UUID()
    var title: String
    var pageCount: Int
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var thumbnail: UIImage?
    var aiTitle: String?
    var ocrText: String?
    var summary: String?
    var fileURL: URL?
    var folderId: UUID?
    
    var displayTitle: String {
        aiTitle ?? title
    }
    
    var hasAIInsights: Bool {
        aiTitle != nil || summary != nil
    }
    
    var formattedDate: String {
        createdAt.formatted(date: .abbreviated, time: .omitted)
    }
}

/// Represents a folder for organizing documents
struct DocumentFolder: Identifiable {
    let id = UUID()
    var name: String
    var color: String?
    var createdAt: Date = Date()
    var documents: [ScannedDocument] = []
    
    var documentCount: Int {
        documents.count
    }
}
