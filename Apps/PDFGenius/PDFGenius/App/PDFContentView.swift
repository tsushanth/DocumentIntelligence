import SwiftUI

struct PDFContentView: View {

    @State private var selectedTab = 0
    @StateObject private var paywallCoordinator = PaywallCoordinator.shared
    @Environment(\.scenePhase) private var scenePhase

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
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                paywallCoordinator.checkWinbackEligibility()
            }
        }
    }
}

#Preview {
    PDFContentView()
        .environmentObject(PDFAppState())
}
