import UIKit
import PDFKit

/// PDF editing capabilities including annotations and signatures
public final class PDFEditor {
    
    public init() {}
    
    /// Add highlight annotation to page
    public func addHighlight(to page: PDFPage, bounds: CGRect, color: UIColor = .yellow) {
        let annotation = PDFAnnotation(bounds: bounds, forType: .highlight, withProperties: nil)
        annotation.color = color.withAlphaComponent(0.5)
        page.addAnnotation(annotation)
    }
    
    /// Add underline annotation to page
    public func addUnderline(to page: PDFPage, bounds: CGRect, color: UIColor = .red) {
        let annotation = PDFAnnotation(bounds: bounds, forType: .underline, withProperties: nil)
        annotation.color = color
        page.addAnnotation(annotation)
    }
    
    /// Add text annotation to page
    public func addText(_ text: String, to page: PDFPage, at point: CGPoint, fontSize: CGFloat = 12, color: UIColor = .black) {
        let bounds = CGRect(x: point.x, y: point.y, width: 300, height: 50)
        let annotation = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
        annotation.contents = text
        annotation.font = UIFont.systemFont(ofSize: fontSize)
        annotation.fontColor = color
        annotation.color = .clear
        page.addAnnotation(annotation)
    }
    
    /// Add signature image to page
    public func addSignature(_ image: UIImage, to page: PDFPage, at rect: CGRect) {
        let annotation = ImageAnnotation(bounds: rect, image: image)
        page.addAnnotation(annotation)
    }
    
    /// Add drawing/ink annotation
    public func addDrawing(path: UIBezierPath, to page: PDFPage, color: UIColor = .black, lineWidth: CGFloat = 2) {
        let annotation = PDFAnnotation(bounds: path.bounds, forType: .ink, withProperties: nil)
        annotation.color = color
        annotation.border = PDFBorder()
        annotation.border?.lineWidth = lineWidth
        page.addAnnotation(annotation)
    }
    
    /// Remove annotation from page
    public func removeAnnotation(_ annotation: PDFAnnotation, from page: PDFPage) {
        page.removeAnnotation(annotation)
    }
    
    /// Remove all annotations from page
    public func removeAllAnnotations(from page: PDFPage) {
        for annotation in page.annotations {
            page.removeAnnotation(annotation)
        }
    }
    
    /// Flatten annotations into PDF content
    public func flattenAnnotations(in document: PDFDocument) -> PDFDocument? {
        guard let data = document.dataRepresentation(),
              let flattened = PDFDocument(data: data) else { return nil }
        return flattened
    }
}

/// Custom annotation for displaying images (signatures, stamps)
public class ImageAnnotation: PDFAnnotation {
    
    private var image: UIImage?
    
    public init(bounds: CGRect, image: UIImage) {
        self.image = image
        super.init(bounds: bounds, forType: .stamp, withProperties: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(with box: PDFDisplayBox, in context: CGContext) {
        guard let image = image, let cgImage = image.cgImage else { return }
        
        context.saveGState()
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1, y: -1)
        context.draw(cgImage, in: CGRect(origin: .zero, size: bounds.size))
        context.restoreGState()
    }
}
