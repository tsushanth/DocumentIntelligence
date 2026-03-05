import SwiftUI
import PDFKit

struct CompressPDFView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sourceURL: URL?
    @State private var showingFilePicker = false
    @State private var isCompressing = false
    @State private var compressionResult: CompressionResult?
    @State private var showingShareSheet = false
    @State private var showingSuccess = false
    @State private var compressedURL: URL?
    @State private var errorMessage: String?
    @State private var quality: Double = 0.5

    struct CompressionResult {
        let originalSize: Int64
        let compressedSize: Int64
        var savings: Double {
            guard originalSize > 0 else { return 0 }
            return Double(originalSize - compressedSize) / Double(originalSize) * 100
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if sourceURL == nil {
                    emptyState
                } else {
                    compressionControls
                }
            }
            .padding()
            .navigationTitle("Compress PDF")
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
                        compressionResult = nil
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
            .alert("Compressed Successfully", isPresented: $showingSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your compressed PDF has been saved and is available in your documents.")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green.opacity(0.5))
            Text("Compress a PDF")
                .font(.title3.bold())
            Text("Reduce file size by compressing images within the PDF.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Choose PDF") { showingFilePicker = true }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            Spacer()
        }
    }

    private var compressionControls: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundStyle(.red)
                Text(sourceURL?.lastPathComponent ?? "PDF")
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                if let size = fileSize(sourceURL) {
                    Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 8) {
                Text("Compression Quality")
                    .font(.subheadline.bold())
                Slider(value: $quality, in: 0.1...0.9, step: 0.1)
                    .tint(.green)
                HStack {
                    Text("Smaller file")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Higher quality")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let result = compressionResult {
                VStack(spacing: 8) {
                    HStack {
                        Text("Original:")
                        Spacer()
                        Text(ByteCountFormatter.string(fromByteCount: result.originalSize, countStyle: .file))
                    }
                    HStack {
                        Text("Compressed:")
                        Spacer()
                        Text(ByteCountFormatter.string(fromByteCount: result.compressedSize, countStyle: .file))
                            .foregroundStyle(.green)
                    }
                    HStack {
                        Text("Savings:")
                        Spacer()
                        Text(String(format: "%.1f%%", result.savings))
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    if let url = compressedURL {
                        saveToDocuments(url)
                    }
                } label: {
                    Text("Save Compressed PDF")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Spacer()

            if compressionResult == nil {
                Button {
                    compressPDF()
                } label: {
                    HStack {
                        if isCompressing {
                            ProgressView().tint(.white)
                        } else {
                            Text("Compress")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isCompressing)
            }
        }
    }

    private func fileSize(_ url: URL?) -> Int64? {
        guard let url = url,
              let attrs = try? FileManager.default.attributesOfItem(atPath: url.path) else { return nil }
        return attrs[.size] as? Int64
    }

    private func compressPDF() {
        guard let url = sourceURL, let document = PDFDocument(url: url) else {
            errorMessage = "Failed to load PDF."
            return
        }

        isCompressing = true
        let originalSize = fileSize(url) ?? 0

        DispatchQueue.global(qos: .userInitiated).async {
            let newDoc = PDFDocument()
            for i in 0..<document.pageCount {
                guard let page = document.page(at: i) else { continue }
                let bounds = page.bounds(for: .mediaBox)
                let renderer = UIGraphicsImageRenderer(size: bounds.size)
                let image = renderer.image { ctx in
                    UIColor.white.setFill()
                    ctx.fill(CGRect(origin: .zero, size: bounds.size))
                    ctx.cgContext.translateBy(x: 0, y: bounds.height)
                    ctx.cgContext.scaleBy(x: 1, y: -1)
                    page.draw(with: .mediaBox, to: ctx.cgContext)
                }
                if let jpegData = image.jpegData(compressionQuality: quality),
                   let jpegImage = UIImage(data: jpegData),
                   let newPage = PDFPage(image: jpegImage) {
                    newDoc.insert(newPage, at: i)
                }
            }

            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Compressed_\(Date().timeIntervalSince1970).pdf")
            let success = newDoc.write(to: tempURL)

            DispatchQueue.main.async {
                isCompressing = false
                if success {
                    let compressedSize = fileSize(tempURL) ?? 0
                    compressedURL = tempURL
                    compressionResult = CompressionResult(originalSize: originalSize, compressedSize: compressedSize)
                } else {
                    errorMessage = "Failed to save compressed PDF."
                }
                url.stopAccessingSecurityScopedResource()
            }
        }
    }

    private func saveToDocuments(_ tempURL: URL) {
        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pdfDir = docsDir.appendingPathComponent("PDFs", isDirectory: true)
        try? FileManager.default.createDirectory(at: pdfDir, withIntermediateDirectories: true)
        let name = sourceURL?.deletingPathExtension().lastPathComponent ?? "Compressed"
        let savedURL = pdfDir.appendingPathComponent("\(name)_compressed.pdf")
        do {
            if FileManager.default.fileExists(atPath: savedURL.path) {
                try FileManager.default.removeItem(at: savedURL)
            }
            try FileManager.default.copyItem(at: tempURL, to: savedURL)
            showingSuccess = true
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
}
