import SwiftUI
import PDFKit
import DocumentCore

@MainActor
class AIInsightsViewModel: ObservableObject {

    var document: ScannedDocument

    @Published var generatedTitle: String?
    @Published var summary: String?
    @Published var ocrText: String?
    @Published var extractedFields: ExtractedDocumentFields?
    @Published var question = ""
    @Published var answer: String?
    @Published var errorMessage: String?

    @Published var isGeneratingTitle = false
    @Published var isGeneratingSummary = false
    @Published var isExtractingText = false
    @Published var isExtractingFields = false
    @Published var isAskingQuestion = false

    private let textRecognizer = TextRecognizer()
    private let autoTitler = AutoTitler()
    private let documentAnalyzer = DocumentAnalyzer()

    init(document: ScannedDocument) {
        self.document = document
        // Load previously saved insights
        self.generatedTitle = document.aiTitle
        self.ocrText = document.ocrText
        self.summary = document.summary
        self.extractedFields = document.extractedFields
    }

    // MARK: - Persist to DocumentStore

    private func saveInsights() {
        DocumentStore.shared.updateDocument(document)
    }

    // MARK: - OCR Text Extraction (on-device, Apple Vision)

    func extractText() async {
        isExtractingText = true
        errorMessage = nil
        defer { isExtractingText = false }

        do {
            let text = try await performOCR()
            ocrText = text.isEmpty ? "No text detected in this document." : text
            document.ocrText = ocrText
            saveInsights()
        } catch {
            errorMessage = "OCR failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Smart Title (OCR → GCP backend)

    func generateTitle() async {
        isGeneratingTitle = true
        errorMessage = nil
        defer { isGeneratingTitle = false }

        do {
            let text = try await getOCRText()
            let title = try await autoTitler.generateTitle(from: text)
            generatedTitle = title
            document.aiTitle = title
            saveInsights()
        } catch {
            errorMessage = "Title generation failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Summary (OCR → GCP backend)

    func generateSummary() async {
        isGeneratingSummary = true
        errorMessage = nil
        defer { isGeneratingSummary = false }

        do {
            let text = try await getOCRText()
            let result = try await documentAnalyzer.summarize(text: text)
            summary = result
            document.summary = result
            saveInsights()
        } catch {
            errorMessage = "Summary failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Field Extraction (OCR → GCP backend)

    func extractFields() async {
        isExtractingFields = true
        errorMessage = nil
        defer { isExtractingFields = false }

        do {
            let text = try await getOCRText()
            let result = try await AIService.shared.analyzeDocument(text: text, task: .extract)

            // Parse the JSON response — all string values to avoid Date decoding issues
            if let data = result.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

                let date = json["date"] as? String
                let vendor = (json["vendorName"] as? String)
                    ?? (json["vendor"] as? String)
                    ?? (json["vendor_name"] as? String)
                    ?? (json["merchant"] as? String)
                    ?? (json["merchantName"] as? String)

                var amountStr: String? = nil
                if let amt = json["totalAmount"] as? Double ?? json["total_amount"] as? Double ?? json["amount"] as? Double ?? json["total"] as? Double {
                    let currency = (json["currency"] as? String) ?? "USD"
                    amountStr = currency == "USD" ? "$\(String(format: "%.2f", amt))" : "\(String(format: "%.2f", amt)) \(currency)"
                } else if let amt = json["totalAmount"] as? String ?? json["amount"] as? String ?? json["total"] as? String {
                    amountStr = amt
                }

                let invoiceNum = (json["invoiceNumber"] as? String)
                    ?? (json["invoice_number"] as? String)
                    ?? (json["referenceNumber"] as? String)

                let fields = ExtractedDocumentFields(
                    date: date,
                    vendor: vendor,
                    amount: amountStr,
                    invoiceNumber: invoiceNum
                )
                extractedFields = fields
                document.extractedFields = fields
                saveInsights()
            } else {
                // Fallback: show raw result as vendor field
                let fields = ExtractedDocumentFields(
                    date: nil,
                    vendor: result,
                    amount: nil,
                    invoiceNumber: nil
                )
                extractedFields = fields
                document.extractedFields = fields
                saveInsights()
            }
        } catch {
            errorMessage = "Field extraction failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Ask AI (OCR → GCP backend)

    func askQuestion() async {
        guard !question.isEmpty else { return }

        isAskingQuestion = true
        errorMessage = nil
        defer { isAskingQuestion = false }

        let currentQuestion = question
        question = ""

        do {
            let text = try await getOCRText()
            let result = try await documentAnalyzer.answerQuestion(text: text, question: currentQuestion)
            answer = result
        } catch {
            errorMessage = "Question failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Helpers

    /// Returns cached OCR text or runs OCR first
    private func getOCRText() async throws -> String {
        if let existing = ocrText, !existing.isEmpty, existing != "No text detected in this document." {
            return existing
        }

        let text = try await performOCR()
        ocrText = text
        document.ocrText = text
        saveInsights()
        return text
    }

    /// Runs OCR on all pages of the stored PDF
    private func performOCR() async throws -> String {
        guard let fileURL = document.fileURL,
              let pdfDocument = PDFDocument(url: fileURL) else {
            throw TextRecognizerError.invalidImage
        }

        var allText: [String] = []
        let pageCount = min(pdfDocument.pageCount, 20) // cap at 20 pages

        for i in 0..<pageCount {
            guard let page = pdfDocument.page(at: i),
                  let cgPage = page.pageRef else { continue }

            let recognized = try await textRecognizer.recognizeText(in: cgPage, level: .accurate)
            if !recognized.fullText.isEmpty {
                allText.append(recognized.fullText)
            }
        }

        return allText.joined(separator: "\n\n")
    }
}

struct ExtractedDocumentFields: Codable {
    let date: String?
    let vendor: String?
    let amount: String?
    let invoiceNumber: String?
}
