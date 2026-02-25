import SwiftUI
import PDFKit

struct PDFEditorView: View {

    let document: PDFDocumentItem
    @StateObject private var viewModel: PDFEditorViewModel
    @State private var showingTools = false
    @State private var showingSignature = false
    @State private var showingAIAssistant = false
    @State private var currentTool: EditingTool = .none

    enum EditingTool {
        case none
        case highlight
        case underline
        case text
        case draw
    }

    init(document: PDFDocumentItem) {
        self.document = document
        self._viewModel = StateObject(wrappedValue: PDFEditorViewModel(document: document))
    }

    var body: some View {
        ZStack {
            // PDF View
            if let pdfDocument = viewModel.pdfDocument {
                PDFEditableView(
                    document: pdfDocument,
                    currentTool: $currentTool,
                    viewModel: viewModel
                )
            } else {
                ProgressView("Loading...")
            }

            // Floating toolbar
            VStack {
                Spacer()
                floatingToolbar
            }
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { showingAIAssistant = true }) {
                    Image(systemName: "sparkles")
                }

                Button(action: { showingSignature = true }) {
                    Image(systemName: "signature")
                }

                Menu {
                    Button(action: viewModel.savePDF) {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    Button(action: viewModel.sharePDF) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Divider()
                    Button(action: viewModel.mergePDFs) {
                        Label("Merge PDFs", systemImage: "doc.on.doc")
                    }
                    Button(action: viewModel.splitPDF) {
                        Label("Split PDF", systemImage: "scissors")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingSignature) {
            SignatureView(onSignature: viewModel.addSignature)
        }
        .sheet(isPresented: $showingAIAssistant) {
            PDFAIAssistantView(document: document, viewModel: viewModel)
        }
    }

    private var floatingToolbar: some View {
        HStack(spacing: 16) {
            toolButton(.highlight, icon: "highlighter", color: .yellow)
            toolButton(.underline, icon: "underline", color: .red)
            toolButton(.text, icon: "textformat", color: .blue)
            toolButton(.draw, icon: "pencil.tip", color: .black)

            Divider()
                .frame(height: 30)

            Button(action: viewModel.undo) {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!viewModel.canUndo)

            Button(action: viewModel.redo) {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!viewModel.canRedo)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(25)
        .shadow(radius: 10)
        .padding(.bottom, 20)
    }

    private func toolButton(_ tool: EditingTool, icon: String, color: Color) -> some View {
        Button(action: { currentTool = currentTool == tool ? .none : tool }) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(currentTool == tool ? .white : color)
                .padding(10)
                .background(currentTool == tool ? color : Color.clear)
                .cornerRadius(8)
        }
    }
}

struct PDFEditableView: UIViewRepresentable {
    let document: PDFDocument
    @Binding var currentTool: PDFEditorView.EditingTool
    @ObservedObject var viewModel: PDFEditorViewModel

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = document
    }
}

#Preview {
    NavigationStack {
        PDFEditorView(document: PDFDocumentItem(title: "Sample", fileURL: nil, pageCount: 5, fileSize: 1024000))
    }
    .environmentObject(AppState())
}
