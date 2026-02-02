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
        // Will integrate with DocumentStore
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
        
        let item = PDFDocumentItem(
            title: url.deletingPathExtension().lastPathComponent,
            fileURL: url,
            pageCount: document.pageCount,
            fileSize: getFileSize(url)
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
