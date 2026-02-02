import SwiftUI
import PDFKit

@MainActor
class DocumentDetailViewModel: ObservableObject {
    
    let document: ScannedDocument
    @Published var pdfDocument: PDFDocument?
    @Published var isLoading = false
    @Published var ocrText: String?
    @Published var aiSummary: String?
    
    init(document: ScannedDocument) {
        self.document = document
        loadDocument()
    }
    
    func loadDocument() {
        isLoading = true
        // Load PDF from storage
        // Will integrate with DocumentStore
        isLoading = false
    }
    
    func renameDocument() {
        // Show rename dialog
    }
    
    func deleteDocument() {
        // Delete from storage
    }
    
    func extractText() async {
        // Use OCR to extract text
        // Will integrate with TextRecognizer
    }
    
    func generateSummary() async {
        // Use AI to generate summary
        // Will integrate with DocumentAnalyzer
    }
}
