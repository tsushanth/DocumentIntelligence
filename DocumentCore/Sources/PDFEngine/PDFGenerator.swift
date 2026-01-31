import UIKit
import PDFKit

/// Generates PDF documents from images and other content
public final class PDFGenerator {

    public init() {}

    /// Generate a PDF from multiple images
    public func generatePDF(from images: [UIImage], title: String? = nil, addWatermark: Bool = false) -> Data? {
        let pdfMetaData = [
            kCGPDFContextTitle: title ?? "Scanned Document",
            kCGPDFContextCreator: "DocumentCore",
            kCGPDFContextAuthor: "Document Intelligence Platform"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        // Use A4 size as default (612 x 792 points)
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            for image in images {
                context.beginPage()

                // Calculate the rect to fit the image while maintaining aspect ratio
                let imageRect = calculateFitRect(for: image.size, in: pageRect, padding: 20)
                image.draw(in: imageRect)

                if addWatermark {
                    drawWatermark(in: context.cgContext, pageRect: pageRect)
                }
            }
        }

        return data
    }

    /// Generate a PDF with custom page sizes matching image dimensions
    public func generatePDFWithOriginalSizes(from images: [UIImage], addWatermark: Bool = false) -> Data? {
        let format = UIGraphicsPDFRendererFormat()

        // Use first image size as reference, but we'll handle each page individually
        let referenceSize = images.first?.size ?? CGSize(width: 612, height: 792)
        let referenceRect = CGRect(origin: .zero, size: referenceSize)

        let renderer = UIGraphicsPDFRenderer(bounds: referenceRect, format: format)

        let data = renderer.pdfData { context in
            for image in images {
                // Scale down if image is too large (max 3000 points)
                let maxDimension: CGFloat = 3000
                var pageSize = image.size

                if pageSize.width > maxDimension || pageSize.height > maxDimension {
                    let scale = min(maxDimension / pageSize.width, maxDimension / pageSize.height)
                    pageSize = CGSize(width: pageSize.width * scale, height: pageSize.height * scale)
                }

                let pageRect = CGRect(origin: .zero, size: pageSize)

                context.beginPage(withBounds: pageRect, pageInfo: [:])
                image.draw(in: pageRect)

                if addWatermark {
                    drawWatermark(in: context.cgContext, pageRect: pageRect)
                }
            }
        }

        return data
    }

    /// Add a page to an existing PDF
    public func addPage(to existingPDF: Data, image: UIImage, addWatermark: Bool = false) -> Data? {
        guard let pdfDocument = PDFDocument(data: existingPDF) else { return nil }

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let newPageData = renderer.pdfData { context in
            context.beginPage()
            let imageRect = calculateFitRect(for: image.size, in: pageRect, padding: 20)
            image.draw(in: imageRect)

            if addWatermark {
                drawWatermark(in: context.cgContext, pageRect: pageRect)
            }
        }

        guard let newPageDocument = PDFDocument(data: newPageData),
              let newPage = newPageDocument.page(at: 0) else { return nil }

        pdfDocument.insert(newPage, at: pdfDocument.pageCount)

        return pdfDocument.dataRepresentation()
    }

    // MARK: - Private Helpers

    private func calculateFitRect(for imageSize: CGSize, in containerRect: CGRect, padding: CGFloat) -> CGRect {
        let availableWidth = containerRect.width - (padding * 2)
        let availableHeight = containerRect.height - (padding * 2)

        let widthRatio = availableWidth / imageSize.width
        let heightRatio = availableHeight / imageSize.height
        let scale = min(widthRatio, heightRatio)

        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale

        let x = (containerRect.width - scaledWidth) / 2
        let y = (containerRect.height - scaledHeight) / 2

        return CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight)
    }

    private func drawWatermark(in context: CGContext, pageRect: CGRect) {
        context.saveGState()

        let watermarkText = "Created with DocuScan AI"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.gray.withAlphaComponent(0.5)
        ]

        let textSize = (watermarkText as NSString).size(withAttributes: attributes)
        let textRect = CGRect(
            x: pageRect.width - textSize.width - 20,
            y: 20,
            width: textSize.width,
            height: textSize.height
        )

        (watermarkText as NSString).draw(in: textRect, withAttributes: attributes)

        context.restoreGState()
    }
}
