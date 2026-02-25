import SwiftUI

/// Represents a PDF document in the app
struct PDFDocumentItem: Identifiable {
    let id = UUID()
    var title: String
    var fileURL: URL?
    var pageCount: Int
    var fileSize: Int64
    var createdAt: Date = Date()
    var thumbnail: UIImage?

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var formattedDate: String {
        createdAt.formatted(date: .abbreviated, time: .omitted)
    }
}
