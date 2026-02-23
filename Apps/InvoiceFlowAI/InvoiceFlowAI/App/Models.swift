import SwiftUI
import UserNotifications

// MARK: - Invoice

struct Invoice: Identifiable {
    let id = UUID()
    var invoiceNumber: String = ""
    var clientName: String
    var clientEmail: String?
    var clientAddress: String?
    var date: Date = Date()
    var dueDate: Date = Date().addingTimeInterval(30 * 24 * 60 * 60)
    var lineItems: [LineItem]
    var taxRate: Double
    var notes: String?
    var status: Status = .draft
    var discountType: DiscountType = .none
    var discountValue: Double = 0
    var currency: Currency = .usd
    var payments: [Payment] = []

    enum Status: String {
        case draft
        case sent
        case paid
        case partiallyPaid
        case overdue

        var color: Color {
            switch self {
            case .draft: return .gray
            case .sent: return .blue
            case .paid: return .green
            case .partiallyPaid: return .orange
            case .overdue: return .red
            }
        }
    }

    var subtotal: Double {
        lineItems.reduce(0) { $0 + $1.amount }
    }

    var discountAmount: Double {
        switch discountType {
        case .none: return 0
        case .percentage: return subtotal * (discountValue / 100)
        case .flatAmount: return discountValue
        }
    }

    var tax: Double {
        (subtotal - discountAmount) * (taxRate / 100)
    }

    var total: Double {
        subtotal - discountAmount + tax
    }

    var amountPaid: Double {
        payments.reduce(0) { $0 + $1.amount }
    }

    var balanceDue: Double {
        total - amountPaid
    }

    var formattedSubtotal: String { currency.format(subtotal) }
    var formattedDiscount: String { currency.format(discountAmount) }
    var formattedTax: String { currency.format(tax) }
    var formattedTotal: String { currency.format(total) }
    var formattedDate: String { date.formatted(date: .abbreviated, time: .omitted) }
    var formattedDueDate: String { dueDate.formatted(date: .abbreviated, time: .omitted) }
    var formattedBalanceDue: String { currency.format(balanceDue) }

    private func formatCurrency(_ amount: Double) -> String {
        currency.format(amount)
    }
}

// MARK: - Payment

struct Payment: Identifiable, Codable {
    let id: UUID
    var amount: Double
    var date: Date
    var method: PaymentMethod
    var notes: String?

    init(id: UUID = UUID(), amount: Double, date: Date = Date(), method: PaymentMethod = .other, notes: String? = nil) {
        self.id = id
        self.amount = amount
        self.date = date
        self.method = method
        self.notes = notes
    }

    enum PaymentMethod: String, Codable, CaseIterable {
        case cash
        case check
        case creditCard
        case bankTransfer
        case paypal
        case venmo
        case zelle
        case stripe
        case other

        var displayName: String {
            switch self {
            case .cash: return "Cash"
            case .check: return "Check"
            case .creditCard: return "Credit Card"
            case .bankTransfer: return "Bank Transfer"
            case .paypal: return "PayPal"
            case .venmo: return "Venmo"
            case .zelle: return "Zelle"
            case .stripe: return "Stripe"
            case .other: return "Other"
            }
        }
    }
}

// MARK: - Line Item

struct LineItem: Identifiable {
    let id = UUID()
    var description: String
    var quantity: Double
    var unitPrice: Double
    var isTaxable: Bool = true
    var taxRate: Double = 0

    var amount: Double {
        quantity * unitPrice
    }

    var formattedUnitPrice: String { formatCurrency(unitPrice) }
    var formattedAmount: String { formatCurrency(amount) }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Client

struct Client: Identifiable {
    let id = UUID()
    var name: String
    var email: String?
    var phone: String?
    var address: String?
    var createdAt: Date = Date()

    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Item Template

struct ItemTemplate: Identifiable {
    let id = UUID()
    var name: String
    var itemDescription: String?
    var price: Double

    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: price)) ?? "$0.00"
    }
}

// MARK: - Estimate

struct Estimate: Identifiable {
    let id = UUID()
    var estimateNumber: String = ""
    var clientName: String
    var clientEmail: String?
    var clientAddress: String?
    var date: Date = Date()
    var validUntil: Date = Date().addingTimeInterval(30 * 24 * 60 * 60)
    var lineItems: [LineItem]
    var taxRate: Double
    var notes: String?
    var terms: String?
    var status: Status = .draft
    var discountType: Invoice.DiscountType = .percentage
    var discountValue: Double = 0
    var template: Invoice.InvoiceTemplate = .modern
    var currency: Currency = .usd

    enum Status: String, Codable, CaseIterable {
        case draft
        case sent
        case accepted
        case declined
        case expired

        var color: Color {
            switch self {
            case .draft: return .gray
            case .sent: return .blue
            case .accepted: return .green
            case .declined: return .red
            case .expired: return .orange
            }
        }

        var displayName: String {
            rawValue.capitalized
        }
    }

    var subtotal: Double {
        lineItems.reduce(0) { $0 + $1.amount }
    }

    var discount: Double {
        switch discountType {
        case .percentage:
            return subtotal * (discountValue / 100)
        case .fixed:
            return discountValue
        }
    }

    var tax: Double {
        (subtotal - discount) * (taxRate / 100)
    }

    var total: Double {
        subtotal - discount + tax
    }

    var formattedSubtotal: String { currency.format(subtotal) }
    var formattedDiscount: String { currency.format(discount) }
    var formattedTax: String { currency.format(tax) }
    var formattedTotal: String { currency.format(total) }
    var formattedDate: String { date.formatted(date: .abbreviated, time: .omitted) }
    var formattedValidUntil: String { validUntil.formatted(date: .abbreviated, time: .omitted) }
}

// MARK: - Invoice Extensions

extension Invoice {
    enum DiscountType: String, Codable, CaseIterable {
        case none
        case percentage
        case flatAmount

        var displayName: String {
            switch self {
            case .none: return "None"
            case .percentage: return "Percentage"
            case .flatAmount: return "Flat Amount"
            }
        }
    }

    enum InvoiceTemplate: String, Codable, CaseIterable {
        case classic
        case modern
        case minimal
        case professional

        var displayName: String {
            rawValue.capitalized
        }
    }
}

// MARK: - Currency

enum Currency: String, Codable, CaseIterable, Identifiable {
    case usd
    case eur
    case gbp
    case cad
    case aud
    case jpy
    case inr

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .cad: return "CA$"
        case .aud: return "A$"
        case .jpy: return "¥"
        case .inr: return "₹"
        }
    }

    var code: String {
        rawValue.uppercased()
    }

    var displayName: String {
        switch self {
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        case .cad: return "Canadian Dollar"
        case .aud: return "Australian Dollar"
        case .jpy: return "Japanese Yen"
        case .inr: return "Indian Rupee"
        }
    }

    func format(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.currencySymbol = symbol
        return formatter.string(from: NSNumber(value: amount)) ?? "\(symbol)0.00"
    }
}

// MARK: - Business Info

struct BusinessInfo: Codable {
    var name: String = ""
    var email: String = ""
    var phone: String = ""
    var address: String = ""
    var website: String = ""
    var taxId: String = ""
    var logo: Data? = nil
    var defaultCurrency: Currency = .usd
    var defaultLateFeeSettings: LateFeeSettings = .defaultSettings
    var paymentDetails: PaymentDetails = .empty

    static let empty = BusinessInfo()
}

// MARK: - Payment Details

struct PaymentDetails: Codable {
    var bankName: String = ""
    var accountName: String = ""
    var accountNumber: String = ""
    var routingNumber: String = ""
    var swiftCode: String = ""
    var iban: String = ""
    var paypalEmail: String = ""
    var venmoUsername: String = ""
    var zelleEmail: String = ""
    var zellePhone: String = ""
    var notes: String = ""
    var customInstructions: String = ""

    // Payment link base URLs
    var stripePaymentLinkBase: String = ""
    var paypalPaymentLinkBase: String = ""
    var venmoPaymentLinkBase: String = ""

    // Display toggles
    var showBankDetails: Bool = false
    var showPayPal: Bool = false
    var showVenmo: Bool = false
    var showZelle: Bool = false
    var showStripePayment: Bool = false
    var showCustomInstructions: Bool = false

    static let empty = PaymentDetails()

    // Payment link generators
    func stripePaymentLink(amount: Double, invoiceNumber: String, currency: Currency) -> URL? {
        guard !stripePaymentLinkBase.isEmpty else { return nil }
        let amountCents = Int(amount * 100)
        var components = URLComponents(string: stripePaymentLinkBase)
        components?.queryItems = [
            URLQueryItem(name: "amount", value: String(amountCents)),
            URLQueryItem(name: "currency", value: currency.code.lowercased()),
            URLQueryItem(name: "invoice", value: invoiceNumber)
        ]
        return components?.url
    }

    func paypalPaymentLink(amount: Double, currency: Currency) -> URL? {
        guard !paypalEmail.isEmpty else { return nil }
        var components = URLComponents(string: "https://www.paypal.com/paypalme/\(paypalEmail)")
        components?.queryItems = [
            URLQueryItem(name: "amount", value: String(format: "%.2f", amount)),
            URLQueryItem(name: "currencyCode", value: currency.code)
        ]
        return components?.url
    }

    func venmoPaymentLink(amount: Double, note: String) -> URL? {
        guard !venmoUsername.isEmpty else { return nil }
        let encodedNote = note.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? note
        return URL(string: "venmo://paycharge?txn=pay&recipients=\(venmoUsername)&amount=\(String(format: "%.2f", amount))&note=\(encodedNote)")
    }
}

// MARK: - Invoice Number Settings

struct InvoiceNumberSettings: Codable {
    var prefix: String = "INV-"
    var startNumber: Int = 1
    var currentNumber: Int = 1
    var padDigits: Int = 4

    var nextNumber: String {
        let paddedNumber = String(format: "%0\(padDigits)d", currentNumber)
        return "\(prefix)\(paddedNumber)"
    }

    mutating func increment() {
        currentNumber += 1
    }

    static let defaultSettings = InvoiceNumberSettings()
}

// MARK: - Recurring Invoice

struct RecurringInvoice: Identifiable, Codable {
    let id: UUID
    var templateInvoice: RecurringInvoiceTemplate
    var frequency: Frequency
    var startDate: Date
    var endDate: Date?
    var nextInvoiceDate: Date
    var isActive: Bool

    init(id: UUID = UUID(), templateInvoice: RecurringInvoiceTemplate, frequency: Frequency, startDate: Date, endDate: Date? = nil) {
        self.id = id
        self.templateInvoice = templateInvoice
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
        self.nextInvoiceDate = startDate
        self.isActive = true
    }

    enum Frequency: String, Codable, CaseIterable {
        case weekly
        case biweekly
        case monthly
        case quarterly
        case yearly

        var displayName: String {
            switch self {
            case .weekly: return "Weekly"
            case .biweekly: return "Bi-weekly"
            case .monthly: return "Monthly"
            case .quarterly: return "Quarterly"
            case .yearly: return "Yearly"
            }
        }

        var calendarComponent: Calendar.Component {
            switch self {
            case .weekly, .biweekly: return .weekOfYear
            case .monthly: return .month
            case .quarterly: return .month
            case .yearly: return .year
            }
        }

        var componentValue: Int {
            switch self {
            case .weekly: return 1
            case .biweekly: return 2
            case .monthly: return 1
            case .quarterly: return 3
            case .yearly: return 1
            }
        }
    }
}

struct RecurringInvoiceTemplate: Codable {
    var clientName: String
    var clientEmail: String?
    var lineItems: [RecurringLineItem]
    var taxRate: Double
    var notes: String?
}

struct RecurringLineItem: Codable {
    var description: String
    var quantity: Double
    var unitPrice: Double

    var amount: Double {
        quantity * unitPrice
    }
}

// MARK: - Late Fee Settings

struct LateFeeSettings: Codable {
    var enabled: Bool = false
    var feeType: FeeType = .percentage
    var feeAmount: Double = 0
    var gracePeriodDays: Int = 0
    var maxLateFee: Double? = nil

    enum FeeType: String, Codable, CaseIterable {
        case percentage
        case flatFee
        case dailyPercentage
        case dailyFlat

        var displayName: String {
            switch self {
            case .percentage: return "Percentage"
            case .flatFee: return "Flat Fee"
            case .dailyPercentage: return "Daily Percentage"
            case .dailyFlat: return "Daily Flat Fee"
            }
        }

        var description: String {
            switch self {
            case .percentage: return "A one-time percentage of the invoice total"
            case .flatFee: return "A one-time flat fee amount"
            case .dailyPercentage: return "A percentage charged for each day the invoice is late"
            case .dailyFlat: return "A flat fee charged for each day the invoice is late"
            }
        }
    }

    static let defaultSettings = LateFeeSettings()
}

// MARK: - Invoice Storage

@MainActor
final class InvoiceStorage: ObservableObject {
    static let shared = InvoiceStorage()

    @Published var invoices: [Invoice] = []
    @Published var estimates: [Estimate] = []
    @Published var clients: [Client] = []
    @Published var items: [ItemTemplate] = []
    @Published var recurringInvoices: [RecurringInvoice] = []

    @Published var businessInfo: BusinessInfo = .empty
    @Published var paymentDetails: PaymentDetails = .empty
    @Published var invoiceNumberSettings: InvoiceNumberSettings = .defaultSettings
    @Published var lateFeeSettings: LateFeeSettings = .defaultSettings
    @Published var defaultCurrency: Currency = .usd

    private init() {
        loadData()
    }

    func saveData() {
        // Persistence implementation
    }

    func loadData() {
        // Load from UserDefaults or CoreData
    }

    func generateInvoiceNumber() -> String {
        let number = invoiceNumberSettings.nextNumber
        invoiceNumberSettings.increment()
        saveData()
        return number
    }

    static func loadBusinessInfo() -> BusinessInfo {
        return shared.businessInfo
    }

    static func loadInvoices() -> [Invoice] {
        return shared.invoices
    }

    static func loadClients() -> [Client] {
        return shared.clients
    }
}

// MARK: - Notification Manager

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized: Bool = false
    @Published var pendingNotifications: Int = 0

    private init() {
        checkAuthorization()
    }

    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            return false
        }
    }

    func schedulePaymentReminder(for invoice: Invoice) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Payment Reminder"
        content.body = "Invoice \(invoice.invoiceNumber) for \(invoice.clientName) is due soon."
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: invoice.dueDate.addingTimeInterval(-24 * 60 * 60))
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: invoice.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotification(for invoiceId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [invoiceId.uuidString])
    }
}
