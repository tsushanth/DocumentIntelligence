import SwiftUI

// MARK: - Pro Features

enum ProFeature: String, CaseIterable, Identifiable {
    case signatures = "signatures"
    case drawing = "drawing"
    case mergeSplit = "merge_split"
    case aiSummary = "ai_summary"
    case aiContractAnalysis = "ai_contract"
    case aiQA = "ai_qa"
    case ocrExtraction = "ocr"
    case passwordProtection = "password"
    case convertToImages = "convert"
    case noWatermark = "no_watermark"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .signatures: return "Signatures"
        case .drawing: return "Drawing & Ink"
        case .mergeSplit: return "Merge & Split PDFs"
        case .aiSummary: return "AI Summaries"
        case .aiContractAnalysis: return "Contract Analysis"
        case .aiQA: return "Ask AI Questions"
        case .ocrExtraction: return "OCR Text Extraction"
        case .passwordProtection: return "Password Protection"
        case .convertToImages: return "Convert to Images"
        case .noWatermark: return "Export Without Watermark"
        }
    }

    var description: String {
        switch self {
        case .signatures:
            return "Create and place signatures on your documents"
        case .drawing:
            return "Draw and annotate with ink tools"
        case .mergeSplit:
            return "Combine multiple PDFs or split into parts"
        case .aiSummary:
            return "Get AI-powered document summaries"
        case .aiContractAnalysis:
            return "Analyze contracts for key clauses and risks"
        case .aiQA:
            return "Ask questions about your documents"
        case .ocrExtraction:
            return "Extract text from scanned documents"
        case .passwordProtection:
            return "Secure PDFs with password encryption"
        case .convertToImages:
            return "Export PDF pages as images"
        case .noWatermark:
            return "Export documents without watermarks"
        }
    }

    var icon: String {
        switch self {
        case .signatures: return "signature"
        case .drawing: return "pencil.tip"
        case .mergeSplit: return "doc.on.doc"
        case .aiSummary: return "sparkles"
        case .aiContractAnalysis: return "doc.text.magnifyingglass"
        case .aiQA: return "bubble.left.and.bubble.right"
        case .ocrExtraction: return "text.viewfinder"
        case .passwordProtection: return "lock.fill"
        case .convertToImages: return "photo.on.rectangle"
        case .noWatermark: return "checkmark.seal"
        }
    }

    var color: Color {
        switch self {
        case .signatures: return .purple
        case .drawing: return .blue
        case .mergeSplit: return .orange
        case .aiSummary: return .pink
        case .aiContractAnalysis: return .red
        case .aiQA: return .indigo
        case .ocrExtraction: return .green
        case .passwordProtection: return .gray
        case .convertToImages: return .cyan
        case .noWatermark: return .mint
        }
    }

    // Features available in free tier
    static var freeFeatures: Set<ProFeature> {
        [] // All features are Pro-only except basic viewing and annotations
    }

    var requiresPro: Bool {
        !ProFeature.freeFeatures.contains(self)
    }
}

// MARK: - Feature Gate

@MainActor
class FeatureGate: ObservableObject {
    static let shared = FeatureGate()

    @Published var showingPaywall = false
    @Published var paywallFeature: ProFeature?

    private var subscriptionManager: SubscriptionManager {
        SubscriptionManager.shared
    }

    func canAccess(_ feature: ProFeature) -> Bool {
        if subscriptionManager.isPro {
            return true
        }
        return !feature.requiresPro
    }

    func requireFeature(_ feature: ProFeature, action: @escaping () -> Void) {
        if canAccess(feature) {
            action()
        } else {
            paywallFeature = feature
            showingPaywall = true
        }
    }

    func checkAccess(_ feature: ProFeature) -> Bool {
        if canAccess(feature) {
            return true
        } else {
            paywallFeature = feature
            showingPaywall = true
            return false
        }
    }
}

// MARK: - View Modifier for Feature Gating

struct FeatureGatedModifier: ViewModifier {
    let feature: ProFeature
    @ObservedObject private var gate = FeatureGate.shared
    @ObservedObject private var subscription = SubscriptionManager.shared

    func body(content: Content) -> some View {
        content
            .disabled(!gate.canAccess(feature))
            .overlay {
                if !gate.canAccess(feature) {
                    ProBadgeOverlay(feature: feature)
                }
            }
    }
}

struct ProBadgeOverlay: View {
    let feature: ProFeature
    @ObservedObject private var gate = FeatureGate.shared

    var body: some View {
        Button {
            gate.paywallFeature = feature
            gate.showingPaywall = true
        } label: {
            VStack {
                Spacer()
                HStack {
                    Spacer()
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
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

extension View {
    func featureGated(_ feature: ProFeature) -> some View {
        modifier(FeatureGatedModifier(feature: feature))
    }
}

// MARK: - Pro Badge Button

struct ProFeatureButton<Label: View>: View {
    let feature: ProFeature
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @ObservedObject private var gate = FeatureGate.shared
    @ObservedObject private var subscription = SubscriptionManager.shared

    var body: some View {
        Button {
            gate.requireFeature(feature, action: action)
        } label: {
            HStack {
                label()
                if !subscription.isPro && feature.requiresPro {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }
}
