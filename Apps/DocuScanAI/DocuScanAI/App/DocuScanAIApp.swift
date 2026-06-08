import SwiftUI
import Combine

@main
struct DocuScanAIApp: App {

    @StateObject private var appState = AppState()

    init() {
        FirebaseTracking.shared.configure()
        TikTokAttribution.shared.configure()
        AttributionService.shared.trackAttribution()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    // Request ATT permission after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        TikTokAttribution.shared.requestTrackingPermission()
                    }
                }
        }
    }
}

/// Global app state
@MainActor
class AppState: ObservableObject {
    @Published var isProUser: Bool = false
    @Published var showPaywall: Bool = false
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Free AI Usage Tracking

    private static let freeAIUsesKey = "freeAIUsesRemaining"
    private static let defaultFreeUses = 3

    var freeAIUsesRemaining: Int {
        get {
            let stored = UserDefaults.standard.object(forKey: Self.freeAIUsesKey)
            return (stored as? Int) ?? Self.defaultFreeUses
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.freeAIUsesKey)
            objectWillChange.send()
        }
    }

    var canUseAIFeature: Bool {
        isProUser || freeAIUsesRemaining > 0
    }

    func consumeAIUse() {
        guard !isProUser, freeAIUsesRemaining > 0 else { return }
        freeAIUsesRemaining -= 1
    }

    init() {
        // Sync isProUser with SubscriptionManager's subscription tier
        SubscriptionManager.shared.$subscriptionTier
            .map { $0 == .pro }
            .receive(on: DispatchQueue.main)
            .assign(to: &$isProUser)
    }
}
