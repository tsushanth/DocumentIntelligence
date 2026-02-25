import SwiftUI

@MainActor
class CreateInvoiceViewModel: ObservableObject {

    @Published var selectedClient: Client?
    @Published var invoiceNumber: String = ""
    @Published var date: Date = Date()
    @Published var dueDate: Date = Date().addingTimeInterval(30 * 24 * 60 * 60)
    @Published var lineItems: [LineItem] = []
    @Published var taxRate: Double = 8.0
    @Published var notes: String = ""

    var subtotal: Double {
        lineItems.reduce(0) { $0 + $1.amount }
    }

    var tax: Double {
        subtotal * (taxRate / 100)
    }

    var total: Double {
        subtotal + tax
    }

    var formattedSubtotal: String { formatCurrency(subtotal) }
    var formattedTax: String { formatCurrency(tax) }
    var formattedTotal: String { formatCurrency(total) }

    var isValid: Bool {
        selectedClient != nil && !lineItems.isEmpty
    }

    init() {
        generateInvoiceNumber()
    }

    private func generateInvoiceNumber() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMM"
        let dateString = dateFormatter.string(from: Date())
        invoiceNumber = "INV-\(dateString)-001"
    }

    func addItem() {
        let newItem = LineItem(description: "New Item", quantity: 1, unitPrice: 0)
        lineItems.append(newItem)
    }

    func deleteItem(at offsets: IndexSet) {
        lineItems.remove(atOffsets: offsets)
    }

    func createInvoice() {
        // Will integrate with storage
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}
