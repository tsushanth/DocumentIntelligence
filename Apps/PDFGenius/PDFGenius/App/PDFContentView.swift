import SwiftUI

struct PDFContentView: View {

    @State private var selectedTab = 0
    @StateObject private var paywallCoordinator = PaywallCoordinator.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var showAppOpenPaywall = false

    // Show paywall on 2nd, 4th, 7th app open (then every 5th after)
    private static let paywallTriggerOpens: Set<Int> = [2, 4, 7]
    private static let paywallRecurringInterval = 5

    private var isFastlaneSnapshot: Bool {
        UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT")
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DocumentListView()
                .tabItem {
                    Label("Documents", systemImage: "doc.fill")
                }
                .tag(0)

            PDFToolsView()
                .tabItem {
                    Label("Tools", systemImage: "slider.horizontal.3")
                }
                .tag(1)

            PDFSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .tint(.purple)
        .sheet(isPresented: $paywallCoordinator.showWinbackOffer) {
            WinbackOfferView()
        }
        .fullScreenCover(isPresented: $showAppOpenPaywall) {
            RemotePaywallView(triggerSource: "app_open")
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                paywallCoordinator.checkWinbackEligibility()
            }
        }
        .onAppear {
            checkAppOpenPaywall()
        }
    }

    private func checkAppOpenPaywall() {
        // Skip paywall in Fastlane snapshot mode
        guard !isFastlaneSnapshot else { return }
        // Don't show to pro users
        guard !SubscriptionManager.shared.isPro else { return }

        let key = "com.pdfgenius.appOpenCount"
        let count = UserDefaults.standard.integer(forKey: key) + 1
        UserDefaults.standard.set(count, forKey: key)

        // Trigger on specific opens, then recurring
        let shouldShow = Self.paywallTriggerOpens.contains(count)
            || (count > 7 && (count - 7) % Self.paywallRecurringInterval == 0)

        if shouldShow {
            // Small delay so the app loads first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showAppOpenPaywall = true
            }
        }
    }
}

#Preview {
    PDFContentView()
        .environmentObject(PDFAppState())
}
