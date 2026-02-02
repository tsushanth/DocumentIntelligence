import SwiftUI

struct AIInsightsView: View {
    
    let document: ScannedDocument
    @StateObject private var viewModel: AIInsightsViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    init(document: ScannedDocument) {
        self.document = document
        self._viewModel = StateObject(wrappedValue: AIInsightsViewModel(document: document))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Auto-generated title
                    insightCard(
                        title: "Smart Title",
                        icon: "textformat",
                        color: .blue
                    ) {
                        if viewModel.isGeneratingTitle {
                            ProgressView()
                        } else if let title = viewModel.generatedTitle {
                            Text(title)
                                .font(.headline)
                        } else {
                            generateButton("Generate Title") {
                                Task { await viewModel.generateTitle() }
                            }
                        }
                    }
                    
                    // Summary
                    insightCard(
                        title: "Summary",
                        icon: "doc.text",
                        color: .purple
                    ) {
                        if viewModel.isGeneratingSummary {
                            ProgressView()
                        } else if let summary = viewModel.summary {
                            Text(summary)
                                .font(.body)
                        } else {
                            generateButton("Generate Summary") {
                                Task { await viewModel.generateSummary() }
                            }
                        }
                    }
                    
                    // Extracted fields
                    insightCard(
                        title: "Key Information",
                        icon: "list.bullet.rectangle",
                        color: .orange
                    ) {
                        if viewModel.isExtractingFields {
                            ProgressView()
                        } else if let fields = viewModel.extractedFields {
                            extractedFieldsList(fields)
                        } else {
                            generateButton("Extract Fields") {
                                Task { await viewModel.extractFields() }
                            }
                        }
                    }
                    
                    // OCR Text
                    insightCard(
                        title: "Full Text (OCR)",
                        icon: "doc.text.magnifyingglass",
                        color: .green
                    ) {
                        if viewModel.isExtractingText {
                            ProgressView()
                        } else if let text = viewModel.ocrText {
                            Text(text)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(10)
                        } else {
                            generateButton("Extract Text") {
                                Task { await viewModel.extractText() }
                            }
                        }
                    }
                    
                    // Ask AI
                    askAISection
                }
                .padding()
            }
            .navigationTitle("AI Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func insightCard<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                if !appState.isProUser {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            content()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func generateButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: "sparkles")
                Text(title)
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(8)
        }
    }
    
    private func extractedFieldsList(_ fields: ExtractedDocumentFields) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let date = fields.date {
                fieldRow("Date", value: date)
            }
            if let vendor = fields.vendor {
                fieldRow("Vendor", value: vendor)
            }
            if let amount = fields.amount {
                fieldRow("Amount", value: amount)
            }
            if let invoiceNumber = fields.invoiceNumber {
                fieldRow("Invoice #", value: invoiceNumber)
            }
        }
    }
    
    private func fieldRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    private var askAISection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "questionmark.bubble")
                    .foregroundColor(.indigo)
                Text("Ask AI")
                    .font(.headline)
            }
            
            HStack {
                TextField("Ask a question about this document...", text: $viewModel.question)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: {
                    Task { await viewModel.askQuestion() }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.question.isEmpty || viewModel.isAskingQuestion)
            }
            
            if viewModel.isAskingQuestion {
                ProgressView()
            } else if let answer = viewModel.answer {
                Text(answer)
                    .font(.body)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    AIInsightsView(document: ScannedDocument(title: "Test", pageCount: 1))
        .environmentObject(AppState())
}
