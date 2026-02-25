import Foundation
import FirebaseCore
import FirebaseAnalytics

/// Manages Firebase Analytics for event tracking and Google Ads attribution
@MainActor
final class FirebaseAnalyticsManager {

    static let shared = FirebaseAnalyticsManager()

    private var isConfigured = false

    private init() {}

    /// Configures Firebase - call once at app launch
    func configure() {
        guard !isConfigured else { return }

        FirebaseApp.configure()
        isConfigured = true

        // Set default parameters
        Analytics.setAnalyticsCollectionEnabled(true)
    }

    /// Sets the user ID for analytics tracking
    func setUserId(_ userId: String?) {
        Analytics.setUserID(userId)
    }

    /// Sets a user property
    func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }

    // MARK: - Screen Tracking

    /// Logs a screen view event
    func logScreenView(screenName: String, screenClass: String? = nil) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass ?? screenName
        ])
    }

    // MARK: - Invoice Events

    /// Logs when an invoice is created
    func logInvoiceCreated(invoiceId: String, amount: Double, currency: String = "USD") {
        Analytics.logEvent("invoice_created", parameters: [
            "invoice_id": invoiceId,
            "amount": amount,
            "currency": currency
        ])
    }

    /// Logs when an invoice is sent
    func logInvoiceSent(invoiceId: String, method: String) {
        Analytics.logEvent("invoice_sent", parameters: [
            "invoice_id": invoiceId,
            "send_method": method
        ])
    }

    /// Logs when an invoice is paid
    func logInvoicePaid(invoiceId: String, amount: Double, currency: String = "USD") {
        Analytics.logEvent("invoice_paid", parameters: [
            "invoice_id": invoiceId,
            "amount": amount,
            "currency": currency
        ])
    }

    // MARK: - Estimate Events

    /// Logs when an estimate is created
    func logEstimateCreated(estimateId: String, amount: Double) {
        Analytics.logEvent("estimate_created", parameters: [
            "estimate_id": estimateId,
            "amount": amount
        ])
    }

    /// Logs when an estimate is converted to invoice
    func logEstimateConverted(estimateId: String, invoiceId: String) {
        Analytics.logEvent("estimate_converted", parameters: [
            "estimate_id": estimateId,
            "invoice_id": invoiceId
        ])
    }

    // MARK: - Client Events

    /// Logs when a client is added
    func logClientAdded(clientId: String) {
        Analytics.logEvent("client_added", parameters: [
            "client_id": clientId
        ])
    }

    // MARK: - Feature Usage Events

    /// Logs when receipt scanning is used
    func logReceiptScanned(success: Bool) {
        Analytics.logEvent("receipt_scanned", parameters: [
            "success": success
        ])
    }

    /// Logs when voice-to-invoice is used
    func logVoiceToInvoiceUsed(success: Bool) {
        Analytics.logEvent("voice_to_invoice_used", parameters: [
            "success": success
        ])
    }

    /// Logs when PDF is exported
    func logPDFExported(templateName: String) {
        Analytics.logEvent("pdf_exported", parameters: [
            "template": templateName
        ])
    }

    /// Logs when data is exported
    func logDataExported(format: String, count: Int) {
        Analytics.logEvent("data_exported", parameters: [
            "format": format,
            "item_count": count
        ])
    }

    // MARK: - Subscription Events

    /// Logs when paywall is shown
    func logPaywallShown(source: String) {
        Analytics.logEvent("paywall_shown", parameters: [
            "source": source
        ])
    }

    /// Logs subscription start
    func logSubscriptionStarted(productId: String, price: Double) {
        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterItemID: productId,
            AnalyticsParameterPrice: price,
            AnalyticsParameterCurrency: "USD"
        ])
    }

    // MARK: - Generic Event Logging

    /// Logs a custom event with optional parameters
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }
}
