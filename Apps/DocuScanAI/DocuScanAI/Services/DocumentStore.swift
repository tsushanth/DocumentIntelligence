import SwiftUI
import PDFKit

/// Persistent storage for scanned documents.
/// Saves PDF files to Documents/Scans/ and metadata to Documents/documents.json.
@MainActor
final class DocumentStore: ObservableObject {
    static let shared = DocumentStore()

    @Published var documents: [ScannedDocument] = []
    @Published var folders: [DocumentFolder] = []

    static let scansDirectory: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let scans = docs.appendingPathComponent("Scans", isDirectory: true)
        try? FileManager.default.createDirectory(at: scans, withIntermediateDirectories: true)
        return scans
    }()

    private static var metadataURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("documents.json")
    }

    private static var foldersURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("folders.json")
    }

    private init() {
        loadDocuments()
        loadFolders()
    }

    // MARK: - Save scanned images as PDF + persist metadata

    func saveScannedDocument(title: String, images: [UIImage]) -> ScannedDocument? {
        guard !images.isEmpty else { return nil }

        let id = UUID()
        let fileName = "\(id.uuidString).pdf"
        let fileURL = Self.scansDirectory.appendingPathComponent(fileName)

        // Create PDF from images
        let pdfDocument = PDFDocument()
        for (index, image) in images.enumerated() {
            guard let page = PDFPage(image: image) else { continue }
            pdfDocument.insert(page, at: index)
        }

        guard pdfDocument.write(to: fileURL) else {
            return nil
        }

        // Generate thumbnail from first image
        let thumbnailData = generateThumbnail(from: images[0])

        let doc = ScannedDocument(
            id: id,
            title: title.isEmpty ? "Scan \(Date().formatted(date: .abbreviated, time: .shortened))" : title,
            pageCount: images.count,
            fileName: fileName,
            createdAt: Date()
        )
        var mutableDoc = doc
        mutableDoc.thumbnailData = thumbnailData

        documents.insert(mutableDoc, at: 0)
        saveMetadata()

        return mutableDoc
    }

    // MARK: - Update

    func updateDocument(_ document: ScannedDocument) {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        documents[index] = document
        saveMetadata()
    }

    // MARK: - Delete

    func deleteDocument(_ document: ScannedDocument) {
        // Remove PDF file
        if let url = document.fileURL {
            try? FileManager.default.removeItem(at: url)
        }

        // Remove from array
        documents.removeAll { $0.id == document.id }

        // Remove from any folders
        for i in folders.indices {
            folders[i].documentIds.removeAll { $0 == document.id }
        }

        saveMetadata()
        saveFolders()
    }

    func deleteDocuments(at offsets: IndexSet) {
        let toDelete = offsets.map { documents[$0] }
        for doc in toDelete {
            if let url = doc.fileURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
        documents.remove(atOffsets: offsets)
        saveMetadata()
    }

    // MARK: - Folders

    func createFolder(name: String) {
        let folder = DocumentFolder(name: name)
        folders.append(folder)
        saveFolders()
    }

    func deleteFolders(at offsets: IndexSet) {
        folders.remove(atOffsets: offsets)
        saveFolders()
    }

    // MARK: - Load PDF for viewing

    func loadPDF(for document: ScannedDocument) -> PDFDocument? {
        guard let url = document.fileURL else { return nil }
        return PDFDocument(url: url)
    }

    // MARK: - Persistence

    private func saveMetadata() {
        do {
            let data = try JSONEncoder().encode(documents)
            try data.write(to: Self.metadataURL, options: .atomic)
        } catch {
            print("DocumentStore: Failed to save metadata: \(error)")
        }
    }

    private func loadDocuments() {
        guard FileManager.default.fileExists(atPath: Self.metadataURL.path) else { return }
        do {
            let data = try Data(contentsOf: Self.metadataURL)
            documents = try JSONDecoder().decode([ScannedDocument].self, from: data)
        } catch {
            print("DocumentStore: Failed to load metadata: \(error)")
        }
    }

    private func saveFolders() {
        do {
            let data = try JSONEncoder().encode(folders)
            try data.write(to: Self.foldersURL, options: .atomic)
        } catch {
            print("DocumentStore: Failed to save folders: \(error)")
        }
    }

    private func loadFolders() {
        guard FileManager.default.fileExists(atPath: Self.foldersURL.path) else { return }
        do {
            let data = try Data(contentsOf: Self.foldersURL)
            folders = try JSONDecoder().decode([DocumentFolder].self, from: data)
        } catch {
            print("DocumentStore: Failed to load folders: \(error)")
        }
    }

    // MARK: - Thumbnail

    private func generateThumbnail(from image: UIImage) -> Data? {
        let maxSize: CGFloat = 200
        let scale = min(maxSize / image.size.width, maxSize / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return thumbnail?.jpegData(compressionQuality: 0.6)
    }
}
