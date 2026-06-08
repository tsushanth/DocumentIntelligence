import Foundation
#if canImport(AdServices)
import AdServices
#endif

/// Registers Apple Search Ads conversions by exchanging the AdServices
/// attribution token with Apple's attribution API. Runs once per install.
final class AttributionService {
    static let shared = AttributionService()
    private let sentKey = "asa.attribution.sent"
    private init() {}

    func trackAttribution() {
        guard !UserDefaults.standard.bool(forKey: sentKey) else { return }
        Task.detached(priority: .background) {
            do {
                if #available(iOS 14.3, *) {
                    let token = try AAAttribution.attributionToken()
                    try await Self.postToApple(token: token)
                    UserDefaults.standard.set(true, forKey: self.sentKey)
                }
            } catch {
                // Silent: surface in DEBUG only to avoid noisy prod logs.
                #if DEBUG
                print("AttributionService: \(error)")
                #endif
            }
        }
    }

    private static func postToApple(token: String) async throws {
        var req = URLRequest(url: URL(string: "https://api-adservices.apple.com/api/v1/")!)
        req.httpMethod = "POST"
        req.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        req.httpBody = token.data(using: .utf8)
        _ = try await URLSession.shared.data(for: req)
    }
}
