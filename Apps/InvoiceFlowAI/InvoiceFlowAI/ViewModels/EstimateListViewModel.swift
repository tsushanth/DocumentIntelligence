import SwiftUI

@MainActor
class EstimateListViewModel: ObservableObject {

    @Published var estimates: [Estimate] = []
    @Published var isLoading = false

    init() {
        loadEstimates()

        // Listen for updates
        NotificationCenter.default.addObserver(
            forName: .estimatesDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadEstimates()
        }

        // Also reload when invoices update (for converted status)
        NotificationCenter.default.addObserver(
            forName: .invoicesDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadEstimates()
        }
    }

    func loadEstimates() {
        estimates = InvoiceStorage.loadEstimates()
        // Check for expired estimates
        updateExpiredEstimates()
    }

    private func updateExpiredEstimates() {
        var needsUpdate = false
        var updatedEstimates = estimates

        for (index, estimate) in updatedEstimates.enumerated() {
            if estimate.isExpired && estimate.status == .sent {
                updatedEstimates[index].status = .expired
                needsUpdate = true
            }
        }

        if needsUpdate {
            InvoiceStorage.saveEstimates(updatedEstimates)
            estimates = updatedEstimates
        }
    }

    func deleteEstimate(_ estimate: Estimate) {
        InvoiceStorage.deleteEstimate(estimate)
        loadEstimates()
    }

    func duplicateEstimate(_ estimate: Estimate) -> Estimate {
        var newEstimate = estimate
        newEstimate.id = UUID()
        newEstimate.estimateNumber = InvoiceStorage.generateEstimateNumber()
        newEstimate.date = Date()
        newEstimate.validUntil = Date().addingTimeInterval(30 * 24 * 60 * 60)
        newEstimate.status = .draft
        newEstimate.pdfFileName = nil
        newEstimate.createdAt = Date()
        newEstimate.convertedToInvoiceId = nil

        InvoiceStorage.addEstimate(newEstimate)
        loadEstimates()

        return newEstimate
    }

    func updateEstimateStatus(_ estimate: Estimate, to status: Estimate.Status) {
        var updatedEstimate = estimate
        updatedEstimate.status = status
        InvoiceStorage.updateEstimate(updatedEstimate)
        loadEstimates()
    }

    func markAsAccepted(_ estimate: Estimate) {
        updateEstimateStatus(estimate, to: .accepted)
    }

    func markAsDeclined(_ estimate: Estimate) {
        updateEstimateStatus(estimate, to: .declined)
    }

    func markAsSent(_ estimate: Estimate) {
        updateEstimateStatus(estimate, to: .sent)
    }

    func convertToInvoice(_ estimate: Estimate) -> Invoice {
        // Create invoice from estimate
        var invoice = estimate.toInvoice()

        // Generate PDF
        let pdfFileName = "\(invoice.invoiceNumber).pdf"
        let pdfURL = InvoiceStorage.getInvoicesDirectory().appendingPathComponent(pdfFileName)
        invoice.pdfFileName = pdfFileName

        let businessInfo = InvoiceStorage.loadBusinessInfo()
        if let pdfData = PDFTemplateGenerator.generate(for: invoice, businessInfo: businessInfo) {
            try? pdfData.write(to: pdfURL)
        }

        // Save the invoice
        InvoiceStorage.addInvoice(invoice)

        // Update estimate status
        var updatedEstimate = estimate
        updatedEstimate.status = .converted
        updatedEstimate.convertedToInvoiceId = invoice.id
        InvoiceStorage.updateEstimate(updatedEstimate)

        // Notify
        NotificationCenter.default.post(name: .invoicesDidUpdate, object: nil)
        NotificationCenter.default.post(name: .estimatesDidUpdate, object: nil)

        loadEstimates()

        return invoice
    }

    // Filter estimates
    var draftEstimates: [Estimate] {
        estimates.filter { $0.status == .draft }
    }

    var sentEstimates: [Estimate] {
        estimates.filter { $0.status == .sent }
    }

    var acceptedEstimates: [Estimate] {
        estimates.filter { $0.status == .accepted }
    }

    var declinedEstimates: [Estimate] {
        estimates.filter { $0.status == .declined }
    }

    var expiredEstimates: [Estimate] {
        estimates.filter { $0.status == .expired }
    }

    var convertedEstimates: [Estimate] {
        estimates.filter { $0.status == .converted }
    }

    // Summary stats
    var totalPending: Double {
        estimates.filter { $0.status == .sent || $0.status == .accepted }.reduce(0) { $0 + $1.total }
    }

    var totalAcceptedThisMonth: Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!

        return estimates
            .filter { ($0.status == .accepted || $0.status == .converted) && $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.total }
    }
}
