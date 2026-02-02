import SwiftUI

@main
struct DocuScanAIApp: App {
    
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

/// Global app state
class AppState: ObservableObject {
    @Published var isProUser: Bool = false
    @Published var showPaywall: Bool = false
    
    init() {
        // Check subscription status on launch
        Task {
            await checkSubscription()
        }
    }
    
    @MainActor
    func checkSubscription() async {
        // Will integrate with StoreKitManager
    }
}
