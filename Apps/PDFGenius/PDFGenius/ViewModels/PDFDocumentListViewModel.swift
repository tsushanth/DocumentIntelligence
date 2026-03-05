import SwiftUI
import PDFKit

@MainActor
class PDFDocumentListViewModel: ObservableObject {
    
    @Published var documents: [PDFDocumentItem] = []
    @Published var isLoading = false
    
    init() {
        loadDocuments()
    }
    
    func loadDocuments() {
        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pdfDir = docsDir.appendingPathComponent("PDFs", isDirectory: true)

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: pdfDir, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey],
            options: .skipsHiddenFiles
        ) else { return }

        let pdfFiles = files.filter { $0.pathExtension.lowercased() == "pdf" }
        var items: [PDFDocumentItem] = []

        for url in pdfFiles {
            guard let doc = PDFDocument(url: url) else { continue }
            let values = try? url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
            items.append(PDFDocumentItem(
                title: url.deletingPathExtension().lastPathComponent,
                fileURL: url,
                pageCount: doc.pageCount,
                fileSize: Int64(values?.fileSize ?? 0),
                createdAt: values?.creationDate ?? Date()
            ))
        }

        documents = items.sorted { $0.createdAt > $1.createdAt }
    }
    
    func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                importPDF(from: url)
            }
        case .failure(let error):
            print("Import failed: \(error)")
        }
    }
    
    func importPDF(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let document = PDFDocument(url: url) else { return }

        // Copy to app Documents so the file remains accessible after security scope ends
        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pdfDir = docsDir.appendingPathComponent("PDFs", isDirectory: true)
        try? FileManager.default.createDirectory(at: pdfDir, withIntermediateDirectories: true)

        let fileName = url.lastPathComponent
        var destURL = pdfDir.appendingPathComponent(fileName)

        // Avoid overwriting — append UUID if file exists
        if FileManager.default.fileExists(atPath: destURL.path) {
            let name = url.deletingPathExtension().lastPathComponent
            let ext = url.pathExtension
            destURL = pdfDir.appendingPathComponent("\(name)_\(UUID().uuidString.prefix(6)).\(ext)")
        }

        do {
            try FileManager.default.copyItem(at: url, to: destURL)
        } catch {
            print("[PDFDocumentListVM] Failed to copy PDF: \(error)")
            return
        }

        let item = PDFDocumentItem(
            title: url.deletingPathExtension().lastPathComponent,
            fileURL: destURL,
            pageCount: document.pageCount,
            fileSize: getFileSize(destURL)
        )

        documents.append(item)
    }
    
    func deleteDocuments(at offsets: IndexSet) {
        documents.remove(atOffsets: offsets)
    }
    
    private func getFileSize(_ url: URL) -> Int64 {
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
    }
}
