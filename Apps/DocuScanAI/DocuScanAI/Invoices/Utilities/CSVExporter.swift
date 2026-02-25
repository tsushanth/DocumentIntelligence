import SwiftUI

struct CSVExporter {

    static func exportInvoices(_ invoices: [Invoice]) -> String {
        var csv = "Invoice Number,Client,Date,Due Date,Status,Subtotal,Tax,Total\n"

        for invoice in invoices {
            csv += "\(invoice.invoiceNumber),\(invoice.clientName),\(invoice.formattedDate),\(invoice.formattedDueDate),\(invoice.status.rawValue),\(invoice.subtotal),\(invoice.tax),\(invoice.total)\n"
        }

        return csv
    }

    static func exportClients(_ clients: [Client]) -> String {
        var csv = "Name,Email,Phone,Address\n"

        for client in clients {
            csv += "\(client.name),\(client.email ?? ""),\(client.phone ?? ""),\(client.address ?? "")\n"
        }

        return csv
    }
}
