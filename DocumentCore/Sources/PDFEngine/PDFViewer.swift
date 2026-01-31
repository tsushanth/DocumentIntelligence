import SwiftUI
import PDFKit

/// SwiftUI wrapper for PDFView
public struct PDFViewer: UIViewRepresentable {
    let document: PDFDocument?
    let displayMode: PDFDisplayMode
    let autoScales: Bool
    let backgroundColor: UIColor

    @Binding var currentPage: Int

    public init(
        document: PDFDocument?,
        displayMode: PDFDisplayMode = .singlePageContinuous,
        autoScales: Bool = true,
        backgroundColor: UIColor = .systemBackground,
        currentPage: Binding<Int> = .constant(0)
    ) {
        self.document = document
        self.displayMode = displayMode
        self.autoScales = autoScales
        self.backgroundColor = backgroundColor
        self._currentPage = currentPage
    }

    public func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.displayMode = displayMode
        pdfView.autoScales = autoScales
        pdfView.backgroundColor = backgroundColor
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true, withViewOptions: nil)

        // Enable gestures
        pdfView.isUserInteractionEnabled = true

        // Set up page change notification
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

        // Navigate to specific page if changed externally
        if let document = document,
           currentPage < document.pageCount,
           let page = document.page(at: currentPage),
           pdfView.currentPage !== page {
            pdfView.go(to: page)
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject {
        var parent: PDFViewer

        init(_ parent: PDFViewer) {
            self.parent = parent
        }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let document = pdfView.document,
                  let pageIndex = document.index(for: currentPage) else { return }

            DispatchQueue.main.async {
                self.parent.currentPage = pageIndex
            }
        }
    }
}

/// Load a PDF from data
public extension PDFDocument {
    convenience init?(imageData: [Data]) {
        self.init()

        for (index, data) in imageData.enumerated() {
            guard let image = UIImage(data: data),
                  let page = PDFPage(image: image) else { continue }
            self.insert(page, at: index)
        }

        guard self.pageCount > 0 else { return nil }
    }
}

// MARK: - PDF Thumbnail Generator

public struct PDFThumbnailGenerator {
    public init() {}

    /// Generate thumbnail for a specific page
    public func generateThumbnail(for page: PDFPage, size: CGSize) -> UIImage? {
        return page.thumbnail(of: size, for: .cropBox)
    }

    /// Generate thumbnails for all pages
    public func generateAllThumbnails(for document: PDFDocument, size: CGSize) -> [UIImage] {
        var thumbnails: [UIImage] = []

        for index in 0..<document.pageCount {
            if let page = document.page(at: index),
               let thumbnail = generateThumbnail(for: page, size: size) {
                thumbnails.append(thumbnail)
            }
        }

        return thumbnails
    }
}
