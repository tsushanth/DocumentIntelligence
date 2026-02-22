import Foundation
import CoreData
import Combine

/// Main document storage service using Core Data
public final class DocumentStore: ObservableObject {

    public static let shared = DocumentStore()

    @Published public private(set) var documents: [DocumentEntity] = []
    @Published public private(set) var folders: [FolderEntity] = []

    private let persistentContainer: NSPersistentContainer

    public init() {
        persistentContainer = NSPersistentContainer(name: "DocumentCore")

        // Configure for in-memory store if needed (for testing)
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            persistentContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        #endif

        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }

        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        fetchDocuments()
        fetchFolders()
    }

    // MARK: - Context

    public var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    private func newBackgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }

    // MARK: - Document Operations

    /// Create a new document
    public func createDocument(
        title: String,
        fileURL: URL,
        type: DocumentType,
        folder: FolderEntity? = nil
    ) throws -> DocumentEntity {
        let context = viewContext

        let document = DocumentEntity(context: context)
        document.id = UUID()
        document.title = title
        document.fileURL = fileURL
        document.type = type.rawValue
        document.createdAt = Date()
        document.updatedAt = Date()
        document.folder = folder

        try context.save()
        fetchDocuments()

        return document
    }

    /// Update a document
    public func updateDocument(_ document: DocumentEntity) throws {
        document.updatedAt = Date()
        try viewContext.save()
        fetchDocuments()
    }

    /// Delete a document
    public func deleteDocument(_ document: DocumentEntity) throws {
        viewContext.delete(document)
        try viewContext.save()
        fetchDocuments()

        // Delete associated file
        if let fileURL = document.fileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    /// Fetch all documents
    private func fetchDocuments() {
        let request: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DocumentEntity.updatedAt, ascending: false)]

        do {
            documents = try viewContext.fetch(request)
        } catch {
            print("Failed to fetch documents: \(error)")
            documents = []
        }
    }

    /// Search documents by title or OCR text
    public func searchDocuments(query: String) -> [DocumentEntity] {
        let request: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()

        let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
        let ocrPredicate = NSPredicate(format: "ocrText CONTAINS[cd] %@", query)
        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, ocrPredicate])

        request.sortDescriptors = [NSSortDescriptor(keyPath: \DocumentEntity.updatedAt, ascending: false)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to search documents: \(error)")
            return []
        }
    }

    // MARK: - Folder Operations

    /// Create a new folder
    public func createFolder(name: String, color: String? = nil) throws -> FolderEntity {
        let context = viewContext

        let folder = FolderEntity(context: context)
        folder.id = UUID()
        folder.name = name
        folder.color = color
        folder.createdAt = Date()

        try context.save()
        fetchFolders()

        return folder
    }

    /// Update a folder
    public func updateFolder(_ folder: FolderEntity) throws {
        try viewContext.save()
        fetchFolders()
    }

    /// Delete a folder
    public func deleteFolder(_ folder: FolderEntity) throws {
        viewContext.delete(folder)
        try viewContext.save()
        fetchFolders()
    }

    /// Fetch all folders
    private func fetchFolders() {
        let request: NSFetchRequest<FolderEntity> = FolderEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FolderEntity.name, ascending: true)]

        do {
            folders = try viewContext.fetch(request)
        } catch {
            print("Failed to fetch folders: \(error)")
            folders = []
        }
    }

    /// Move document to folder
    public func moveDocument(_ document: DocumentEntity, to folder: FolderEntity?) throws {
        document.folder = folder
        try viewContext.save()
        fetchDocuments()
    }

    // MARK: - File Management

    /// Get documents directory URL
    public var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Documents", isDirectory: true)
    }

    /// Save file to documents directory
    public func saveFile(data: Data, filename: String) throws -> URL {
        let directoryURL = documentsDirectory

        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        let fileURL = directoryURL.appendingPathComponent(filename)
        try data.write(to: fileURL)

        return fileURL
    }

    /// Export document
    public func exportDocument(_ document: DocumentEntity) throws -> URL {
        guard let fileURL = document.fileURL else {
            throw DocumentStoreError.fileNotFound
        }

        return fileURL
    }
}

/// Document types
public enum DocumentType: String, Codable {
    case pdf = "pdf"
    case scan = "scan"
    case invoice = "invoice"
    case receipt = "receipt"
    case contract = "contract"
    case other = "other"

    public var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .scan: return "Scan"
        case .invoice: return "Invoice"
        case .receipt: return "Receipt"
        case .contract: return "Contract"
        case .other: return "Other"
        }
    }
}

/// Errors that can occur in DocumentStore
public enum DocumentStoreError: LocalizedError {
    case fileNotFound
    case saveFailed
    case deleteFailed

    public var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "File not found"
        case .saveFailed:
            return "Failed to save document"
        case .deleteFailed:
            return "Failed to delete document"
        }
    }
}
