import SwiftUI
import PaywallKit

@MainActor
class PaywallCoordinator: ObservableObject {
    static let shared = PaywallCoordinator()
    @Published var showWinback = false
    private let dismissCountKey = "pwkit_paywall_dismiss_count"
    private let lastDismissKey = "pwkit_last_paywall_dismiss"
    
    func trackDismiss() {
        let count = UserDefaults.standard.integer(forKey: dismissCountKey) + 1
        UserDefaults.standard.set(count, forKey: dismissCountKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastDismissKey)
    }
    
    func checkWinback() {
        guard !StoreManager.shared.isPremium else { return }
        let count = UserDefaults.standard.integer(forKey: dismissCountKey)
        let lastDismiss = UserDefaults.standard.double(forKey: lastDismissKey)
        if count >= 3 && Date().timeIntervalSince1970 - lastDismiss >= 86400 {
            showWinback = true
            UserDefaults.standard.set(0, forKey: dismissCountKey)
        }
    }
}
