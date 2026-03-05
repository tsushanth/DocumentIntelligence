import SwiftUI
import PDFKit

struct ConvertPDFView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sourceURL: URL?
    @State private var showingFilePicker = false
    @State private var isConverting = false
    @State private var convertedImages: [UIImage] = []
    @State private var selectedImages: Set<Int> = []
    @State private var showingShareSheet = false
    @State private var showingSuccess = false
    @State private var savedImageCount = 0
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if sourceURL == nil {
                    emptyState
                } else if convertedImages.isEmpty && !isConverting {
                    convertControls
                } else if isConverting {
                    ProgressView("Converting pages...")
                        .padding()
                } else {
                    imageResults
                }
            }
            .navigationTitle("Convert to Images")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        _ = url.startAccessingSecurityScopedResource()
                        sourceURL = url
                    }
                case .failure:
                    errorMessage = "Failed to import file."
                }
            }
            .alert("Error", isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .alert("Saved to Photos", isPresented: $showingSuccess) {
                Button("Open Photos") {
                    if let url = URL(string: "photos-redirect://") {
                        UIApplication.shared.open(url)
                    }
                    dismiss()
                }
                Button("Done") { dismiss() }
            } message: {
                Text("\(savedImageCount) image\(savedImageCount == 1 ? "" : "s") saved. Open the Photos app to view them.")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 60))
                .foregroundStyle(.purple.opacity(0.5))
            Text("Convert PDF to Images")
                .font(.title3.bold())
            Text("Export each page of a PDF as a high-quality image.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Choose PDF") { showingFilePicker = true }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            Spacer()
        }
        .padding()
    }

    private var convertControls: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundStyle(.red)
                Text(sourceURL?.lastPathComponent ?? "PDF")
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()

            Button {
                convertToImages()
            } label: {
                Text("Convert to Images")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }

    private var imageResults: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(convertedImages.count) pages converted")
                    .font(.headline)
                Spacer()
                Button(selectedImages.count == convertedImages.count ? "Deselect All" : "Select All") {
                    if selectedImages.count == convertedImages.count {
                        selectedImages.removeAll()
                    } else {
                        selectedImages = Set(convertedImages.indices)
                    }
                }
                .font(.subheadline)
            }
            .padding(.horizontal)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(convertedImages.indices, id: \.self) { index in
                        Button {
                            if selectedImages.contains(index) {
                                selectedImages.remove(index)
                            } else {
                                selectedImages.insert(index)
                            }
                        } label: {
                            VStack(spacing: 4) {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: convertedImages[index])
                                        .resizable()
                                        .scaledToFit()
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedImages.contains(index) ? Color.purple : Color.clear, lineWidth: 3)
                                        )
                                        .shadow(radius: 2)
                                    if selectedImages.contains(index) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.purple)
                                            .background(Circle().fill(.white))
                                            .padding(4)
                                    }
                                }
                                Text("Page \(index + 1)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }

            Button {
                saveImagesToPhotos()
            } label: {
                Text("Save \(selectedImages.count) Image\(selectedImages.count == 1 ? "" : "s")")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedImages.isEmpty ? Color.gray : Color.purple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(selectedImages.isEmpty)
            .padding(.horizontal)
        }
    }

    private func convertToImages() {
        guard let url = sourceURL, let document = PDFDocument(url: url) else {
            errorMessage = "Failed to load PDF."
            return
        }

        isConverting = true
        DispatchQueue.global(qos: .userInitiated).async {
            var images: [UIImage] = []
            for i in 0..<document.pageCount {
                guard let page = document.page(at: i) else { continue }
                let bounds = page.bounds(for: .mediaBox)
                let scale: CGFloat = 2.0
                let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
                let renderer = UIGraphicsImageRenderer(size: size)
                let image = renderer.image { ctx in
                    UIColor.white.setFill()
                    ctx.fill(CGRect(origin: .zero, size: size))
                    ctx.cgContext.scaleBy(x: scale, y: scale)
                    ctx.cgContext.translateBy(x: 0, y: bounds.height)
                    ctx.cgContext.scaleBy(x: 1, y: -1)
                    page.draw(with: .mediaBox, to: ctx.cgContext)
                }
                images.append(image)
            }

            DispatchQueue.main.async {
                convertedImages = images
                selectedImages = Set(images.indices) // Select all by default
                isConverting = false
                url.stopAccessingSecurityScopedResource()
            }
        }
    }

    private func saveImagesToPhotos() {
        let indices = selectedImages.sorted()
        savedImageCount = indices.count
        let saver = ImageSaver(count: indices.count) { error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "Failed to save images: \(error.localizedDescription)"
                } else {
                    showingSuccess = true
                }
            }
        }
        for index in indices {
            saver.save(convertedImages[index])
        }
    }
}

private class ImageSaver: NSObject {
    private let completion: (Error?) -> Void
    private var lastError: Error?
    private var remaining: Int
    private static var activeSaver: ImageSaver?

    init(count: Int, completion: @escaping (Error?) -> Void) {
        self.completion = completion
        self.remaining = count
        super.init()
        ImageSaver.activeSaver = self // prevent deallocation
    }

    func save(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(didFinishSaving), nil)
    }

    @objc private func didFinishSaving(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer?) {
        if let error = error { lastError = error }
        remaining -= 1
        if remaining <= 0 {
            completion(lastError)
            ImageSaver.activeSaver = nil
        }
    }
}
