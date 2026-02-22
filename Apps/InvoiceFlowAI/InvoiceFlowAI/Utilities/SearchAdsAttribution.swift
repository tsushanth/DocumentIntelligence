import Foundation
import AdServices
import iAd

/// Handles Apple Search Ads attribution tracking for ASA bid optimization
@MainActor
final class SearchAdsAttribution: ObservableObject {

    static let shared = SearchAdsAttribution()

    @Published private(set) var attributionToken: String?
    @Published private(set) var attributionData: [String: Any]?
    @Published private(set) var isAttributed: Bool = false

    private let attributionTokenKey = "asa_attribution_token"
    private let attributionDataKey = "asa_attribution_data"
    private let attributionSentKey = "asa_attribution_sent"

    private init() {}

    /// Fetches attribution data on app launch
    func fetchAttribution() async {
        // Check if we've already sent attribution
        guard !UserDefaults.standard.bool(forKey: attributionSentKey) else {
            return
        }

        // First, try to get the attribution token (iOS 14.3+)
        await fetchAttributionToken()

        // Then fetch detailed attribution data using iAd framework
        await fetchAttributionDetails()

        // Send to ad-optimizer if we have attribution data
        if attributionToken != nil || attributionData != nil {
            await sendAttributionToOptimizer()
        }
    }

    /// Fetches the attribution token using AdServices (iOS 14.3+)
    private func fetchAttributionToken() async {
        guard #available(iOS 14.3, *) else { return }

        do {
            let token = try AAAttribution.attributionToken()
            self.attributionToken = token
            UserDefaults.standard.set(token, forKey: attributionTokenKey)
        } catch {
            print("SearchAdsAttribution: Failed to get attribution token: \(error.localizedDescription)")
        }
    }

    /// Fetches detailed attribution data using iAd framework
    private func fetchAttributionDetails() async {
        await withCheckedContinuation { continuation in
            ADClient.shared().requestAttributionDetails { [weak self] details, error in
                Task { @MainActor in
                    if let error = error {
                        print("SearchAdsAttribution: Failed to get attribution details: \(error.localizedDescription)")
                    } else if let details = details {
                        self?.attributionData = details
                        self?.isAttributed = true

                        // Store attribution data
                        if let data = try? JSONSerialization.data(withJSONObject: details) {
                            UserDefaults.standard.set(data, forKey: self?.attributionDataKey ?? "")
                        }
                    }
                    continuation.resume()
                }
            }
        }
    }

    /// Sends attribution data to the ad-optimizer service
    private func sendAttributionToOptimizer() async {
        guard NetworkMonitor.shared.isConnected else {
            // Queue for later if offline
            return
        }

        var payload: [String: Any] = [
            "app_id": "com.documentintelligence.invoiceflow",
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "platform": "ios"
        ]

        if let token = attributionToken {
            payload["attribution_token"] = token
        }

        if let data = attributionData {
            payload["attribution_data"] = data

            // Extract key fields for optimization
            if let iadAttribution = data["iad-attribution"] as? String {
                payload["is_attributed"] = iadAttribution == "true"
            }
            if let campaignId = data["iad-campaign-id"] as? String {
                payload["campaign_id"] = campaignId
            }
            if let campaignName = data["iad-campaign-name"] as? String {
                payload["campaign_name"] = campaignName
            }
            if let adGroupId = data["iad-adgroup-id"] as? String {
                payload["adgroup_id"] = adGroupId
            }
            if let adGroupName = data["iad-adgroup-name"] as? String {
                payload["adgroup_name"] = adGroupName
            }
            if let keyword = data["iad-keyword"] as? String {
                payload["keyword"] = keyword
            }
            if let keywordMatchType = data["iad-keyword-matchtype"] as? String {
                payload["keyword_match_type"] = keywordMatchType
            }
            if let clickDate = data["iad-click-date"] as? String {
                payload["click_date"] = clickDate
            }
            if let conversionDate = data["iad-conversion-date"] as? String {
                payload["conversion_date"] = conversionDate
            }
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload)

            // Send to ad-optimizer endpoint
            var request = URLRequest(url: URL(string: "https://api.documentintelligence.com/v1/attribution/asa")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                // Mark as sent to avoid duplicate submissions
                UserDefaults.standard.set(true, forKey: attributionSentKey)
                print("SearchAdsAttribution: Successfully sent attribution data")
            }
        } catch {
            print("SearchAdsAttribution: Failed to send attribution data: \(error.localizedDescription)")
        }
    }

    /// Retrieves stored attribution data
    func getStoredAttribution() -> [String: Any]? {
        if let data = UserDefaults.standard.data(forKey: attributionDataKey),
           let attribution = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return attribution
        }
        return nil
    }

    /// Resets attribution tracking (for testing purposes)
    func resetAttribution() {
        UserDefaults.standard.removeObject(forKey: attributionTokenKey)
        UserDefaults.standard.removeObject(forKey: attributionDataKey)
        UserDefaults.standard.removeObject(forKey: attributionSentKey)
        attributionToken = nil
        attributionData = nil
        isAttributed = false
    }
}
