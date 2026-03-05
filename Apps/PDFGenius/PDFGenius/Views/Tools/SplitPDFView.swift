import SwiftUI
import PDFKit

struct SplitPDFView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sourceURL: URL?
    @State private var sourceDocument: PDFDocument?
    @State private var showingFilePicker = false
    @State private var selectedPages: Set<Int> = []
    @State private var isSplitting = false
    @State private var showingShareSheet = false
    @State private var showingSuccess = false
    @State private var extractedURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let doc = sourceDocument {
                    pageSelector(doc)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Split PDF")
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
                        sourceDocument = PDFDocument(url: url)
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
            .alert("Split Successfully", isPresented: $showingSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Extracted pages have been saved and are available in your documents.")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "scissors")
                .font(.system(size: 60))
                .foregroundStyle(.orange.opacity(0.5))
            Text("Select a PDF to Split")
                .font(.title3.bold())
            Text("Choose which pages to extract into a new document.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Choose PDF") { showingFilePicker = true }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            Spacer()
        }
        .padding()
    }

    private func pageSelector(_ doc: PDFDocument) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(sourceURL?.lastPathComponent ?? "PDF")
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text("\(doc.pageCount) pages")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Text("Select pages to extract:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                    ForEach(0..<doc.pageCount, id: \.self) { index in
                        Button {
                            if selectedPages.contains(index) {
                                selectedPages.remove(index)
                            } else {
                                selectedPages.insert(index)
                            }
                        } label: {
                            Text("\(index + 1)")
                                .font(.callout.bold())
                                .frame(width: 50, height: 50)
                                .background(selectedPages.contains(index) ? Color.orange : Color(.systemGray5))
                                .foregroundStyle(selectedPages.contains(index) ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(.horizontal)
            }

            if !selectedPages.isEmpty {
                Button {
                    extractPages()
                } label: {
                    HStack {
                        if isSplitting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Extract \(selectedPages.count) Page\(selectedPages.count == 1 ? "" : "s")")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .disabled(isSplitting)
            }
        }
    }

    private func extractPages() {
        guard let doc = sourceDocument else { return }
        isSplitting = true

        let newDoc = PDFDocument()
        let sortedPages = selectedPages.sorted()
        for (newIndex, pageIndex) in sortedPages.enumerated() {
            if let page = doc.page(at: pageIndex) {
                newDoc.insert(page, at: newIndex)
            }
        }

        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pdfDir = docsDir.appendingPathComponent("PDFs", isDirectory: true)
        try? FileManager.default.createDirectory(at: pdfDir, withIntermediateDirectories: true)
        let savedURL = pdfDir.appendingPathComponent("Split_\(UUID().uuidString.prefix(6)).pdf")

        if newDoc.write(to: savedURL) {
            extractedURL = savedURL
            sourceURL?.stopAccessingSecurityScopedResource()
            isSplitting = false
            showingSuccess = true
        } else {
            errorMessage = "Failed to save extracted pages."
            sourceURL?.stopAccessingSecurityScopedResource()
            isSplitting = false
        }
    }
}
