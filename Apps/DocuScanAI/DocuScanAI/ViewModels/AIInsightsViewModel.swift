import SwiftUI

@MainActor
class AIInsightsViewModel: ObservableObject {
    
    let document: ScannedDocument
    
    @Published var generatedTitle: String?
    @Published var summary: String?
    @Published var ocrText: String?
    @Published var extractedFields: ExtractedDocumentFields?
    @Published var question = ""
    @Published var answer: String?
    
    @Published var isGeneratingTitle = false
    @Published var isGeneratingSummary = false
    @Published var isExtractingText = false
    @Published var isExtractingFields = false
    @Published var isAskingQuestion = false
    
    init(document: ScannedDocument) {
        self.document = document
    }
    
    func generateTitle() async {
        isGeneratingTitle = true
        defer { isGeneratingTitle = false }
        
        // Will integrate with AutoTitler
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        generatedTitle = "Electric Bill - January 2026"
    }
    
    func generateSummary() async {
        isGeneratingSummary = true
        defer { isGeneratingSummary = false }
        
        // Will integrate with DocumentAnalyzer
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        summary = "This is an electricity bill from Pacific Gas & Electric for January 2026. The total amount due is $142.87 with a due date of February 15, 2026."
    }
    
    func extractText() async {
        isExtractingText = true
        defer { isExtractingText = false }
        
        // Will integrate with TextRecognizer
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        ocrText = "Pacific Gas & Electric\nAccount: 1234567890\nService Address: 123 Main St..."
    }
    
    func extractFields() async {
        isExtractingFields = true
        defer { isExtractingFields = false }
        
        // Will integrate with FieldExtractor
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        extractedFields = ExtractedDocumentFields(
            date: "January 15, 2026",
            vendor: "Pacific Gas & Electric",
            amount: "$142.87",
            invoiceNumber: "INV-2026-001"
        )
    }
    
    func askQuestion() async {
        guard !question.isEmpty else { return }
        
        isAskingQuestion = true
        defer { isAskingQuestion = false }
        
        let currentQuestion = question
        question = ""
        
        // Will integrate with DocumentAnalyzer
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        answer = "Based on the document, the due date is February 15, 2026 and the total amount is $142.87."
    }
}

struct ExtractedDocumentFields {
    let date: String?
    let vendor: String?
    let amount: String?
    let invoiceNumber: String?
}
