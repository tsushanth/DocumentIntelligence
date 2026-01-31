import UIKit
import PDFKit

/// Provides PDF editing capabilities including annotations and signatures
public final class PDFEditor {

    public init() {}

    // MARK: - Annotations

    /// Add a text annotation to a PDF page
    public func addTextAnnotation(
        to page: PDFPage,
        text: String,
        at point: CGPoint,
        color: UIColor = .yellow,
        fontSize: CGFloat = 14
    ) {
        let bounds = CGRect(x: point.x, y: point.y, width: 200, height: 50)
        let annotation = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
        annotation.contents = text
        annotation.color = color
        annotation.font = UIFont.systemFont(ofSize: fontSize)
        annotation.fontColor = .black
        page.addAnnotation(annotation)
    }

    /// Add a highlight annotation to a PDF page
    public func addHighlightAnnotation(
        to page: PDFPage,
        bounds: CGRect,
        color: UIColor = .yellow
    ) {
        let annotation = PDFAnnotation(bounds: bounds, forType: .highlight, withProperties: nil)
        annotation.color = color.withAlphaComponent(0.3)
        page.addAnnotation(annotation)
    }

    /// Add an underline annotation to a PDF page
    public func addUnderlineAnnotation(
        to page: PDFPage,
        bounds: CGRect,
        color: UIColor = .red
    ) {
        let annotation = PDFAnnotation(bounds: bounds, forType: .underline, withProperties: nil)
        annotation.color = color
        page.addAnnotation(annotation)
    }

    /// Add a strikethrough annotation to a PDF page
    public func addStrikethroughAnnotation(
        to page: PDFPage,
        bounds: CGRect,
        color: UIColor = .red
    ) {
        let annotation = PDFAnnotation(bounds: bounds, forType: .strikeOut, withProperties: nil)
        annotation.color = color
        page.addAnnotation(annotation)
    }

    /// Add a drawing/ink annotation to a PDF page
    public func addInkAnnotation(
        to page: PDFPage,
        paths: [UIBezierPath],
        color: UIColor = .black,
        lineWidth: CGFloat = 2.0
    ) {
        // Calculate bounds from all paths
        var combinedBounds = CGRect.null
        for path in paths {
            combinedBounds = combinedBounds.union(path.bounds)
        }

        let annotation = PDFAnnotation(bounds: combinedBounds.insetBy(dx: -lineWidth, dy: -lineWidth), forType: .ink, withProperties: nil)
        annotation.color = color

        // Convert UIBezierPath to CGPath for the annotation
        var annotationPaths: [[CGPoint]] = []
        for path in paths {
            let points = extractPoints(from: path)
            if !points.isEmpty {
                annotationPaths.append(points)
            }
        }

        annotation.setValue(annotationPaths, forAnnotationKey: .inkList)

        page.addAnnotation(annotation)
    }

    // MARK: - Signature

    /// Add a signature image to a PDF page
    public func addSignature(
        to page: PDFPage,
        signatureImage: UIImage,
        at rect: CGRect
    ) {
        let annotation = PDFAnnotation(bounds: rect, forType: .stamp, withProperties: nil)

        // Create a PDFPage from the signature image and use it as stamp
        if let cgImage = signatureImage.cgImage {
            let stampAppearance = createStampAppearance(from: cgImage, bounds: rect)
            annotation.setValue(stampAppearance, forAnnotationKey: .appearance)
        }

        page.addAnnotation(annotation)
    }

    /// Add a signature from drawing paths
    public func addSignatureFromDrawing(
        to page: PDFPage,
        paths: [UIBezierPath],
        at rect: CGRect,
        color: UIColor = .black
    ) {
        // Render the signature to an image first
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        let signatureImage = renderer.image { context in
            color.setStroke()

            // Scale paths to fit the rect
            let originalBounds = paths.reduce(CGRect.null) { $0.union($1.bounds) }
            let scaleX = rect.width / originalBounds.width
            let scaleY = rect.height / originalBounds.height
            let scale = min(scaleX, scaleY) * 0.9 // 90% to add padding

            context.cgContext.translateBy(
                x: (rect.width - originalBounds.width * scale) / 2,
                y: (rect.height - originalBounds.height * scale) / 2
            )
            context.cgContext.scaleBy(x: scale, y: scale)
            context.cgContext.translateBy(x: -originalBounds.minX, y: -originalBounds.minY)

            for path in paths {
                path.lineWidth = 2.0
                path.stroke()
            }
        }

        addSignature(to: page, signatureImage: signatureImage, at: rect)
    }

    // MARK: - Remove Annotations

    /// Remove all annotations from a page
    public func removeAllAnnotations(from page: PDFPage) {
        for annotation in page.annotations {
            page.removeAnnotation(annotation)
        }
    }

    /// Remove a specific annotation
    public func removeAnnotation(_ annotation: PDFAnnotation, from page: PDFPage) {
        page.removeAnnotation(annotation)
    }

    // MARK: - Form Fields

    /// Fill a text form field
    public func fillTextField(
        annotation: PDFAnnotation,
        with text: String
    ) {
        guard annotation.type == "Widget",
              let fieldType = annotation.fieldName else { return }

        annotation.setValue(text, forAnnotationKey: .widgetValue)
    }

    /// Get all form fields in a document
    public func getFormFields(in document: PDFDocument) -> [PDFAnnotation] {
        var fields: [PDFAnnotation] = []

        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }

            for annotation in page.annotations {
                if annotation.type == "Widget" {
                    fields.append(annotation)
                }
            }
        }

        return fields
    }

    // MARK: - Private Helpers

    private func extractPoints(from path: UIBezierPath) -> [CGPoint] {
        var points: [CGPoint] = []
        let cgPath = path.cgPath

        cgPath.applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint, .addLineToPoint:
                points.append(element.pointee.points[0])
            case .addQuadCurveToPoint:
                points.append(element.pointee.points[0])
                points.append(element.pointee.points[1])
            case .addCurveToPoint:
                points.append(element.pointee.points[0])
                points.append(element.pointee.points[1])
                points.append(element.pointee.points[2])
            case .closeSubpath:
                break
            @unknown default:
                break
            }
        }

        return points
    }

    private func createStampAppearance(from cgImage: CGImage, bounds: CGRect) -> PDFPage? {
        let image = UIImage(cgImage: cgImage)
        return PDFPage(image: image)
    }
}
