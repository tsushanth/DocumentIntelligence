import SwiftUI
import PDFKit

struct DocumentDetailView: View {
    
    let document: ScannedDocument
    @StateObject private var viewModel: DocumentDetailViewModel
    @EnvironmentObject var appState: AppState
    @State private var showingShareSheet = false
    @State private var showingAIInsights = false
    @State private var showingDeleteConfirmation = false
    
    init(document: ScannedDocument) {
        self.document = document
        self._viewModel = StateObject(wrappedValue: DocumentDetailViewModel(document: document))
    }
    
    var body: some View {
        ZStack {
            // PDF Viewer
            if let pdfDocument = viewModel.pdfDocument {
                PDFKitView(document: pdfDocument)
            } else {
                ProgressView("Loading...")
            }
            
            // Floating AI button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    aiButton
                        .padding()
                }
            }
        }
        .navigationTitle(document.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
                
                Menu {
                    Button(action: viewModel.renameDocument) {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button(action: { showingAIInsights = true }) {
                        Label("AI Insights", systemImage: "sparkles")
                    }
                    Divider()
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAIInsights) {
            AIInsightsView(document: document)
        }
        .confirmationDialog("Delete Document?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                viewModel.deleteDocument()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private var aiButton: some View {
        Button(action: { showingAIInsights = true }) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("AI Insights")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(25)
            .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = document
    }
}

#Preview {
    NavigationStack {
        DocumentDetailView(document: ScannedDocument(title: "Sample Document", pageCount: 3))
    }
    .environmentObject(AppState())
}
