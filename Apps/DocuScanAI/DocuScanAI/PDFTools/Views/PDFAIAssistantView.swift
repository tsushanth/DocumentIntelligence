import SwiftUI

struct PDFAIAssistantView: View {

    let document: PDFDocumentItem
    @ObservedObject var viewModel: PDFEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0
    @State private var question = ""
    @State private var answer: String?
    @State private var isProcessing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                Picker("", selection: $selectedTab) {
                    Text("Summary").tag(0)
                    Text("Contract").tag(1)
                    Text("Ask AI").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                TabView(selection: $selectedTab) {
                    summaryTab.tag(0)
                    contractTab.tag(1)
                    askAITab.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var summaryTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let summary = viewModel.aiSummary {
                    Text(summary)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.purple.opacity(0.5))

                        Text("Generate a summary of this document")
                            .foregroundColor(.secondary)

                        Button(action: {
                            Task {
                                isProcessing = true
                                await viewModel.generateSummary()
                                isProcessing = false
                            }
                        }) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Label("Generate Summary", systemImage: "sparkles")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.purple)
                        .cornerRadius(10)
                        .disabled(isProcessing)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 60)
                }
            }
            .padding()
        }
    }

    private var contractTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Contract Analysis")
                    .font(.headline)

                // Parties
                analysisSection(title: "Parties", icon: "person.2", color: .blue) {
                    Text("• Acme Corporation")
                    Text("• John Doe")
                }

                // Key Clauses
                analysisSection(title: "Key Clauses", icon: "doc.text", color: .orange) {
                    Text("• Termination clause (Page 5)")
                    Text("• Payment terms: Net 30 (Page 3)")
                    Text("• Intellectual Property (Page 7)")
                }

                // Potential Risks
                analysisSection(title: "Potential Risks", icon: "exclamationmark.triangle", color: .red) {
                    Text("• Broad non-compete clause may limit future opportunities")
                    Text("• No liability cap specified")
                }

                Button(action: {}) {
                    Label("Analyze Contract", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
    }

    private func analysisSection<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline.bold())
            }

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var askAITab: some View {
        VStack(spacing: 16) {
            if let answer = answer {
                ScrollView {
                    Text(answer)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                }
            } else {
                Spacer()
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 50))
                    .foregroundColor(.purple.opacity(0.5))
                Text("Ask any question about this document")
                    .foregroundColor(.secondary)
                Spacer()
            }

            HStack {
                TextField("Ask a question...", text: $question)
                    .textFieldStyle(.roundedBorder)

                Button(action: askQuestion) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundColor(.purple)
                }
                .disabled(question.isEmpty || isProcessing)
            }
            .padding()
        }
    }

    private func askQuestion() {
        let q = question
        question = ""
        isProcessing = true

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            answer = "Based on the document, the answer to '\(q)' is: This appears to be related to the terms outlined in section 3.2..."
            isProcessing = false
        }
    }
}

#Preview {
    PDFAIAssistantView(
        document: PDFDocumentItem(title: "Test", fileURL: nil, pageCount: 5, fileSize: 1024),
        viewModel: PDFEditorViewModel(document: PDFDocumentItem(title: "Test", fileURL: nil, pageCount: 5, fileSize: 1024))
    )
    .environmentObject(AppState())
}
