import SwiftUI

struct ExportDataView: View {

    @State private var selectedExportType: ExportType = .invoices
    @State private var isExporting = false
    @State private var exportSuccess = false

    enum ExportType: String, CaseIterable {
        case invoices = "Invoices"
        case clients = "Clients"
        case payments = "Payments"
        case allData = "All Data"
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .font(.largeTitle)
                        .foregroundColor(.purple)

                    Text("Export to CSV")
                        .font(.headline)

                    Text("Export your invoice data in CSV format, compatible with Excel, Google Sheets, and accounting software.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Export Type") {
                ForEach(ExportType.allCases, id: \.self) { type in
                    Button(action: { selectedExportType = type }) {
                        HStack {
                            Text(type.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedExportType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }

            Section {
                Button(action: exportData) {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Label("Export \(selectedExportType.rawValue)", systemImage: "square.and.arrow.up")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(isExporting)
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Export Complete", isPresented: $exportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your data has been exported successfully.")
        }
    }

    private func exportData() {
        isExporting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let exporter = CSVExporter.shared
            let invoices = InvoiceStorage.loadInvoices()
            let clients = InvoiceStorage.loadClients()

            var items: [Any] = []

            switch selectedExportType {
            case .invoices:
                let csv = exporter.exportInvoices(invoices)
                if let url = exporter.saveToFile(content: csv, filename: "invoices.csv") {
                    items.append(url)
                }
            case .clients:
                let csv = exporter.exportClients(clients)
                if let url = exporter.saveToFile(content: csv, filename: "clients.csv") {
                    items.append(url)
                }
            case .payments:
                let csv = exporter.exportPayments(from: invoices)
                if let url = exporter.saveToFile(content: csv, filename: "payments.csv") {
                    items.append(url)
                }
            case .allData:
                if let folderURL = exporter.saveAllToFolder() {
                    items.append(folderURL)
                }
            }

            isExporting = false

            if !items.isEmpty {
                let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(activityVC, animated: true)
                }
                exportSuccess = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExportDataView()
    }
}
