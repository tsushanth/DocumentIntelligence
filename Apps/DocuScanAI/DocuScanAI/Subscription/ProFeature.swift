import SwiftUI

// MARK: - Pro Features

enum ProFeature: String, CaseIterable, Identifiable {
    case ocrExtraction = "ocr"
    case aiSummary = "ai_summary"
    case autoTitle = "auto_title"
    case fieldExtraction = "field_extraction"
    case askAI = "ask_ai"
    case searchInDocuments = "search_documents"
    case cloudSync = "cloud_sync"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ocrExtraction: return "OCR Text Extraction"
        case .aiSummary: return "AI Summaries"
        case .autoTitle: return "Smart Titles"
        case .fieldExtraction: return "Extract Key Fields"
        case .askAI: return "Ask AI Questions"
        case .searchInDocuments: return "Search in Documents"
        case .cloudSync: return "iCloud Sync"
        }
    }

    var description: String {
        switch self {
        case .ocrExtraction:
            return "Extract text from scanned documents using OCR"
        case .aiSummary:
            return "Get AI-powered document summaries"
        case .autoTitle:
            return "Automatically generate smart titles for documents"
        case .fieldExtraction:
            return "Extract dates, amounts, and key information"
        case .askAI:
            return "Ask questions about your documents"
        case .searchInDocuments:
            return "Search text within all your documents"
        case .cloudSync:
            return "Sync documents across all your devices"
        }
    }

    var icon: String {
        switch self {
        case .ocrExtraction: return "text.viewfinder"
        case .aiSummary: return "sparkles"
        case .autoTitle: return "textformat"
        case .fieldExtraction: return "list.bullet.rectangle"
        case .askAI: return "bubble.left.and.bubble.right"
        case .searchInDocuments: return "doc.text.magnifyingglass"
        case .cloudSync: return "icloud"
        }
    }

    var color: Color {
        switch self {
        case .ocrExtraction: return .green
        case .aiSummary: return .purple
        case .autoTitle: return .blue
        case .fieldExtraction: return .orange
        case .askAI: return .indigo
        case .searchInDocuments: return .cyan
        case .cloudSync: return .pink
        }
    }

    // Features available in free tier
    static var freeFeatures: Set<ProFeature> {
        [] // All AI features are Pro-only
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
                            colors: [.purple, .blue],
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
