import SwiftUI
import TikTokBusinessSDK
import RevenueCat

@main
struct PDFGeniusApp: App {

    @StateObject private var appState = PDFAppState()
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasRequestedATT = false

    init() {
        // Initialize TikTok Events SDK
        TikTokHelper.shared.initialize()

        // Initialize RevenueCat (triggers SubscriptionManager.shared singleton)
        _ = SubscriptionManager.shared
    }

    var body: some Scene {
        WindowGroup {
            PDFContentView()
                .environmentObject(appState)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task { await appState.checkSubscription() }
                if !hasRequestedATT {
                    hasRequestedATT = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        TikTokHelper.shared.requestTrackingPermission()
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
        await subscriptionManager.refreshCustomerInfo()
        isProUser = subscriptionManager.isPro
    }
}
