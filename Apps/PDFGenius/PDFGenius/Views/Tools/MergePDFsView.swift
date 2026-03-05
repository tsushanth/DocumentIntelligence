import SwiftUI
import PDFKit

struct MergePDFsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedURLs: [URL] = []
    @State private var showingFilePicker = false
    @State private var isMerging = false
    @State private var mergedURL: URL?
    @State private var showingShareSheet = false
    @State private var showingSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if selectedURLs.isEmpty {
                    emptyState
                } else {
                    fileList
                }

                Spacer()

                if !selectedURLs.isEmpty {
                    mergeButton
                }
            }
            .padding()
            .navigationTitle("Merge PDFs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingFilePicker = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    for url in urls {
                        if url.startAccessingSecurityScopedResource() {
                            selectedURLs.append(url)
                        }
                    }
                case .failure:
                    errorMessage = "Failed to import files."
                }
            }
            .alert("Error", isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .alert("Merged Successfully", isPresented: $showingSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your merged PDF has been saved and is available in your documents.")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.on.doc")
                .font(.system(size: 60))
                .foregroundStyle(.blue.opacity(0.5))
            Text("Select PDFs to Merge")
                .font(.title3.bold())
            Text("Tap + to add PDF files you want to combine into one document.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add PDFs") { showingFilePicker = true }
                .buttonStyle(.borderedProminent)
            Spacer()
        }
    }

    private var fileList: some View {
        List {
            ForEach(selectedURLs, id: \.absoluteString) { url in
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(.red)
                    Text(url.lastPathComponent)
                        .lineLimit(1)
                }
            }
            .onDelete { offsets in
                let urls = offsets.map { selectedURLs[$0] }
                urls.forEach { $0.stopAccessingSecurityScopedResource() }
                selectedURLs.remove(atOffsets: offsets)
            }
            .onMove { from, to in
                selectedURLs.move(fromOffsets: from, toOffset: to)
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, .constant(.active))
    }

    private var mergeButton: some View {
        Button {
            performMerge()
        } label: {
            HStack {
                if isMerging {
                    ProgressView().tint(.white)
                } else {
                    Text("Merge \(selectedURLs.count) PDFs")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedURLs.count >= 2 ? Color.blue : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(selectedURLs.count < 2 || isMerging)
    }

    private func performMerge() {
        isMerging = true
        let mergedDocument = PDFDocument()
        var pageIndex = 0

        for url in selectedURLs {
            guard let doc = PDFDocument(url: url) else { continue }
            for i in 0..<doc.pageCount {
                if let page = doc.page(at: i) {
                    mergedDocument.insert(page, at: pageIndex)
                    pageIndex += 1
                }
            }
        }

        // Save to app's Documents/PDFs directory so it persists and shows in document list
        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pdfDir = docsDir.appendingPathComponent("PDFs", isDirectory: true)
        try? FileManager.default.createDirectory(at: pdfDir, withIntermediateDirectories: true)

        let fileName = "Merged_\(Date().formatted(.dateTime.year().month().day().hour().minute())).pdf"
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ",", with: "")
        let savedURL = pdfDir.appendingPathComponent(fileName)

        if mergedDocument.write(to: savedURL) {
            mergedURL = savedURL
            selectedURLs.forEach { $0.stopAccessingSecurityScopedResource() }
            isMerging = false
            showingSuccess = true
        } else {
            errorMessage = "Failed to save merged PDF."
            selectedURLs.forEach { $0.stopAccessingSecurityScopedResource() }
            isMerging = false
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// Present UIActivityViewController directly via UIKit (avoids blank screen in SwiftUI .sheet)
func presentShareSheet(items: [Any]) {
    let avc = UIActivityViewController(activityItems: items, applicationActivities: nil)
    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let root = scene.keyWindow?.rootViewController {
        let presenter = root.presentedViewController ?? root
        avc.popoverPresentationController?.sourceView = presenter.view
        presenter.present(avc, animated: true)
    }
}
