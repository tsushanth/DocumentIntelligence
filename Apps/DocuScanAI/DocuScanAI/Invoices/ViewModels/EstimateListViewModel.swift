import SwiftUI

@MainActor
class EstimateListViewModel: ObservableObject {

    @Published var estimates: [Estimate] = []
    @Published var isLoading = false

    init() {
        loadEstimates()
    }

    func loadEstimates() {
        // Will integrate with storage
    }

    func deleteEstimate(_ estimate: Estimate) {
        estimates.removeAll { $0.id == estimate.id }
    }

    func duplicateEstimate(_ estimate: Estimate) {
        var newEstimate = Estimate(
            clientName: estimate.clientName,
            clientEmail: estimate.clientEmail,
            lineItems: estimate.lineItems,
            taxRate: estimate.taxRate
        )
        newEstimate.estimateNumber = generateEstimateNumber()
        newEstimate.date = Date()
        newEstimate.status = .draft
        estimates.append(newEstimate)
    }

    private func generateEstimateNumber() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMM"
        let dateString = dateFormatter.string(from: Date())
        let count = estimates.count + 1
        return "EST-\(dateString)-\(String(format: "%03d", count))"
    }
}
