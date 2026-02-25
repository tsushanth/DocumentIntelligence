import SwiftUI

@MainActor
class InvoiceListViewModel: ObservableObject {

    @Published var invoices: [Invoice] = []
    @Published var isLoading = false

    init() {
        loadInvoices()
    }

    func loadInvoices() {
        // Will integrate with Core Data storage
    }

    func deleteInvoice(_ invoice: Invoice) {
        invoices.removeAll { $0.id == invoice.id }
    }

    func duplicateInvoice(_ invoice: Invoice) {
        var newInvoice = Invoice(
            clientName: invoice.clientName,
            clientEmail: invoice.clientEmail,
            lineItems: invoice.lineItems,
            taxRate: invoice.taxRate
        )
        newInvoice.invoiceNumber = generateInvoiceNumber()
        newInvoice.date = Date()
        newInvoice.status = .draft
        invoices.append(newInvoice)
    }

    private func generateInvoiceNumber() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMM"
        let dateString = dateFormatter.string(from: Date())
        let count = invoices.count + 1
        return "INV-\(dateString)-\(String(format: "%03d", count))"
    }
}
