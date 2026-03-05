import SwiftUI
import PDFKit
import DocumentCore

@MainActor
class PDFEditorViewModel: ObservableObject {

    let document: PDFDocumentItem
    @Published var pdfDocument: PDFDocument?
    @Published var currentPage: Int = 0
    @Published var canUndo = false
    @Published var canRedo = false
    @Published var aiSummary: String?
    @Published var extractedText: String?
    @Published var loadError: String?
    @Published var isSaving = false

    private var undoStack: [[PDFAnnotation]] = []
    private var redoStack: [[PDFAnnotation]] = []

    init(document: PDFDocumentItem) {
        self.document = document
        loadDocument()
    }

    func loadDocument() {
        guard let url = document.fileURL else {
            loadError = "No file URL available"
            return
        }
        if let doc = PDFDocument(url: url) {
            pdfDocument = doc
        } else {
            print("[PDFEditorVM] Failed to load PDF at: \(url.path)")
            loadError = "Unable to open this PDF"
        }
    }

    // MARK: - Text Extraction

    /// Extract all text from the PDF using PDFKit
    func extractAllText() -> String {
        guard let doc = pdfDocument else { return "" }
        var allText = ""
        for i in 0..<doc.pageCount {
            if let page = doc.page(at: i), let text = page.string {
                allText += text + "\n\n"
            }
        }
        // Limit to ~8000 chars to stay within API limits
        if allText.count > 8000 {
            allText = String(allText.prefix(8000))
        }
        return allText
    }

    // MARK: - Editing

    func addHighlight(at bounds: CGRect, on page: PDFPage) {
        let annotation = PDFAnnotation(bounds: bounds, forType: .highlight, withProperties: nil)
        annotation.color = .yellow.withAlphaComponent(0.5)
        page.addAnnotation(annotation)
        saveUndoState()
    }

    func addUnderline(at bounds: CGRect, on page: PDFPage) {
        let annotation = PDFAnnotation(bounds: bounds, forType: .underline, withProperties: nil)
        annotation.color = .red
        page.addAnnotation(annotation)
        saveUndoState()
    }

    func addText(_ text: String, at point: CGPoint, on page: PDFPage) {
        let bounds = CGRect(x: point.x, y: point.y, width: 200, height: 50)
        let annotation = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
        annotation.contents = text
        annotation.font = UIFont.systemFont(ofSize: 14)
        page.addAnnotation(annotation)
        saveUndoState()
    }

    func addSignature(_ image: UIImage) {
        guard let page = pdfDocument?.page(at: currentPage) else { return }

        let pageBounds = page.bounds(for: .mediaBox)
        let signatureSize = CGSize(width: 150, height: 50)
        let signatureBounds = CGRect(
            x: (pageBounds.width - signatureSize.width) / 2,
            y: (pageBounds.height - signatureSize.height) / 2,
            width: signatureSize.width,
            height: signatureSize.height
        )

        let annotation = ImageStampAnnotation(image: image, bounds: signatureBounds)
        page.addAnnotation(annotation)
        saveUndoState()
    }

    // MARK: - Undo/Redo

    private func saveUndoState() {
        canUndo = true
        redoStack.removeAll()
        canRedo = false
    }

    func undo() {
        canRedo = true
    }

    func redo() {
        // Implement redo
    }

    // MARK: - File Operations

    func savePDF() {
        guard let doc = pdfDocument, let url = document.fileURL else { return }
        doc.write(to: url)
    }

    func sharePDF() -> URL? {
        // Save first, then return URL for sharing
        savePDF()
        return document.fileURL
    }

    // MARK: - AI Features

    func generateSummary() async {
        let text = extractAllText()
        guard !text.isEmpty else {
            aiSummary = "Could not extract text from this PDF."
            return
        }

        do {
            let result = try await AIService.shared.analyzeDocument(text: text, task: .summarize)
            aiSummary = result
        } catch {
            print("[PDFEditorVM] AI summary error: \(error)")
            aiSummary = "Failed to generate summary: \(error.localizedDescription)"
        }
    }

    func extractText() async {
        let text = extractAllText()
        if text.isEmpty {
            extractedText = "No text could be extracted from this PDF."
        } else {
            extractedText = text
        }
    }

    func analyzeContract() async -> ContractAnalysisResult? {
        let text = extractAllText()
        guard !text.isEmpty else { return nil }

        do {
            let messages = [
                ChatMessage(role: .system, content: """
                    Analyze this contract. Return a JSON object with:
                    {"parties": ["name1", "name2"], "keyClauses": ["clause1", "clause2"], "risks": ["risk1", "risk2"]}
                    Only include information actually found in the document.
                    """),
                ChatMessage(role: .user, content: text)
            ]
            let response = try await AIService.shared.chatCompletion(messages: messages, temperature: 0.3)

            if let data = response.data(using: .utf8),
               let json = try? JSONDecoder().decode(ContractAnalysisResult.self, from: data) {
                return json
            }
            // If JSON parsing fails, return a simple result
            return ContractAnalysisResult(
                parties: [],
                keyClauses: [response],
                risks: []
            )
        } catch {
            print("[PDFEditorVM] Contract analysis error: \(error)")
            return nil
        }
    }

    func askQuestion(_ question: String) async -> String {
        let text = extractAllText()
        guard !text.isEmpty else {
            return "Could not extract text from this PDF to answer your question."
        }

        do {
            return try await AIService.shared.askQuestion(document: text, question: question)
        } catch {
            print("[PDFEditorVM] Ask question error: \(error)")
            return "Failed to get answer: \(error.localizedDescription)"
        }
    }
}

// MARK: - Image Stamp Annotation

class ImageStampAnnotation: PDFAnnotation {
    private let stampImage: UIImage

    init(image: UIImage, bounds: CGRect) {
        self.stampImage = image
        super.init(bounds: bounds, forType: .stamp, withProperties: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        guard let cgImage = stampImage.cgImage else { return }
        context.saveGState()
        context.draw(cgImage, in: bounds)
        context.restoreGState()
    }
}

// MARK: - Contract Analysis Result

struct ContractAnalysisResult: Codable {
    let parties: [String]
    let keyClauses: [String]
    let risks: [String]
}
