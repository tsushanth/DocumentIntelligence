import SwiftUI
import PDFKit

/// SwiftUI wrapper for PDFKit viewer
public struct PDFViewer: UIViewRepresentable {
    
    let document: PDFDocument?
    let displayMode: PDFDisplayMode
    let autoScales: Bool
    
    public init(
        document: PDFDocument?,
        displayMode: PDFDisplayMode = .singlePageContinuous,
        autoScales: Bool = true
    ) {
        self.document = document
        self.displayMode = displayMode
        self.autoScales = autoScales
    }
    
    public func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.displayMode = displayMode
        pdfView.autoScales = autoScales
        pdfView.displayDirection = .vertical
        pdfView.document = document
        return pdfView
    }
    
    public func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = document
    }
}

/// PDFView with editing capabilities
public struct EditablePDFView: UIViewRepresentable {
    
    @Binding var document: PDFDocument?
    let onPageChange: ((Int) -> Void)?
    
    public init(document: Binding<PDFDocument?>, onPageChange: ((Int) -> Void)? = nil) {
        self._document = document
        self.onPageChange = onPageChange
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
        pdfView.document = document
        
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )
        
        return pdfView
    }
    
    public func updateUIView(_ pdfView: PDFView, context: Context) {
        if pdfView.document !== document {
            pdfView.document = document
        }
    }
    
    public class Coordinator: NSObject {
        var parent: EditablePDFView
        
        init(_ parent: EditablePDFView) {
            self.parent = parent
        }
        
        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let pageIndex = pdfView.document?.index(for: currentPage) else { return }
            parent.onPageChange?(pageIndex)
        }
    }
}
