import SwiftUI
import VisionKit

/// SwiftUI wrapper for VNDocumentCameraViewController
public struct DocumentScanner: UIViewControllerRepresentable {
    
    let onScanComplete: ([UIImage]) -> Void
    let onCancel: () -> Void
    
    public init(onScanComplete: @escaping ([UIImage]) -> Void, onCancel: @escaping () -> Void = {}) {
        self.onScanComplete = onScanComplete
        self.onCancel = onCancel
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    public func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    public class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScanner
        
        init(_ parent: DocumentScanner) {
            self.parent = parent
        }
        
        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            parent.onScanComplete(images)
        }
        
        public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.onCancel()
        }
        
        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.onCancel()
        }
    }
    
    /// Check if document scanning is supported
    public static var isSupported: Bool {
        VNDocumentCameraViewController.isSupported
    }
}

/// Document scanner view model
@MainActor
public class DocumentScannerViewModel: ObservableObject {
    
    @Published public var scannedImages: [UIImage] = []
    @Published public var isScanning = false
    @Published public var showScanner = false
    
    public init() {}
    
    public func startScanning() {
        guard DocumentScanner.isSupported else { return }
        showScanner = true
        isScanning = true
    }
    
    public func handleScanComplete(images: [UIImage]) {
        scannedImages.append(contentsOf: images)
        showScanner = false
        isScanning = false
    }
    
    public func handleCancel() {
        showScanner = false
        isScanning = false
    }
    
    public func removeImage(at index: Int) {
        guard index < scannedImages.count else { return }
        scannedImages.remove(at: index)
    }
    
    public func clearAll() {
        scannedImages.removeAll()
    }
    
    public func reorderImages(from source: IndexSet, to destination: Int) {
        scannedImages.move(fromOffsets: source, toOffset: destination)
    }
}
