import Foundation

/// Exports invoice data to CSV format for accounting software
final class CSVExporter {

    static let shared = CSVExporter()

    private init() {}

    // MARK: - Invoice Export

    /// Export invoices to CSV
    func exportInvoices(_ invoices: [Invoice]) -> String {
        var csv = "Invoice Number,Client Name,Client Email,Date,Due Date,Status,Subtotal,Discount,Tax,Total,Amount Paid,Balance Due,Currency,Notes\n"

        for invoice in invoices {
            let row = [
                escapeCSV(invoice.invoiceNumber),
                escapeCSV(invoice.clientName),
                escapeCSV(invoice.clientEmail ?? ""),
                formatDate(invoice.date),
                formatDate(invoice.dueDate),
                invoice.status.rawValue,
                String(format: "%.2f", invoice.subtotal),
                String(format: "%.2f", invoice.discountAmount),
                String(format: "%.2f", invoice.tax),
                String(format: "%.2f", invoice.total),
                String(format: "%.2f", invoice.amountPaid),
                String(format: "%.2f", invoice.balanceDue),
                invoice.currency.rawValue,
                escapeCSV(invoice.notes ?? "")
            ].joined(separator: ",")

            csv += row + "\n"
        }

        return csv
    }

    /// Export invoices with line items (detailed)
    func exportInvoicesDetailed(_ invoices: [Invoice]) -> String {
        var csv = "Invoice Number,Client Name,Date,Status,Item Description,Quantity,Unit Price,Item Amount,Tax Rate,Taxable\n"

        for invoice in invoices {
            for item in invoice.lineItems {
                let row = [
                    escapeCSV(invoice.invoiceNumber),
                    escapeCSV(invoice.clientName),
                    formatDate(invoice.date),
                    invoice.status.rawValue,
                    escapeCSV(item.description),
                    String(format: "%.2f", item.quantity),
                    String(format: "%.2f", item.unitPrice),
                    String(format: "%.2f", item.amount),
                    String(format: "%.1f", item.taxRate ?? invoice.taxRate),
                    item.isTaxable ? "Yes" : "No"
                ].joined(separator: ",")

                csv += row + "\n"
            }
        }

        return csv
    }

    // MARK: - Client Export

    /// Export clients to CSV
    func exportClients(_ clients: [Client]) -> String {
        var csv = "Name,Email,Phone,Address,Created Date\n"

        for client in clients {
            let row = [
                escapeCSV(client.name),
                escapeCSV(client.email ?? ""),
                escapeCSV(client.phone ?? ""),
                escapeCSV(client.address ?? ""),
                formatDate(client.createdAt)
            ].joined(separator: ",")

            csv += row + "\n"
        }

        return csv
    }

    // MARK: - Payment Export

    /// Export payments to CSV
    func exportPayments(from invoices: [Invoice]) -> String {
        var csv = "Invoice Number,Client Name,Payment Date,Amount,Method,Notes\n"

        for invoice in invoices {
            for payment in invoice.payments {
                let row = [
                    escapeCSV(invoice.invoiceNumber),
                    escapeCSV(invoice.clientName),
                    formatDate(payment.date),
                    String(format: "%.2f", payment.amount),
                    payment.method.displayName,
                    escapeCSV(payment.notes ?? "")
                ].joined(separator: ",")

                csv += row + "\n"
            }
        }

        return csv
    }

    // MARK: - Revenue Report

    /// Export revenue summary by month
    func exportRevenueSummary(_ invoices: [Invoice]) -> String {
        var csv = "Month,Invoiced Amount,Paid Amount,Outstanding,Invoice Count\n"

        let calendar = Calendar.current
        var monthlyData: [String: (invoiced: Double, paid: Double, count: Int)] = [:]

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"

        for invoice in invoices {
            let monthKey = formatter.string(from: invoice.date)

            var data = monthlyData[monthKey] ?? (0, 0, 0)
            data.invoiced += invoice.total
            data.paid += invoice.amountPaid
            data.count += 1
            monthlyData[monthKey] = data
        }

        let sortedMonths = monthlyData.keys.sorted()

        for month in sortedMonths {
            if let data = monthlyData[month] {
                let row = [
                    month,
                    String(format: "%.2f", data.invoiced),
                    String(format: "%.2f", data.paid),
                    String(format: "%.2f", data.invoiced - data.paid),
                    String(data.count)
                ].joined(separator: ",")

                csv += row + "\n"
            }
        }

        return csv
    }

    // MARK: - All Data Export

    /// Export all data (invoices, clients, payments) to separate files in a folder
    func exportAllData() -> [(filename: String, content: String)] {
        let invoices = InvoiceStorage.loadInvoices()
        let clients = InvoiceStorage.loadClients()

        return [
            ("invoices.csv", exportInvoices(invoices)),
            ("invoices_detailed.csv", exportInvoicesDetailed(invoices)),
            ("clients.csv", exportClients(clients)),
            ("payments.csv", exportPayments(from: invoices)),
            ("revenue_summary.csv", exportRevenueSummary(invoices))
        ]
    }

    // MARK: - Save to File

    /// Save CSV content to a temporary file
    func saveToFile(content: String, filename: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to save CSV: \(error)")
            return nil
        }
    }

    /// Save all exports to a folder and return the folder URL
    func saveAllToFolder() -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let exportDir = tempDir.appendingPathComponent("InvoiceFlowAI_Export_\(formatDateForFilename(Date()))")

        do {
            try FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)

            for (filename, content) in exportAllData() {
                let fileURL = exportDir.appendingPathComponent(filename)
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
            }

            return exportDir
        } catch {
            print("Failed to create export folder: \(error)")
            return nil
        }
    }

    // MARK: - Helpers

    private func escapeCSV(_ string: String) -> String {
        var escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") || escaped.contains("\"") {
            escaped = "\"\(escaped)\""
        }
        return escaped
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func formatDateForFilename(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: date)
    }
}
