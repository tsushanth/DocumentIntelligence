import SwiftUI

struct PDFDocumentListView: View {

    @StateObject private var viewModel = PDFDocumentListViewModel()
    @State private var showingFilePicker = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.documents.isEmpty {
                    emptyState
                } else {
                    documentList
                }
            }
            .navigationTitle("PDFs")
            .searchable(text: $searchText, prompt: "Search PDFs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilePicker = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: true
            ) { result in
                viewModel.handleFileImport(result)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            Text("No PDFs Yet")
                .font(.title2.bold())

            Text("Import PDFs to view, edit, and sign them")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: { showingFilePicker = true }) {
                Label("Import PDF", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.purple)
                    .cornerRadius(10)
            }
        }
    }

    private var documentList: some View {
        List {
            ForEach(filteredDocuments) { document in
                NavigationLink(destination: PDFEditorView(document: document)) {
                    PDFDocumentRow(document: document)
                }
            }
            .onDelete(perform: viewModel.deleteDocuments)
        }
    }

    private var filteredDocuments: [PDFDocumentItem] {
        if searchText.isEmpty {
            return viewModel.documents
        }
        return viewModel.documents.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
}

struct PDFDocumentRow: View {
    let document: PDFDocumentItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .font(.title)
                .foregroundColor(.purple)
                .frame(width: 50, height: 65)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.body)
                    .lineLimit(2)

                Text("\(document.pageCount) pages • \(document.formattedSize)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PDFDocumentListView()
        .environmentObject(AppState())
}
