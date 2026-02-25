import Foundation

/// Generates shareable HTML invoices for the Client Portal feature
final class ClientPortalGenerator {

    static let shared = ClientPortalGenerator()

    private init() {}

    func generateHTML(for invoice: Invoice, businessInfo: BusinessInfo) -> String {
        let primaryColor = "#22c55e"
        let textColor = "#1f2937"
        let mutedColor = "#6b7280"
        let bgColor = "#f9fafb"

        let lineItemsHTML = invoice.lineItems.map { item in
            """
            <tr>
                <td style="padding: 12px 0; border-bottom: 1px solid #e5e7eb;">\(item.description)</td>
                <td style="padding: 12px 0; border-bottom: 1px solid #e5e7eb; text-align: center;">\(Int(item.quantity))</td>
                <td style="padding: 12px 0; border-bottom: 1px solid #e5e7eb; text-align: right;">\(item.formattedUnitPrice)</td>
                <td style="padding: 12px 0; border-bottom: 1px solid #e5e7eb; text-align: right; font-weight: 500;">\(item.formattedAmount)</td>
            </tr>
            """
        }.joined(separator: "\n")

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Invoice \(invoice.invoiceNumber)</title>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; background: \(bgColor); color: \(textColor); line-height: 1.5; }
                .container { max-width: 800px; margin: 0 auto; padding: 40px 20px; }
                .card { background: white; border-radius: 16px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); overflow: hidden; }
                .header { background: linear-gradient(135deg, \(primaryColor), #16a34a); color: white; padding: 32px; }
                .header h1 { font-size: 28px; margin-bottom: 8px; }
                .content { padding: 32px; }
                .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 32px; margin-bottom: 32px; }
                .info-section h3 { color: \(mutedColor); font-size: 12px; text-transform: uppercase; margin-bottom: 8px; }
                table { width: 100%; border-collapse: collapse; margin-bottom: 24px; }
                th { text-align: left; padding: 12px 0; border-bottom: 2px solid \(primaryColor); color: \(mutedColor); font-size: 12px; text-transform: uppercase; }
                .total-row { font-size: 24px; font-weight: 700; color: \(primaryColor); }
                .footer { text-align: center; padding: 24px; color: \(mutedColor); font-size: 13px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="card">
                    <div class="header">
                        <h1>\(businessInfo.name.isEmpty ? "Invoice" : businessInfo.name)</h1>
                        <div>\(invoice.invoiceNumber)</div>
                    </div>
                    <div class="content">
                        <div class="info-grid">
                            <div class="info-section">
                                <h3>Bill To</h3>
                                <p><strong>\(invoice.clientName)</strong></p>
                                \(invoice.clientEmail.map { "<p>\($0)</p>" } ?? "")
                            </div>
                            <div class="info-section" style="text-align: right;">
                                <h3>Details</h3>
                                <p>Date: <strong>\(invoice.formattedDate)</strong></p>
                                <p>Due: <strong>\(invoice.formattedDueDate)</strong></p>
                            </div>
                        </div>
                        <table>
                            <thead><tr><th>Description</th><th style="text-align:center">Qty</th><th style="text-align:right">Rate</th><th style="text-align:right">Amount</th></tr></thead>
                            <tbody>\(lineItemsHTML)</tbody>
                            <tfoot>
                                <tr><td colspan="3" style="text-align:right;padding:8px 0;color:\(mutedColor)">Subtotal:</td><td style="text-align:right;padding:8px 0">\(invoice.formattedSubtotal)</td></tr>
                                <tr><td colspan="3" style="text-align:right;padding:8px 0;color:\(mutedColor)">Tax (\(String(format:"%.1f",invoice.taxRate))%):</td><td style="text-align:right;padding:8px 0">\(invoice.formattedTax)</td></tr>
                                <tr class="total-row"><td colspan="3" style="text-align:right;padding:16px 0 8px">Total:</td><td style="text-align:right;padding:16px 0 8px">\(invoice.formattedTotal)</td></tr>
                            </tfoot>
                        </table>
                        \(invoice.notes.map { "<div style='background:#fffbeb;border-left:4px solid #f59e0b;padding:16px;border-radius:0 8px 8px 0;margin-top:24px'><h4 style='color:#92400e;margin-bottom:8px'>Notes</h4><p style='color:#78350f'>\($0)</p></div>" } ?? "")
                    </div>
                    <div class="footer">
                        <p>Thank you for your business!</p>
                        \(!businessInfo.email.isEmpty ? "<p>\(businessInfo.email)</p>" : "")
                    </div>
                </div>
            </div>
        </body>
        </html>
        """
    }

    func saveHTMLToFile(html: String, invoiceNumber: String) -> URL? {
        let fileName = "Invoice-\(invoiceNumber).html"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try html.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Failed to save HTML: \(error)")
            return nil
        }
    }
}
