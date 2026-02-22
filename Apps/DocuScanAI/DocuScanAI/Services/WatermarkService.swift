import PDFKit
import UIKit

/// Service to add watermarks to PDF documents for free tier users
class WatermarkService {
    static let shared = WatermarkService()

    private init() {}

    /// Adds a watermark to each page of a PDF document
    /// - Parameters:
    ///   - document: The PDF document to watermark
    ///   - text: The watermark text (default: "DocuScan AI - Free Version")
    /// - Returns: A new URL to the watermarked PDF, or nil if watermarking failed
    func addWatermark(to url: URL, text: String = "DocuScan AI - Free Version") -> URL? {
        guard let pdfDocument = PDFDocument(url: url) else {
            return nil
        }

        // Create a temporary file for the watermarked PDF
        let tempDir = FileManager.default.temporaryDirectory
        let watermarkedURL = tempDir.appendingPathComponent("watermarked_\(UUID().uuidString).pdf")

        // Create new PDF with watermarks
        let watermarkedPDF = PDFDocument()

        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }

            // Create watermarked page image
            if let watermarkedImage = createWatermarkedPageImage(page: page, watermarkText: text),
               let watermarkedPage = PDFPage(image: watermarkedImage) {
                watermarkedPDF.insert(watermarkedPage, at: pageIndex)
            } else {
                // If watermarking fails, use original page
                watermarkedPDF.insert(page, at: pageIndex)
            }
        }

        // Write watermarked PDF to file
        if watermarkedPDF.write(to: watermarkedURL) {
            return watermarkedURL
        }

        return nil
    }

    private func createWatermarkedPageImage(page: PDFPage, watermarkText: String) -> UIImage? {
        let pageRect = page.bounds(for: .mediaBox)
        let scale: CGFloat = 2.0 // Higher resolution
        let scaledSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

        let renderer = UIGraphicsImageRenderer(size: scaledSize)

        return renderer.image { context in
            // Draw white background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: scaledSize))

            // Draw the original page
            context.cgContext.saveGState()
            context.cgContext.translateBy(x: 0, y: scaledSize.height)
            context.cgContext.scaleBy(x: scale, y: -scale)
            page.draw(with: .mediaBox, to: context.cgContext)
            context.cgContext.restoreGState()

            // Draw watermark
            drawWatermark(in: context.cgContext, size: scaledSize, text: watermarkText)
        }
    }

    private func drawWatermark(in context: CGContext, size: CGSize, text: String) {
        context.saveGState()

        // Set watermark style - semi-transparent diagonal text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: size.width * 0.04),
            .foregroundColor: UIColor.gray.withAlphaComponent(0.25),
            .paragraphStyle: paragraphStyle
        ]

        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()

        // Rotate and position for diagonal watermark
        context.translateBy(x: size.width / 2, y: size.height / 2)
        context.rotate(by: -.pi / 4) // 45 degree rotation

        // Draw multiple watermarks across the page
        let spacing: CGFloat = textSize.height * 3

        for row in stride(from: -size.height, to: size.height, by: spacing) {
            for col in stride(from: -size.width, to: size.width, by: textSize.width * 1.5) {
                attributedString.draw(at: CGPoint(x: col - textSize.width / 2, y: row - textSize.height / 2))
            }
        }

        context.restoreGState()

        // Also draw a footer watermark
        drawFooterWatermark(in: context, size: size, text: text)
    }

    private func drawFooterWatermark(in context: CGContext, size: CGSize, text: String) {
        context.saveGState()

        let footerText = "Created with DocuScan AI - Upgrade to Pro to remove watermark"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size.width * 0.02),
            .foregroundColor: UIColor.gray.withAlphaComponent(0.7)
        ]

        let attributedString = NSAttributedString(string: footerText, attributes: attributes)
        let textSize = attributedString.size()

        // Position at bottom center
        let point = CGPoint(
            x: (size.width - textSize.width) / 2,
            y: size.height - textSize.height - 20
        )

        // Draw background for footer
        let bgRect = CGRect(
            x: point.x - 10,
            y: point.y - 5,
            width: textSize.width + 20,
            height: textSize.height + 10
        )
        UIColor.white.withAlphaComponent(0.9).setFill()
        context.fill(bgRect)

        attributedString.draw(at: point)

        context.restoreGState()
    }

    /// Cleans up temporary watermarked files older than 1 hour
    func cleanupTemporaryFiles() {
        let tempDir = FileManager.default.temporaryDirectory
        let fileManager = FileManager.default

        guard let files = try? fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }

        let oneHourAgo = Date().addingTimeInterval(-3600)

        for file in files where file.lastPathComponent.hasPrefix("watermarked_") {
            if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
               let creationDate = attributes[.creationDate] as? Date,
               creationDate < oneHourAgo {
                try? fileManager.removeItem(at: file)
            }
        }
    }
}
