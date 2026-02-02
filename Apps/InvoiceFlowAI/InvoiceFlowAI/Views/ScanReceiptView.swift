import SwiftUI
import VisionKit

struct ScanReceiptView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ScanReceiptViewModel()
    @EnvironmentObject var appState: InvoiceAppState
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.showScanner {
                    ReceiptScannerView(viewModel: viewModel)
                } else if let image = viewModel.scannedImage {
                    // Show scanned receipt with extracted data
                    ScrollView {
                        VStack(spacing: 20) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                            
                            if viewModel.isProcessing {
                                ProgressView("Extracting receipt data...")
                            } else if let expense = viewModel.extractedExpense {
                                extractedExpenseCard(expense)
                            }
                        }
                        .padding()
                    }
                } else {
                    // Initial state
                    VStack(spacing: 24) {
                        Spacer()
                        
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.orange.opacity(0.5))
                        
                        Text("Scan a Receipt")
                            .font(.title2.bold())
                        
                        Text("We'll automatically extract the expense details")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: { viewModel.showScanner = true }) {
                            Label("Start Scanning", systemImage: "camera.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                if viewModel.extractedExpense != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            viewModel.saveExpense()
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }
    
    private func extractedExpenseCard(_ expense: ExtractedExpense) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Expense Extracted")
                    .font(.headline)
            }
            
            Divider()
            
            expenseRow("Merchant", expense.merchant)
            expenseRow("Date", expense.date)
            expenseRow("Total", expense.formattedTotal)
            
            if !expense.items.isEmpty {
                Divider()
                Text("Items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(expense.items, id: \.description) { item in
                    HStack {
                        Text(item.description)
                        Spacer()
                        Text(item.formattedPrice)
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func expenseRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct ReceiptScannerView: UIViewControllerRepresentable {
    @ObservedObject var viewModel: ScanReceiptViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let viewModel: ScanReceiptViewModel
        
        init(viewModel: ScanReceiptViewModel) {
            self.viewModel = viewModel
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            Task { @MainActor in
                if scan.pageCount > 0 {
                    viewModel.scannedImage = scan.imageOfPage(at: 0)
                    viewModel.showScanner = false
                    await viewModel.processReceipt()
                }
            }
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            Task { @MainActor in
                viewModel.showScanner = false
            }
        }
    }
}

struct ExtractedExpense {
    var merchant: String
    var date: String
    var total: Double
    var items: [ExpenseItem]
    
    var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: total)) ?? "$0.00"
    }
}

struct ExpenseItem {
    var description: String
    var price: Double
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: price)) ?? "$0.00"
    }
}

#Preview {
    ScanReceiptView()
        .environmentObject(InvoiceAppState())
}
