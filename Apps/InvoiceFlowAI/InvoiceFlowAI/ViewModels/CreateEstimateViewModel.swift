import SwiftUI
import PDFKit

@MainActor
class CreateEstimateViewModel: ObservableObject {

    @Published var selectedClient: Client?
    @Published var estimateNumber: String = ""
    @Published var date: Date = Date()
    @Published var validUntil: Date = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days
    @Published var lineItems: [LineItem] = []
    @Published var taxRate: Double = 8.0
    @Published var notes: String = ""
    @Published var isSaving = false
    @Published var errorMessage: String?

    // Discount support
    @Published var discountType: Invoice.DiscountType = .none
    @Published var discountValue: Double = 0

    // Template support
    @Published var templateStyle: Invoice.InvoiceTemplate = .modern

    // Currency support
    @Published var currency: Currency = .usd

    // For editing existing estimates
    var editingEstimate: Estimate?

    var subtotal: Double {
        lineItems.reduce(0) { $0 + $1.amount }
    }

    var discountAmount: Double {
        switch discountType {
        case .none:
            return 0
        case .percentage:
            return subtotal * (discountValue / 100)
        case .flatAmount:
            return min(discountValue, subtotal)
        }
    }

    var subtotalAfterDiscount: Double {
        subtotal - discountAmount
    }

    var tax: Double {
        subtotalAfterDiscount * (taxRate / 100)
    }

    var total: Double {
        subtotalAfterDiscount + tax
    }

    var formattedSubtotal: String {
        formatCurrency(subtotal)
    }

    var formattedDiscount: String {
        formatCurrency(discountAmount)
    }

    var formattedSubtotalAfterDiscount: String {
        formatCurrency(subtotalAfterDiscount)
    }

    var formattedTax: String {
        formatCurrency(tax)
    }

    var formattedTotal: String {
        formatCurrency(total)
    }

    var hasDiscount: Bool {
        discountType != .none && discountValue > 0
    }

    var isValid: Bool {
        selectedClient != nil && !lineItems.isEmpty
    }

    init() {
        estimateNumber = InvoiceStorage.generateEstimateNumber()
        // Load default currency from business info
        let businessInfo = InvoiceStorage.loadBusinessInfo()
        self.currency = businessInfo.defaultCurrency
    }

    init(estimate: Estimate) {
        self.editingEstimate = estimate
        self.estimateNumber = estimate.estimateNumber
        self.date = estimate.date
        self.validUntil = estimate.validUntil
        self.lineItems = estimate.lineItems
        self.taxRate = estimate.taxRate
        self.notes = estimate.notes ?? ""
        self.discountType = estimate.discountType
        self.discountValue = estimate.discountValue
        self.templateStyle = estimate.templateStyle
        self.currency = estimate.currency

        // Try to find matching client
        let clients = InvoiceStorage.loadClients()
        self.selectedClient = clients.first { $0.name == estimate.clientName }

        if selectedClient == nil {
            // Create a temporary client object
            self.selectedClient = Client(
                name: estimate.clientName,
                email: estimate.clientEmail,
                address: estimate.clientAddress
            )
        }
    }

    func addItem() {
        let newItem = LineItem(
            description: "New Item",
            quantity: 1,
            unitPrice: 0
        )
        lineItems.append(newItem)
    }

    func addItemFromTemplate(_ template: ItemTemplate) {
        let newItem = LineItem(
            description: template.itemDescription ?? template.name,
            quantity: 1,
            unitPrice: template.price
        )
        lineItems.append(newItem)
    }

    func deleteItem(at offsets: IndexSet) {
        lineItems.remove(atOffsets: offsets)
    }

    func updateItem(at index: Int, description: String, quantity: Double, unitPrice: Double) {
        guard index < lineItems.count else { return }
        lineItems[index].description = description
        lineItems[index].quantity = quantity
        lineItems[index].unitPrice = unitPrice
    }

    func createEstimate() {
        guard let client = selectedClient else { return }

        isSaving = true
        defer { isSaving = false }

        // Generate PDF
        let pdfFileName = "\(estimateNumber).pdf"
        let pdfURL = InvoiceStorage.getEstimatesDirectory().appendingPathComponent(pdfFileName)

        var estimate = Estimate(
            estimateNumber: estimateNumber,
            clientName: client.name,
            clientEmail: client.email,
            clientAddress: client.address,
            date: date,
            validUntil: validUntil,
            lineItems: lineItems,
            taxRate: taxRate,
            notes: notes.isEmpty ? nil : notes,
            status: .draft,
            pdfFileName: pdfFileName,
            discountType: discountType,
            discountValue: discountValue,
            templateStyle: templateStyle
        )
        estimate.currency = currency

        // If editing, preserve the original ID
        if let existingEstimate = editingEstimate {
            estimate.id = existingEstimate.id
            estimate.createdAt = existingEstimate.createdAt
            estimate.convertedToInvoiceId = existingEstimate.convertedToInvoiceId
        }

        // Generate and save PDF using template
        let businessInfo = InvoiceStorage.loadBusinessInfo()
        if let pdfData = PDFTemplateGenerator.generate(for: estimate, businessInfo: businessInfo) {
            try? pdfData.write(to: pdfURL)
        }

        // Save to storage
        if editingEstimate != nil {
            InvoiceStorage.updateEstimate(estimate)
        } else {
            InvoiceStorage.addEstimate(estimate)
        }

        // Notify
        NotificationCenter.default.post(name: .estimatesDidUpdate, object: nil)
    }

    private func formatCurrency(_ amount: Double) -> String {
        currency.format(amount)
    }

    /// Currency symbol for display in views
    var currencySymbol: String {
        currency.symbol
    }
}
