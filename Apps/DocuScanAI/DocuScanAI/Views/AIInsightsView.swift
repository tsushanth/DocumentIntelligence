import SwiftUI

struct AIInsightsView: View {

    let document: ScannedDocument
    @StateObject private var viewModel: AIInsightsViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var showingPaywall = false
    @AppStorage("hasConsentedToAIDataSharing") private var hasConsentedToAI = false
    @State private var showingAIConsent = false
    @State private var pendingAIAction: (() -> Void)?

    init(document: ScannedDocument) {
        self.document = document
        self._viewModel = StateObject(wrappedValue: AIInsightsViewModel(document: document))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Free uses banner
                    if !appState.isProUser {
                        freeUsesBanner
                    }

                    // AI Data Notice
                    aiDataNotice

                    // OCR Text (always free — on-device)
                    insightCard(
                        title: "Full Text (OCR)",
                        icon: "doc.text.magnifyingglass",
                        color: .green,
                        isFree: true
                    ) {
                        if viewModel.isExtractingText {
                            ProgressView()
                        } else if let text = viewModel.ocrText {
                            ScrollView {
                                Text(text)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            }
                            .frame(maxHeight: 250)
                        } else {
                            generateButton("Extract Text") {
                                Task { await viewModel.extractText() }
                            }
                        }
                    }

                    // Auto-generated title (AI-powered)
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
                                requireAIConsent {
                                    if appState.canUseAIFeature {
                                        appState.consumeAIUse()
                                        Task { await viewModel.generateTitle() }
                                    } else {
                                        showingPaywall = true
                                    }
                                }
                            }
                        }
                    }

                    // Summary (AI-powered)
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
                                requireAIConsent {
                                    if appState.canUseAIFeature {
                                        appState.consumeAIUse()
                                        Task { await viewModel.generateSummary() }
                                    } else {
                                        showingPaywall = true
                                    }
                                }
                            }
                        }
                    }

                    // Extracted fields (AI-powered)
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
                                requireAIConsent {
                                    if appState.canUseAIFeature {
                                        appState.consumeAIUse()
                                        Task { await viewModel.extractFields() }
                                    } else {
                                        showingPaywall = true
                                    }
                                }
                            }
                        }
                    }

                    // Ask AI (AI-powered)
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
            .alert("Error", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingAIConsent) {
                AIConsentView(
                    onAccept: {
                        hasConsentedToAI = true
                        showingAIConsent = false
                        pendingAIAction?()
                        pendingAIAction = nil
                    },
                    onDecline: {
                        showingAIConsent = false
                        pendingAIAction = nil
                    }
                )
            }
        }
    }

    // MARK: - AI Consent Gate

    private func requireAIConsent(action: @escaping () -> Void) {
        if hasConsentedToAI {
            action()
        } else {
            pendingAIAction = action
            showingAIConsent = true
        }
    }

    // MARK: - AI Data Notice

    private var aiDataNotice: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
                .font(.caption)
            Text("OCR runs on-device. AI features (summaries, titles, field extraction, questions) send extracted text to our secure server powered by OpenAI for processing. No images are transmitted.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }

    // MARK: - Free Uses Banner

    private var freeUsesBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundColor(.blue)
            if appState.freeAIUsesRemaining > 0 {
                Text("\(appState.freeAIUsesRemaining) free AI use\(appState.freeAIUsesRemaining == 1 ? "" : "s") remaining")
                    .foregroundColor(.primary)
            } else {
                Text("Upgrade to Pro for unlimited AI insights")
                    .foregroundColor(.primary)
            }
            Spacer()
            if appState.freeAIUsesRemaining == 0 {
                Button {
                    showingPaywall = true
                } label: {
                    Text("Upgrade")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                }
            }
        }
        .font(.caption)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Insight Card

    private func insightCard<Content: View>(
        title: String,
        icon: String,
        color: Color,
        isFree: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)

                if isFree {
                    Text("FREE")
                        .font(.caption2.bold())
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(6)
                }

                Spacer()

                if !isFree && !appState.isProUser {
                    Button {
                        showingPaywall = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                            Text("PRO")
                                .font(.caption2.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
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
            if fields.date == nil && fields.vendor == nil && fields.amount == nil && fields.invoiceNumber == nil {
                Text("No key fields detected in this document.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
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

    // MARK: - Ask AI Section

    private var askAISection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "questionmark.bubble")
                    .foregroundColor(.indigo)
                Text("Ask AI")
                    .font(.headline)

                Spacer()

                if !appState.isProUser {
                    Button {
                        showingPaywall = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                            Text("PRO")
                                .font(.caption2.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
            }

            HStack {
                TextField("Ask a question about this document...", text: $viewModel.question)
                    .textFieldStyle(.roundedBorder)

                Button(action: {
                    requireAIConsent {
                        if appState.canUseAIFeature {
                            appState.consumeAIUse()
                            Task { await viewModel.askQuestion() }
                        } else {
                            showingPaywall = true
                        }
                    }
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

// MARK: - AI Consent View

struct AIConsentView: View {
    let onAccept: () -> Void
    let onDecline: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "brain.filled.head.profile")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue.gradient)

                        Text("AI Feature Data Usage")
                            .font(.title2.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)

                    // What data is sent
                    consentSection(
                        icon: "doc.text",
                        title: "What data is sent",
                        description: "When you use AI features (Smart Titles, Summaries, Field Extraction, Ask AI), the text extracted from your document via OCR is sent to our server for processing. No images or photos are transmitted."
                    )

                    // Who processes it
                    consentSection(
                        icon: "server.rack",
                        title: "Who processes your data",
                        description: "Your document text is processed by our secure server, which uses OpenAI's language model to generate insights. The data is not stored after processing and is not used to train AI models."
                    )

                    // What stays on device
                    consentSection(
                        icon: "iphone",
                        title: "What stays on your device",
                        description: "OCR text extraction runs entirely on your device using Apple's Vision framework. Your scanned images and PDF files are never uploaded."
                    )

                    // Privacy
                    consentSection(
                        icon: "lock.shield",
                        title: "Your privacy",
                        description: "We do not sell or share your document data. Processing is done only to provide you with the requested AI feature. See our Privacy Policy for full details."
                    )

                    Text("By tapping \"I Agree\", you consent to sending your document text to our server for AI processing as described above.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .padding(.horizontal)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Button(action: onAccept) {
                        Text("I Agree")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(14)
                    }

                    Button(action: onDecline) {
                        Text("No Thanks")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onDecline()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .interactiveDismissDisabled()
    }

    private func consentSection(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    AIInsightsView(document: ScannedDocument(title: "Test", pageCount: 1))
        .environmentObject(AppState())
}
