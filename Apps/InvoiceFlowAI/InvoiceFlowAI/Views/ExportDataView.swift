import SwiftUI

struct ExportDataView: View {

    @State private var selectedExportType: ExportType = .invoices
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var isExporting = false
    @State private var exportSuccess = false

    enum ExportType: String, CaseIterable {
        case invoices = "Invoices"
        case invoicesDetailed = "Invoices (Detailed)"
        case clients = "Clients"
        case payments = "Payments"
        case revenueSummary = "Revenue Summary"
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

                    Text("Export your invoice data in CSV format, compatible with Excel, Google Sheets, QuickBooks, and other accounting software.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Export Type") {
                ForEach(ExportType.allCases, id: \.self) { type in
                    Button(action: { selectedExportType = type }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.rawValue)
                                    .foregroundColor(.primary)
                                Text(descriptionFor(type))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedExportType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }

            Section("Preview") {
                previewContent
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
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: shareItems)
        }
        .alert("Export Complete", isPresented: $exportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your data has been exported successfully.")
        }
    }

    private func descriptionFor(_ type: ExportType) -> String {
        switch type {
        case .invoices:
            return "Invoice summary with totals"
        case .invoicesDetailed:
            return "Line-by-line item breakdown"
        case .clients:
            return "Client contact information"
        case .payments:
            return "All recorded payments"
        case .revenueSummary:
            return "Monthly revenue breakdown"
        case .allData:
            return "Export everything as multiple files"
        }
    }

    @ViewBuilder
    private var previewContent: some View {
        let invoices = InvoiceStorage.loadInvoices()
        let clients = InvoiceStorage.loadClients()
        let payments = invoices.flatMap { $0.payments }

        switch selectedExportType {
        case .invoices, .invoicesDetailed:
            HStack {
                Text("Total Invoices")
                Spacer()
                Text("\(invoices.count)")
                    .foregroundColor(.secondary)
            }
        case .clients:
            HStack {
                Text("Total Clients")
                Spacer()
                Text("\(clients.count)")
                    .foregroundColor(.secondary)
            }
        case .payments:
            HStack {
                Text("Total Payments")
                Spacer()
                Text("\(payments.count)")
                    .foregroundColor(.secondary)
            }
        case .revenueSummary:
            let months = Set(invoices.map { monthKey(from: $0.date) }).count
            HStack {
                Text("Months with Data")
                Spacer()
                Text("\(months)")
                    .foregroundColor(.secondary)
            }
        case .allData:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Files to Export")
                        .fontWeight(.medium)
                    Spacer()
                    Text("5")
                        .foregroundColor(.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("• invoices.csv")
                    Text("• invoices_detailed.csv")
                    Text("• clients.csv")
                    Text("• payments.csv")
                    Text("• revenue_summary.csv")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }

    private func monthKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
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
            case .invoicesDetailed:
                let csv = exporter.exportInvoicesDetailed(invoices)
                if let url = exporter.saveToFile(content: csv, filename: "invoices_detailed.csv") {
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
            case .revenueSummary:
                let csv = exporter.exportRevenueSummary(invoices)
                if let url = exporter.saveToFile(content: csv, filename: "revenue_summary.csv") {
                    items.append(url)
                }
            case .allData:
                if let folderURL = exporter.saveAllToFolder() {
                    items.append(folderURL)
                }
            }

            isExporting = false

            if !items.isEmpty {
                shareItems = items
                showingShareSheet = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExportDataView()
    }
}
