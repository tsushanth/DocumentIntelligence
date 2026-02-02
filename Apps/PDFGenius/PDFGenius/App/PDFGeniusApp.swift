import SwiftUI

@main
struct PDFGeniusApp: App {
    
    @StateObject private var appState = PDFAppState()
    
    var body: some Scene {
        WindowGroup {
            PDFContentView()
                .environmentObject(appState)
        }
    }
}

class PDFAppState: ObservableObject {
    @Published var isProUser: Bool = false
    @Published var showPaywall: Bool = false
    
    init() {
        Task {
            await checkSubscription()
        }
    }
    
    @MainActor
    func checkSubscription() async {
        // Will integrate with StoreKitManager
    }
}
