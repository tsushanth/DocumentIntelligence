import UIKit
import PDFKit

/// Service for adding and removing watermarks from PDFs
public final class WatermarkService {

    public enum WatermarkStyle {
        case text(String)
        case image(UIImage)
        case diagonal(String)
    }

    public enum WatermarkPosition {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
        case center
        case diagonal
    }

    public init() {}

    /// Add a watermark to all pages of a PDF
    public func addWatermark(
        to document: PDFDocument,
        style: WatermarkStyle,
        position: WatermarkPosition = .bottomRight,
        opacity: CGFloat = 0.3
    ) -> PDFDocument {
        let newDocument = PDFDocument()

        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }

            let watermarkedPage = addWatermarkToPage(
                page: page,
                style: style,
                position: position,
                opacity: opacity
            )

            newDocument.insert(watermarkedPage, at: pageIndex)
        }

        return newDocument
    }

    /// Add a watermark to a single page
    private func addWatermarkToPage(
        page: PDFPage,
        style: WatermarkStyle,
        position: WatermarkPosition,
        opacity: CGFloat
    ) -> PDFPage {
        let pageBounds = page.bounds(for: .mediaBox)

        // Create a new PDF page with the watermark
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            // Draw original page content
            if let cgContext = UIGraphicsGetCurrentContext() {
                cgContext.saveGState()

                // Flip context for proper rendering
                cgContext.translateBy(x: 0, y: pageBounds.height)
                cgContext.scaleBy(x: 1, y: -1)

                page.draw(with: .mediaBox, to: cgContext)

                cgContext.restoreGState()

                // Draw watermark
                cgContext.setAlpha(opacity)

                switch style {
                case .text(let text):
                    drawTextWatermark(text, in: cgContext, bounds: pageBounds, position: position)

                case .image(let image):
                    drawImageWatermark(image, in: cgContext, bounds: pageBounds, position: position)

                case .diagonal(let text):
                    drawDiagonalWatermark(text, in: cgContext, bounds: pageBounds)
                }
            }
        }

        return PDFDocument(data: data)?.page(at: 0) ?? page
    }

    private func drawTextWatermark(_ text: String, in context: CGContext, bounds: CGRect, position: WatermarkPosition) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: UIColor.gray
        ]

        let textSize = (text as NSString).size(withAttributes: attributes)
        let textRect = calculateRect(for: textSize, in: bounds, position: position, padding: 20)

        // Flip for text drawing
        context.saveGState()
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1, y: -1)

        (text as NSString).draw(in: textRect, withAttributes: attributes)

        context.restoreGState()
    }

    private func drawImageWatermark(_ image: UIImage, in context: CGContext, bounds: CGRect, position: WatermarkPosition) {
        let maxSize: CGFloat = 100
        let scale = min(maxSize / image.size.width, maxSize / image.size.height)
        let imageSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let imageRect = calculateRect(for: imageSize, in: bounds, position: position, padding: 20)

        context.saveGState()
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1, y: -1)

        image.draw(in: imageRect)

        context.restoreGState()
    }

    private func drawDiagonalWatermark(_ text: String, in context: CGContext, bounds: CGRect) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 60, weight: .bold),
            .foregroundColor: UIColor.gray.withAlphaComponent(0.2)
        ]

        let textSize = (text as NSString).size(withAttributes: attributes)

        context.saveGState()

        // Move to center and rotate
        context.translateBy(x: bounds.midX, y: bounds.midY)
        context.rotate(by: -.pi / 4) // 45 degree rotation

        // Flip for text
        context.scaleBy(x: 1, y: -1)

        let textRect = CGRect(
            x: -textSize.width / 2,
            y: -textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )

        (text as NSString).draw(in: textRect, withAttributes: attributes)

        context.restoreGState()
    }

    private func calculateRect(for size: CGSize, in bounds: CGRect, position: WatermarkPosition, padding: CGFloat) -> CGRect {
        let x: CGFloat
        let y: CGFloat

        switch position {
        case .topLeft:
            x = padding
            y = padding
        case .topRight:
            x = bounds.width - size.width - padding
            y = padding
        case .bottomLeft:
            x = padding
            y = bounds.height - size.height - padding
        case .bottomRight:
            x = bounds.width - size.width - padding
            y = bounds.height - size.height - padding
        case .center, .diagonal:
            x = (bounds.width - size.width) / 2
            y = (bounds.height - size.height) / 2
        }

        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }

    /// Remove watermark annotation (only works for annotation-based watermarks)
    public func removeWatermarkAnnotations(from document: PDFDocument) {
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }

            // Remove any stamp or watermark annotations
            let annotationsToRemove = page.annotations.filter { annotation in
                annotation.type == "Stamp" ||
                annotation.type == "Watermark" ||
                (annotation.contents?.lowercased().contains("watermark") ?? false)
            }

            for annotation in annotationsToRemove {
                page.removeAnnotation(annotation)
            }
        }
    }
}
