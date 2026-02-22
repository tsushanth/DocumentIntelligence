import Foundation

/// Generates shareable HTML invoices for the Client Portal feature
final class ClientPortalGenerator {

    static let shared = ClientPortalGenerator()

    private init() {}

    /// Generate a shareable HTML invoice
    func generateHTML(for invoice: Invoice, businessInfo: BusinessInfo) -> String {
        let primaryColor = "#22c55e" // Green
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

        let paymentDetailsHTML = generatePaymentDetailsHTML(paymentDetails: businessInfo.paymentDetails, invoice: invoice)

        let statusBadge = generateStatusBadgeHTML(status: invoice.status)

        let discountHTML = invoice.discountAmount > 0 ? """
            <tr>
                <td colspan="3" style="text-align: right; padding: 8px 0; color: \(mutedColor);">Discount:</td>
                <td style="text-align: right; padding: 8px 0; color: #ef4444;">-\(invoice.formattedDiscount)</td>
            </tr>
            """ : ""

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Invoice \(invoice.invoiceNumber)</title>
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
                    background-color: \(bgColor);
                    color: \(textColor);
                    line-height: 1.5;
                }
                .container {
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 40px 20px;
                }
                .invoice-card {
                    background: white;
                    border-radius: 16px;
                    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
                    overflow: hidden;
                }
                .header {
                    background: linear-gradient(135deg, \(primaryColor), #16a34a);
                    color: white;
                    padding: 32px;
                }
                .header h1 {
                    font-size: 28px;
                    margin-bottom: 8px;
                }
                .header .invoice-number {
                    opacity: 0.9;
                    font-size: 16px;
                }
                .content {
                    padding: 32px;
                }
                .info-grid {
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 32px;
                    margin-bottom: 32px;
                }
                .info-section h3 {
                    color: \(mutedColor);
                    font-size: 12px;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                    margin-bottom: 8px;
                }
                .info-section p {
                    font-size: 15px;
                    margin-bottom: 4px;
                }
                .info-section .value {
                    font-weight: 600;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin-bottom: 24px;
                }
                th {
                    text-align: left;
                    padding: 12px 0;
                    border-bottom: 2px solid \(primaryColor);
                    color: \(mutedColor);
                    font-size: 12px;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                }
                th:nth-child(2), th:nth-child(3), th:nth-child(4) {
                    text-align: right;
                }
                th:nth-child(2) {
                    text-align: center;
                }
                .totals {
                    border-top: 2px solid #e5e7eb;
                    padding-top: 16px;
                }
                .total-row {
                    font-size: 24px;
                    font-weight: 700;
                    color: \(primaryColor);
                }
                .payment-section {
                    background: \(bgColor);
                    border-radius: 12px;
                    padding: 24px;
                    margin-top: 24px;
                }
                .payment-section h3 {
                    color: \(textColor);
                    font-size: 16px;
                    margin-bottom: 16px;
                }
                .pay-button {
                    display: inline-block;
                    background: \(primaryColor);
                    color: white;
                    padding: 12px 32px;
                    border-radius: 8px;
                    text-decoration: none;
                    font-weight: 600;
                    margin-right: 12px;
                    margin-bottom: 12px;
                    transition: background 0.2s;
                }
                .pay-button:hover {
                    background: #16a34a;
                }
                .pay-button.paypal {
                    background: #0070ba;
                }
                .pay-button.paypal:hover {
                    background: #005ea6;
                }
                .pay-button.venmo {
                    background: #008cff;
                }
                .bank-details {
                    background: white;
                    border-radius: 8px;
                    padding: 16px;
                    margin-top: 16px;
                }
                .bank-details h4 {
                    font-size: 14px;
                    color: \(mutedColor);
                    margin-bottom: 12px;
                }
                .bank-details p {
                    font-size: 14px;
                    margin-bottom: 4px;
                }
                .status-badge {
                    display: inline-block;
                    padding: 4px 12px;
                    border-radius: 999px;
                    font-size: 12px;
                    font-weight: 600;
                    text-transform: uppercase;
                }
                .status-draft { background: #e5e7eb; color: #374151; }
                .status-sent { background: #dbeafe; color: #1d4ed8; }
                .status-paid { background: #dcfce7; color: #16a34a; }
                .status-overdue { background: #fee2e2; color: #dc2626; }
                .status-partial { background: #fef3c7; color: #d97706; }
                .notes {
                    background: #fffbeb;
                    border-left: 4px solid #f59e0b;
                    padding: 16px;
                    border-radius: 0 8px 8px 0;
                    margin-top: 24px;
                }
                .notes h4 {
                    font-size: 14px;
                    color: #92400e;
                    margin-bottom: 8px;
                }
                .notes p {
                    color: #78350f;
                    font-size: 14px;
                }
                .footer {
                    text-align: center;
                    padding: 24px;
                    color: \(mutedColor);
                    font-size: 13px;
                }
                @media (max-width: 600px) {
                    .info-grid {
                        grid-template-columns: 1fr;
                        gap: 24px;
                    }
                    .header {
                        padding: 24px;
                    }
                    .content {
                        padding: 24px;
                    }
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="invoice-card">
                    <div class="header">
                        <h1>\(businessInfo.name.isEmpty ? "Invoice" : businessInfo.name)</h1>
                        <div class="invoice-number">Invoice \(invoice.invoiceNumber)</div>
                    </div>

                    <div class="content">
                        <div class="info-grid">
                            <div class="info-section">
                                <h3>Bill To</h3>
                                <p class="value">\(invoice.clientName)</p>
                                \(invoice.clientEmail.map { "<p>\($0)</p>" } ?? "")
                            </div>
                            <div class="info-section" style="text-align: right;">
                                <h3>Invoice Details</h3>
                                <p>Date: <span class="value">\(invoice.formattedDate)</span></p>
                                <p>Due: <span class="value">\(invoice.formattedDueDate)</span></p>
                                <p style="margin-top: 8px;">\(statusBadge)</p>
                            </div>
                        </div>

                        <table>
                            <thead>
                                <tr>
                                    <th>Description</th>
                                    <th>Qty</th>
                                    <th>Rate</th>
                                    <th>Amount</th>
                                </tr>
                            </thead>
                            <tbody>
                                \(lineItemsHTML)
                            </tbody>
                            <tfoot class="totals">
                                <tr>
                                    <td colspan="3" style="text-align: right; padding: 8px 0; color: \(mutedColor);">Subtotal:</td>
                                    <td style="text-align: right; padding: 8px 0;">\(invoice.formattedSubtotal)</td>
                                </tr>
                                \(discountHTML)
                                <tr>
                                    <td colspan="3" style="text-align: right; padding: 8px 0; color: \(mutedColor);">Tax (\(String(format: "%.1f", invoice.taxRate))%):</td>
                                    <td style="text-align: right; padding: 8px 0;">\(invoice.formattedTax)</td>
                                </tr>
                                <tr class="total-row">
                                    <td colspan="3" style="text-align: right; padding: 16px 0 8px;">Total Due:</td>
                                    <td style="text-align: right; padding: 16px 0 8px;">\(invoice.formattedBalanceDue)</td>
                                </tr>
                            </tfoot>
                        </table>

                        \(paymentDetailsHTML)

                        \(invoice.notes.map { """
                        <div class="notes">
                            <h4>Notes</h4>
                            <p>\($0)</p>
                        </div>
                        """ } ?? "")
                    </div>

                    <div class="footer">
                        <p>Thank you for your business!</p>
                        \(!businessInfo.email.isEmpty ? "<p>\(businessInfo.email)</p>" : "")
                        \(!businessInfo.phone.isEmpty ? "<p>\(businessInfo.phone)</p>" : "")
                    </div>
                </div>
            </div>
        </body>
        </html>
        """
    }

    private func generateStatusBadgeHTML(status: Invoice.Status) -> String {
        let statusClass: String
        let statusText: String

        switch status {
        case .draft:
            statusClass = "status-draft"
            statusText = "Draft"
        case .sent:
            statusClass = "status-sent"
            statusText = "Sent"
        case .paid:
            statusClass = "status-paid"
            statusText = "Paid"
        case .overdue:
            statusClass = "status-overdue"
            statusText = "Overdue"
        case .partiallyPaid:
            statusClass = "status-partial"
            statusText = "Partially Paid"
        }

        return "<span class=\"status-badge \(statusClass)\">\(statusText)</span>"
    }

    private func generatePaymentDetailsHTML(paymentDetails: PaymentDetails, invoice: Invoice) -> String {
        var payButtonsHTML = ""
        var bankDetailsHTML = ""

        // Stripe Pay Button
        if paymentDetails.showStripePayment,
           let stripeURL = paymentDetails.stripePaymentLink(amount: invoice.balanceDue, invoiceNumber: invoice.invoiceNumber, currency: invoice.currency) {
            payButtonsHTML += """
            <a href="\(stripeURL.absoluteString)" class="pay-button" target="_blank">Pay with Card</a>
            """
        }

        // PayPal Button
        if paymentDetails.showPayPal,
           let paypalURL = paymentDetails.paypalPaymentLink(amount: invoice.balanceDue, currency: invoice.currency) {
            payButtonsHTML += """
            <a href="\(paypalURL.absoluteString)" class="pay-button paypal" target="_blank">Pay with PayPal</a>
            """
        }

        // Venmo Button
        if paymentDetails.showVenmo,
           let venmoURL = paymentDetails.venmoPaymentLink(amount: invoice.balanceDue, note: "Invoice \(invoice.invoiceNumber)") {
            payButtonsHTML += """
            <a href="\(venmoURL.absoluteString)" class="pay-button venmo" target="_blank">Pay with Venmo</a>
            """
        }

        // Bank Details
        if paymentDetails.showBankDetails && !paymentDetails.bankName.isEmpty {
            bankDetailsHTML += """
            <div class="bank-details">
                <h4>Bank Transfer Details</h4>
                <p><strong>Bank:</strong> \(paymentDetails.bankName)</p>
                \(!paymentDetails.accountName.isEmpty ? "<p><strong>Account Name:</strong> \(paymentDetails.accountName)</p>" : "")
                \(!paymentDetails.accountNumber.isEmpty ? "<p><strong>Account Number:</strong> \(paymentDetails.accountNumber)</p>" : "")
                \(!paymentDetails.routingNumber.isEmpty ? "<p><strong>Routing Number:</strong> \(paymentDetails.routingNumber)</p>" : "")
                \(!paymentDetails.swiftCode.isEmpty ? "<p><strong>SWIFT:</strong> \(paymentDetails.swiftCode)</p>" : "")
                \(!paymentDetails.iban.isEmpty ? "<p><strong>IBAN:</strong> \(paymentDetails.iban)</p>" : "")
            </div>
            """
        }

        // Zelle Info
        if paymentDetails.showZelle && (!paymentDetails.zelleEmail.isEmpty || !paymentDetails.zellePhone.isEmpty) {
            bankDetailsHTML += """
            <div class="bank-details">
                <h4>Zelle Payment</h4>
                \(!paymentDetails.zelleEmail.isEmpty ? "<p><strong>Email:</strong> \(paymentDetails.zelleEmail)</p>" : "")
                \(!paymentDetails.zellePhone.isEmpty ? "<p><strong>Phone:</strong> \(paymentDetails.zellePhone)</p>" : "")
            </div>
            """
        }

        // Custom Instructions
        if paymentDetails.showCustomInstructions && !paymentDetails.customInstructions.isEmpty {
            bankDetailsHTML += """
            <div class="bank-details">
                <h4>Payment Instructions</h4>
                <p>\(paymentDetails.customInstructions.replacingOccurrences(of: "\n", with: "<br>"))</p>
            </div>
            """
        }

        if payButtonsHTML.isEmpty && bankDetailsHTML.isEmpty {
            return ""
        }

        return """
        <div class="payment-section">
            <h3>Payment Options</h3>
            \(payButtonsHTML)
            \(bankDetailsHTML)
        </div>
        """
    }

    /// Save HTML to a temporary file for sharing
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
