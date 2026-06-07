import SwiftUI
import TikTokBusinessSDK
import FacebookCore
import PaywallKit
import RatingKit

@main
struct PDFGeniusApp: App {

    @StateObject private var appState = PDFAppState()
    @StateObject private var paywallCoordinator = PaywallCoordinator.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasRequestedATT = false

    init() {
        // Initialize TikTok Events SDK
        TikTokHelper.shared.initialize()

        // Initialize Facebook SDK
        FacebookHelper.shared.initialize()

        // Configure StoreKit 2 via PaywallKit (replaces RevenueCat)
        StoreManager.shared.configure(productIds: ProductID.allIDs)

        // Server-driven rating prompts (variant testing + analytics).
        RatingKit.configure(appId: "pdfgenius", apiUrl: "https://paywallkit-api.fly.dev")
        RatingKit.shared.trackAppOpen()

        // Apple Search Ads attribution (AdServices) — registers ASA install conversions.
        AttributionService.shared.trackAttribution()
    }

    var body: some Scene {
        WindowGroup {
            PDFContentView()
                .ratingPrompt()
                .environmentObject(appState)
                .sheet(isPresented: $paywallCoordinator.showWinbackOffer) {
                    WinbackOfferView()
                }
                .task {
                    await PromoCodeManager.shared.checkClipboard()
                }
                .onOpenURL { url in
                    PromoCodeManager.shared.handleURL(url)
                    ApplicationDelegate.shared.application(
                        UIApplication.shared,
                        open: url,
                        sourceApplication: nil,
                        annotation: UIApplication.OpenURLOptionsKey.annotation
                    )
                }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task { await appState.checkSubscription() }
                paywallCoordinator.checkWinbackEligibility()
                if !hasRequestedATT {
                    hasRequestedATT = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        TikTokHelper.shared.requestTrackingPermission()
                        FacebookHelper.shared.updateTrackingStatus()
                    }
                }
            }
        }
    }
}

class PDFAppState: ObservableObject {
    @Published var isProUser: Bool = false
    @Published var showPaywall: Bool = false

    private var subscriptionManager = SubscriptionManager.shared

    init() {
        Task {
            await checkSubscription()
        }
    }

    @MainActor
    func checkSubscription() async {
        await subscriptionManager.validateSubscriptionState()
        isProUser = subscriptionManager.isPro
    }
}
