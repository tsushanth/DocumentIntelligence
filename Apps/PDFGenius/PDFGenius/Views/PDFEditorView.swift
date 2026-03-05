import SwiftUI
import PDFKit

struct PDFEditorView: View {
    
    let document: PDFDocumentItem
    @StateObject private var viewModel: PDFEditorViewModel
    @EnvironmentObject var appState: PDFAppState
    @State private var showingTools = false
    @State private var showingSignature = false
    @State private var showingAIAssistant = false
    @State private var showingShareSheet = false
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
            } else if let error = viewModel.loadError {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.headline)
                    Text("Try importing the PDF again.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
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
                    Button(action: {
                        viewModel.savePDF()
                    }) {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    Button(action: {
                        if let url = viewModel.sharePDF() {
                            let avc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let root = scene.keyWindow?.rootViewController {
                                let presenter = root.presentedViewController ?? root
                                avc.popoverPresentationController?.sourceView = presenter.view
                                presenter.present(avc, animated: true)
                            }
                        }
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
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

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous

        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPressDrag(_:))
        )
        longPress.minimumPressDuration = 0.15
        longPress.delegate = context.coordinator
        pdfView.addGestureRecognizer(longPress)
        context.coordinator.pdfView = pdfView

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = document
        context.coordinator.pdfView = pdfView
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var pdfView: PDFView?
        private var draggedAnnotation: PDFAnnotation?
        private var draggedPage: PDFPage?
        private var dragOffset: CGPoint = .zero

        // Only activate when touching a signature annotation
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pdfView = pdfView else { return false }
            let location = gestureRecognizer.location(in: pdfView)
            guard let page = pdfView.page(for: location, nearest: true) else { return false }
            let pagePoint = pdfView.convert(location, to: page)
            // Use inflated bounds for easier grabbing
            return page.annotations.contains {
                $0 is ImageStampAnnotation && $0.bounds.insetBy(dx: -20, dy: -20).contains(pagePoint)
            }
        }

        @objc func handleLongPressDrag(_ gesture: UILongPressGestureRecognizer) {
            guard let pdfView = pdfView else { return }
            let location = gesture.location(in: pdfView)

            switch gesture.state {
            case .began:
                guard let page = pdfView.page(for: location, nearest: true) else { return }
                let pagePoint = pdfView.convert(location, to: page)
                for annotation in page.annotations where annotation is ImageStampAnnotation {
                    if annotation.bounds.insetBy(dx: -20, dy: -20).contains(pagePoint) {
                        draggedAnnotation = annotation
                        draggedPage = page
                        dragOffset = CGPoint(
                            x: pagePoint.x - annotation.bounds.origin.x,
                            y: pagePoint.y - annotation.bounds.origin.y
                        )
                        // Disable scrolling while dragging
                        findScrollView(in: pdfView)?.isScrollEnabled = false
                        break
                    }
                }
            case .changed:
                guard let annotation = draggedAnnotation, let page = draggedPage else { return }
                let pagePoint = pdfView.convert(location, to: page)
                annotation.bounds = CGRect(
                    x: pagePoint.x - dragOffset.x,
                    y: pagePoint.y - dragOffset.y,
                    width: annotation.bounds.width,
                    height: annotation.bounds.height
                )
            case .ended, .cancelled:
                // Transfer annotation to the drop page if it changed
                if let annotation = draggedAnnotation,
                   let oldPage = draggedPage,
                   let dropPage = pdfView.page(for: location, nearest: true),
                   dropPage != oldPage {
                    let dropPoint = pdfView.convert(location, to: dropPage)
                    oldPage.removeAnnotation(annotation)
                    annotation.bounds = CGRect(
                        x: dropPoint.x - dragOffset.x,
                        y: dropPoint.y - dragOffset.y,
                        width: annotation.bounds.width,
                        height: annotation.bounds.height
                    )
                    dropPage.addAnnotation(annotation)
                }
                draggedAnnotation = nil
                draggedPage = nil
                // Re-enable scrolling
                findScrollView(in: pdfView)?.isScrollEnabled = true
            default:
                break
            }
        }

        private func findScrollView(in view: UIView) -> UIScrollView? {
            for subview in view.subviews {
                if let scrollView = subview as? UIScrollView {
                    return scrollView
                }
                if let found = findScrollView(in: subview) {
                    return found
                }
            }
            return nil
        }
    }
}

#Preview {
    NavigationStack {
        PDFEditorView(document: PDFDocumentItem(title: "Sample", fileURL: nil, pageCount: 5, fileSize: 1024000))
    }
    .environmentObject(PDFAppState())
}
