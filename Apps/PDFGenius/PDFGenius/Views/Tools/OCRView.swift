import SwiftUI
import PDFKit
import Vision

struct OCRView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sourceURL: URL?
    @State private var showingFilePicker = false
    @State private var isExtracting = false
    @State private var extractedText = ""
    @State private var errorMessage: String?
    @State private var showingShareSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if sourceURL == nil {
                    emptyState
                } else if extractedText.isEmpty && !isExtracting {
                    extractButton
                } else if isExtracting {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Extracting text from PDF...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                } else {
                    textResult
                }
            }
            .navigationTitle("OCR - Extract Text")
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
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(.indigo.opacity(0.5))
            Text("Extract Text with OCR")
                .font(.title3.bold())
            Text("Use optical character recognition to extract text from scanned PDFs and images.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Choose PDF") { showingFilePicker = true }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            Spacer()
        }
        .padding()
    }

    private var extractButton: some View {
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
                performOCR()
            } label: {
                Text("Extract Text")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.indigo)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }

    private var textResult: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Extracted Text")
                    .font(.headline)
                Spacer()
                Button {
                    UIPasteboard.general.string = extractedText
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)

                Button {
                    presentShareSheet(items: [extractedText])
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            ScrollView {
                Text(extractedText)
                    .font(.body)
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }

    private func performOCR() {
        guard let url = sourceURL, let document = PDFDocument(url: url) else {
            errorMessage = "Failed to load PDF."
            return
        }

        isExtracting = true

        DispatchQueue.global(qos: .userInitiated).async {
            var allText = ""

            for i in 0..<document.pageCount {
                guard let page = document.page(at: i) else { continue }

                // First try PDFKit's built-in text extraction
                if let pageText = page.string, !pageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    allText += "--- Page \(i + 1) ---\n\(pageText)\n\n"
                    continue
                }

                // Fall back to Vision OCR for scanned pages
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

                guard let cgImage = image.cgImage else { continue }

                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])

                if let results = request.results {
                    let pageText = results.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                    if !pageText.isEmpty {
                        allText += "--- Page \(i + 1) ---\n\(pageText)\n\n"
                    }
                }
            }

            DispatchQueue.main.async {
                extractedText = allText.isEmpty ? "No text could be extracted from this PDF." : allText
                isExtracting = false
                url.stopAccessingSecurityScopedResource()
            }
        }
    }
}
