import SwiftUI
import VisionKit

/// SwiftUI wrapper for VNDocumentCameraViewController
/// Provides automatic edge detection and document scanning
public struct DocumentScanner: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    private let onScan: ([UIImage]) -> Void
    private let onCancel: () -> Void

    public init(
        onScan: @escaping ([UIImage]) -> Void,
        onCancel: @escaping () -> Void = {}
    ) {
        self.onScan = onScan
        self.onCancel = onCancel
    }

    public func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }

    public func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScanner

        init(_ parent: DocumentScanner) {
            self.parent = parent
        }

        public func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            var images: [UIImage] = []
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                images.append(image)
            }
            parent.onScan(images)
            parent.dismiss()
        }

        public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.onCancel()
            parent.dismiss()
        }

        public func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            print("Document scanner error: \(error.localizedDescription)")
            parent.onCancel()
            parent.dismiss()
        }
    }

    /// Check if document scanning is available on this device
    public static var isSupported: Bool {
        VNDocumentCameraViewController.isSupported
    }
}

// MARK: - Preview Provider
#if DEBUG
struct DocumentScanner_Previews: PreviewProvider {
    static var previews: some View {
        DocumentScanner { images in
            print("Scanned \(images.count) pages")
        }
    }
}
#endif
