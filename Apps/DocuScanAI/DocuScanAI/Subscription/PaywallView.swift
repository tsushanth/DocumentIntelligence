import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var localErrorMessage: String?

    let feature: ProFeature?

    init(feature: ProFeature? = nil) {
        self.feature = feature
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Feature highlight if triggered by specific feature
                    if let feature = feature {
                        featureHighlight(feature)
                    }

                    // Features list
                    featuresSection

                    // Pricing options
                    pricingSection

                    // Purchase button
                    purchaseButton

                    // Restore & Terms
                    footerSection
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.gray.opacity(0.5))
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(localErrorMessage ?? subscriptionManager.errorMessage ?? "An error occurred")
            }
            .onAppear {
                // Pre-select annual as best value
                selectedPackage = subscriptionManager.annualPackage
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Crown icon with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }

            Text("Upgrade to Pro")
                .font(.largeTitle.bold())

            Text("Unlock AI-powered document insights and premium features")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 20)
    }

    // MARK: - Feature Highlight

    private func featureHighlight(_ feature: ProFeature) -> some View {
        HStack(spacing: 12) {
            Image(systemName: feature.icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(feature.color)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text("Unlock \(feature.displayName)")
                    .font(.headline)
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Everything in Pro")
                .font(.headline)
                .padding(.leading, 4)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(ProFeature.allCases) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.subheadline)

                        Text(feature.displayName)
                            .font(.subheadline)
                            .lineLimit(1)

                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Pricing Section

    @State private var selectedMockOption: MockPricingOption = .annual

    private var hasPackages: Bool {
        subscriptionManager.monthlyPackage != nil ||
        subscriptionManager.annualPackage != nil ||
        subscriptionManager.lifetimePackage != nil
    }

    private var pricingSection: some View {
        VStack(spacing: 12) {
            if subscriptionManager.isLoading {
                ProgressView()
                    .padding()
            } else if hasPackages {
                // Annual - Best Value
                if let annual = subscriptionManager.annualPackage {
                    PricingOptionView(
                        package: annual,
                        isSelected: selectedPackage?.identifier == annual.identifier,
                        badge: "BEST VALUE",
                        subtitle: "\(annual.pricePerMonth)/month",
                        savings: subscriptionManager.annualSavingsPercent
                    ) {
                        selectedPackage = annual
                    }
                }

                // Monthly
                if let monthly = subscriptionManager.monthlyPackage {
                    PricingOptionView(
                        package: monthly,
                        isSelected: selectedPackage?.identifier == monthly.identifier,
                        badge: nil,
                        subtitle: "Billed monthly",
                        savings: nil
                    ) {
                        selectedPackage = monthly
                    }
                }

                // Lifetime
                if let lifetime = subscriptionManager.lifetimePackage {
                    PricingOptionView(
                        package: lifetime,
                        isSelected: selectedPackage?.identifier == lifetime.identifier,
                        badge: "ONE TIME",
                        subtitle: "Pay once, own forever",
                        savings: nil
                    ) {
                        selectedPackage = lifetime
                    }
                }
            } else {
                // Show mock pricing for testing/preview
                mockPricingSection
            }
        }
    }

    // Mock pricing for local testing when RevenueCat isn't configured
    private var mockPricingSection: some View {
        VStack(spacing: 12) {
            MockPricingOptionView(
                option: .annual,
                isSelected: selectedMockOption == .annual,
                badge: "BEST VALUE",
                subtitle: "$2.50/month",
                savings: 50
            ) {
                selectedMockOption = .annual
            }

            MockPricingOptionView(
                option: .monthly,
                isSelected: selectedMockOption == .monthly,
                badge: nil,
                subtitle: "Billed monthly",
                savings: nil
            ) {
                selectedMockOption = .monthly
            }

            MockPricingOptionView(
                option: .lifetime,
                isSelected: selectedMockOption == .lifetime,
                badge: "ONE TIME",
                subtitle: "Pay once, own forever",
                savings: nil
            ) {
                selectedMockOption = .lifetime
            }
        }
    }

    // MARK: - Purchase Button

    private var canPurchase: Bool {
        if hasPackages {
            return selectedPackage != nil
        } else {
            return true
        }
    }

    private var purchaseButton: some View {
        Button {
            if hasPackages {
                purchase()
            } else {
                mockPurchase()
            }
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Continue")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .disabled(!canPurchase || isPurchasing)
        .opacity(canPurchase ? 1 : 0.6)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 12) {
            Button("Restore Purchases") {
                restore()
            }
            .font(.subheadline)
            .foregroundColor(.blue)

            HStack(spacing: 20) {
                Link("Terms of Use", destination: URL(string: "https://kreativekoala.llc/terms")!)
                Text("•")
                    .foregroundColor(.secondary)
                Link("Privacy Policy", destination: URL(string: "https://kreativekoala.llc/privacy")!)
            }
            .font(.footnote.weight(.medium))
            .foregroundColor(.blue)

            Text("Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Manage subscriptions in Settings.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func purchase() {
        guard let package = selectedPackage else { return }

        isPurchasing = true

        Task {
            do {
                let success = try await subscriptionManager.purchase(package)
                if success {
                    dismiss()
                }
            } catch {
                showError = true
            }
            isPurchasing = false
        }
    }

    private func mockPurchase() {
        localErrorMessage = "Products not loaded. Please ensure you're connected to the internet and try again."
        showError = true
    }

    private func restore() {
        isPurchasing = true

        Task {
            do {
                try await subscriptionManager.restorePurchases()
                if subscriptionManager.isPro {
                    dismiss()
                }
            } catch {
                showError = true
            }
            isPurchasing = false
        }
    }
}

// MARK: - Pricing Option View

struct PricingOptionView: View {
    let package: Package
    let isSelected: Bool
    let badge: String?
    let subtitle: String
    let savings: Int?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 16, height: 16)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(packageTitle)
                            .font(.headline)

                        if let badge = badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(4)
                        }

                        if let savings = savings, savings > 0 {
                            Text("Save \(savings)%")
                                .font(.caption2.bold())
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.15))
                                .cornerRadius(4)
                        }
                    }

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(package.localizedPriceString)
                    .font(.title3.bold())
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var packageTitle: String {
        switch package.packageType {
        case .monthly:
            return "Monthly"
        case .annual:
            return "Annual"
        case .lifetime:
            return "Lifetime"
        default:
            return package.storeProduct.localizedTitle
        }
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

// MARK: - Mock Pricing for Testing

enum MockPricingOption: String {
    case monthly
    case annual
    case lifetime

    var title: String {
        switch self {
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        case .lifetime: return "Lifetime"
        }
    }

    var price: String {
        switch self {
        case .monthly: return "$4.99"
        case .annual: return "$29.99"
        case .lifetime: return "$59.99"
        }
    }
}

struct MockPricingOptionView: View {
    let option: MockPricingOption
    let isSelected: Bool
    let badge: String?
    let subtitle: String
    let savings: Int?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 16, height: 16)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(option.title)
                            .font(.headline)

                        if let badge = badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(4)
                        }

                        if let savings = savings, savings > 0 {
                            Text("Save \(savings)%")
                                .font(.caption2.bold())
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.15))
                                .cornerRadius(4)
                        }
                    }

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(option.price)
                    .font(.title3.bold())
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView(feature: .aiSummary)
}
