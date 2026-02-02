import SwiftUI
import VisionKit

struct ScannerView: View {
    
    @StateObject private var viewModel = ScannerViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.scannedImages.isEmpty {
                    emptyState
                } else {
                    scannedImagesList
                }
                
                bottomToolbar
            }
            .navigationTitle("Scanner")
            .sheet(isPresented: $viewModel.showScanner) {
                DocumentScannerSheet(viewModel: viewModel)
            }
            .alert("Save Document", isPresented: $viewModel.showingSaveDialog) {
                TextField("Document Title", text: $viewModel.documentTitle)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    Task {
                        _ = await viewModel.saveDocument()
                    }
                }
            } message: {
                Text("Enter a name for your scanned document")
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 100))
                .foregroundColor(.blue.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("Ready to Scan")
                    .font(.title2.bold())
                
                Text("Position your document within the camera frame")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: viewModel.startScanning) {
                Label("Start Scanning", systemImage: "camera.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .disabled(!viewModel.isSupported)
            
            Spacer()
        }
    }
    
    private var scannedImagesList: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                ForEach(Array(viewModel.scannedImages.enumerated()), id: \.offset) { index, image in
                    ScannedImageCard(
                        image: image,
                        pageNumber: index + 1,
                        onDelete: { viewModel.removeImage(at: index) }
                    )
                }
                
                // Add more button
                Button(action: viewModel.startScanning) {
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        Text("Add Pages")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }
    
    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 20) {
                // Filter selector
                Menu {
                    ForEach(ScannerViewModel.ImageFilter.allCases, id: \.self) { filter in
                        Button(action: { viewModel.applyFilter(filter) }) {
                            Label(filter.rawValue, systemImage: filter.icon)
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: viewModel.selectedFilter.icon)
                            .font(.title3)
                        Text(viewModel.selectedFilter.rawValue)
                            .font(.caption2)
                    }
                    .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Page count
                if !viewModel.scannedImages.isEmpty {
                    Text("\(viewModel.scannedImages.count) pages")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Save button
                Button(action: {
                    Task { await viewModel.generatePDF() }
                }) {
                    Text("Save PDF")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(viewModel.canSave ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!viewModel.canSave || viewModel.isProcessing)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}

struct ScannedImageCard: View {
    let image: UIImage
    let pageNumber: Int
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 8) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 180)
                    .clipped()
                    .cornerRadius(8)
                
                Text("Page \(pageNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            .padding(8)
        }
    }
}

struct DocumentScannerSheet: UIViewControllerRepresentable {
    @ObservedObject var viewModel: ScannerViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let viewModel: ScannerViewModel
        
        init(viewModel: ScannerViewModel) {
            self.viewModel = viewModel
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            Task { @MainActor in
                viewModel.handleScanComplete(images: images)
            }
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            Task { @MainActor in
                viewModel.handleScanCancel()
            }
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            Task { @MainActor in
                viewModel.handleScanCancel()
            }
        }
    }
}

#Preview {
    ScannerView()
        .environmentObject(AppState())
}
