import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var manager = SubscriptionManager.shared
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""

    let feature: ProFeature?

    init(feature: ProFeature? = nil) {
        self.feature = feature
    }

    private var proFeatures: [(icon: String, title: String, description: String)] {
        [
            ("doc.on.doc.fill", "Merge & Split PDFs", "Combine multiple PDFs into one or extract specific pages"),
            ("arrow.down.doc.fill", "Compress PDFs", "Reduce file size while maintaining quality"),
            ("photo.on.rectangle", "Convert to Images", "Export PDF pages as high-quality images"),
            ("lock.fill", "Password Protection", "Secure sensitive documents with encryption"),
            ("doc.text.viewfinder", "OCR Text Extraction", "Extract text from scanned PDFs using AI recognition"),
            ("signature", "Digital Signatures", "Create and place signatures on documents"),
            ("pencil.tip", "Drawing & Annotations", "Draw, highlight, and annotate documents"),
            ("sparkles", "AI Document Analysis", "Get summaries, contract analysis, and ask questions about your PDFs"),
            ("checkmark.seal.fill", "No Watermarks", "Export documents without any watermarks"),
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featuresSection
                    plansSection
                    purchaseButton
                    restoreSection
                    legalSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Upgrade to Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title2)
                    }
                }
            }
            .task {
                if manager.offerings == nil {
                    await manager.loadOfferings()
                }
                // Auto-select annual as best value
                selectedPackage = manager.annualPackage ?? manager.monthlyPackage
            }
            .onChange(of: manager.isPro) { isPro in
                if isPro { dismiss() }
            }
            .alert("Restore Purchases", isPresented: $showRestoreAlert) {
                Button("OK") { showRestoreAlert = false }
            } message: {
                Text(restoreMessage)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.richtext.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: .purple.opacity(0.3), radius: 10, y: 5)

            Text("All-in-One PDF Pro")
                .font(.title.bold())

            Text("Unlock every PDF tool and remove all limitations")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Everything You Get")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                ForEach(proFeatures, id: \.title) { feature in
                    HStack(spacing: 12) {
                        Image(systemName: feature.icon)
                            .font(.title3)
                            .foregroundStyle(.purple)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(feature.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Plans

    private var plansSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Plan")
                .font(.headline)
                .padding(.horizontal, 4)

            if manager.isLoading && manager.offerings == nil {
                HStack {
                    Spacer()
                    ProgressView().padding()
                    Spacer()
                }
                .frame(height: 150)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 12) {
                    if let lifetime = manager.lifetimePackage {
                        planOption(
                            package: lifetime,
                            title: "Pro Lifetime",
                            subtitle: "One-time purchase, yours forever",
                            badge: nil
                        )
                    }

                    if let annual = manager.annualPackage {
                        planOption(
                            package: annual,
                            title: "Pro Annual",
                            subtitle: annualSubtitle(annual),
                            badge: "Best Value"
                        )
                    }

                    if let monthly = manager.monthlyPackage {
                        planOption(
                            package: monthly,
                            title: "Pro Monthly",
                            subtitle: monthlySubtitle(monthly),
                            badge: nil
                        )
                    }
                }
            }
        }
    }

    private func annualSubtitle(_ package: Package) -> String {
        let monthlyPrice = package.pricePerMonth
        var subtitle = "\(monthlyPrice)/mo"
        if let trial = package.storeProduct.introductoryDiscount,
           trial.paymentMode == .freeTrial {
            let days = trial.subscriptionPeriod.value
            let unit = trial.subscriptionPeriod.unit
            let trialText: String
            switch unit {
            case .day: trialText = "\(days) day"
            case .week: trialText = "\(days) week"
            default: trialText = "\(days) day"
            }
            subtitle = "Start your \(trialText) free trial, then \(package.localizedPriceString)/yr (\(monthlyPrice)/mo)"
        } else {
            subtitle = "\(package.localizedPriceString)/yr (\(monthlyPrice)/mo)"
        }
        return subtitle
    }

    private func monthlySubtitle(_ package: Package) -> String {
        if let trial = package.storeProduct.introductoryDiscount,
           trial.paymentMode == .freeTrial {
            let days = trial.subscriptionPeriod.value
            let unit = trial.subscriptionPeriod.unit
            let trialText: String
            switch unit {
            case .day: trialText = "\(days) day"
            case .week: trialText = "\(days) week"
            default: trialText = "\(days) day"
            }
            return "Start your \(trialText) free trial, then \(package.localizedPriceString)/mo"
        }
        return "\(package.localizedPriceString)/mo, cancel anytime"
    }

    private func planOption(package: Package, title: String, subtitle: String, badge: String?) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedPackage = package
            }
        } label: {
            let isSelected = selectedPackage?.identifier == package.identifier
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if let badge = badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .clipShape(Capsule())
                        }
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(package.localizedPriceString)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .purple : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.purple : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            Task {
                guard let package = selectedPackage else { return }
                isPurchasing = true
                defer { isPurchasing = false }
                do {
                    let success = try await manager.purchase(package)
                    if success { dismiss() }
                } catch {
                    // Error handled by SubscriptionManager
                }
            }
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView().tint(.white)
                } else {
                    Text("Continue")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(selectedPackage == nil || isPurchasing)
    }

    // MARK: - Restore

    private var restoreSection: some View {
        Button {
            Task {
                do {
                    try await manager.restorePurchases()
                    if manager.isPro {
                        restoreMessage = "Your purchases have been restored successfully!"
                        showRestoreAlert = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
                    } else {
                        restoreMessage = "No previous purchases found."
                        showRestoreAlert = true
                    }
                } catch {
                    restoreMessage = "Failed to restore purchases. Please try again."
                    showRestoreAlert = true
                }
            }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundStyle(.blue)
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 8) {
            Text("Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period. Manage subscriptions in Settings.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link("Terms of Use", destination: URL(string: "https://kreativekoala.llc/terms")!)
                    .font(.caption)
                Text("•").foregroundStyle(.secondary)
                Link("Privacy Policy", destination: URL(string: "https://kreativekoala.llc/privacy")!)
                    .font(.caption)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Paywall Modifier

struct PaywallModifier: ViewModifier {
    @ObservedObject private var gate = FeatureGate.shared

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $gate.showingPaywall) {
                PaywallView(feature: gate.paywallFeature)
            }
    }
}

extension View {
    func withPaywall() -> some View {
        modifier(PaywallModifier())
    }
}

#Preview {
    PaywallView(feature: .signatures)
}
