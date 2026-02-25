import SwiftUI

@MainActor
class ScanReceiptViewModel: ObservableObject {

    @Published var showScanner = false
    @Published var scannedImage: UIImage?
    @Published var isProcessing = false
    @Published var extractedExpense: ExtractedExpense?
    @Published var errorMessage: String?

    func processReceipt() async {
        guard scannedImage != nil else { return }

        isProcessing = true
        defer { isProcessing = false }

        // Simulate AI processing
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // Will integrate with OCR + AI extraction
        extractedExpense = ExtractedExpense(
            merchant: "Starbucks",
            date: Date().formatted(date: .abbreviated, time: .omitted),
            total: 12.85,
            items: [
                ExpenseItem(description: "Grande Latte", price: 5.95),
                ExpenseItem(description: "Blueberry Muffin", price: 3.45),
                ExpenseItem(description: "Tax", price: 0.75),
                ExpenseItem(description: "Tip", price: 2.70)
            ]
        )
    }

    func saveExpense() {
        // Will integrate with storage
    }

    func reset() {
        scannedImage = nil
        extractedExpense = nil
        showScanner = false
    }
}
