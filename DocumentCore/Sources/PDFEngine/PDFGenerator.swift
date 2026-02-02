import UIKit
import PDFKit

/// Generates PDFs from images and other sources
public final class PDFGenerator {

    public init() {}

    /// Create a PDF from an array of images
    public func createPDF(from images: [UIImage]) -> PDFDocument? {
        let document = PDFDocument()

        for (index, image) in images.enumerated() {
            guard let page = createPDFPage(from: image) else { continue }
            document.insert(page, at: index)
        }

        return document.pageCount > 0 ? document : nil
    }

    /// Create a PDF page from a single image
    public func createPDFPage(from image: UIImage) -> PDFPage? {
        let pageRect = CGRect(origin: .zero, size: image.size)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            context.beginPage()
            image.draw(in: pageRect)
        }

        guard let document = PDFDocument(data: data),
              let page = document.page(at: 0) else {
            return nil
        }

        return page
    }

    /// Save PDF to file
    public func savePDF(_ document: PDFDocument, to url: URL) throws {
        guard document.write(to: url) else {
            throw PDFGeneratorError.writeFailed
        }
    }

    /// Generate PDF data
    public func generatePDFData(from images: [UIImage]) -> Data? {
        guard let document = createPDF(from: images) else { return nil }
        return document.dataRepresentation()
    }
}

public enum PDFGeneratorError: LocalizedError {
    case writeFailed
    case invalidImage

    public var errorDescription: String? {
        switch self {
        case .writeFailed: return "Failed to write PDF"
        case .invalidImage: return "Invalid image"
        }
    }
}
