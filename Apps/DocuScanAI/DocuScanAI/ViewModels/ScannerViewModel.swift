import SwiftUI
import VisionKit
import PDFKit

/// View model for scanner functionality
@MainActor
class ScannerViewModel: ObservableObject {
    
    @Published var scannedImages: [UIImage] = []
    @Published var isScanning = false
    @Published var showScanner = false
    @Published var selectedFilter: ImageFilter = .color
    @Published var isProcessing = false
    @Published var showingSaveDialog = false
    @Published var documentTitle = ""
    @Published var generatedPDF: PDFDocument?
    
    enum ImageFilter: String, CaseIterable {
        case color = "Color"
        case blackAndWhite = "B&W"
        case grayscale = "Grayscale"
        
        var icon: String {
            switch self {
            case .color: return "paintpalette"
            case .blackAndWhite: return "circle.lefthalf.filled"
            case .grayscale: return "circle.grid.2x2"
            }
        }
    }
    
    var canSave: Bool {
        !scannedImages.isEmpty
    }
    
    var isSupported: Bool {
        VNDocumentCameraViewController.isSupported
    }
    
    func startScanning() {
        guard isSupported else { return }
        showScanner = true
        isScanning = true
    }
    
    func handleScanComplete(images: [UIImage]) {
        scannedImages.append(contentsOf: images)
        showScanner = false
        isScanning = false
    }
    
    func handleScanCancel() {
        showScanner = false
        isScanning = false
    }
    
    func applyFilter(_ filter: ImageFilter) {
        selectedFilter = filter
        // Apply filter to all images
        // Will integrate with ImageProcessor
    }
    
    func removeImage(at index: Int) {
        guard index < scannedImages.count else { return }
        scannedImages.remove(at: index)
    }
    
    func reorderImages(from source: IndexSet, to destination: Int) {
        scannedImages.move(fromOffsets: source, toOffset: destination)
    }
    
    func clearAll() {
        scannedImages.removeAll()
        generatedPDF = nil
        documentTitle = ""
    }
    
    func generatePDF() async {
        isProcessing = true
        
        // Generate PDF from images
        // Will integrate with PDFGenerator
        
        isProcessing = false
        showingSaveDialog = true
    }
    
    func saveDocument() async -> ScannedDocument? {
        guard !scannedImages.isEmpty else { return nil }
        
        isProcessing = true
        defer { isProcessing = false }
        
        // Create and save document
        // Will integrate with DocumentStore
        
        let document = ScannedDocument(
            title: documentTitle.isEmpty ? "Scan \(Date().formatted())" : documentTitle,
            pageCount: scannedImages.count
        )
        
        clearAll()
        return document
    }
}
