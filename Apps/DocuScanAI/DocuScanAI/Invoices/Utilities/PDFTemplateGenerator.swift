import SwiftUI
import PDFKit

struct PDFTemplateGenerator {

    static func generate(for invoice: Invoice) -> Data? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            context.beginPage()

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold)
            ]

            let title = "INVOICE"
            title.draw(at: CGPoint(x: 50, y: 50), withAttributes: attributes)

            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12)
            ]

            var yPosition: CGFloat = 100

            // Invoice number and date
            "\(invoice.invoiceNumber)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 20
            "Date: \(invoice.formattedDate)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 20
            "Due: \(invoice.formattedDueDate)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 40

            // Client
            "Bill To:".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold)])
            yPosition += 20
            invoice.clientName.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 40

            // Line items
            for item in invoice.lineItems {
                "\(item.description) - Qty: \(Int(item.quantity)) x \(item.formattedUnitPrice) = \(item.formattedAmount)".draw(
                    at: CGPoint(x: 50, y: yPosition),
                    withAttributes: bodyAttributes
                )
                yPosition += 25
            }

            yPosition += 20

            // Totals
            "Subtotal: \(invoice.formattedSubtotal)".draw(at: CGPoint(x: 400, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 20
            "Tax: \(invoice.formattedTax)".draw(at: CGPoint(x: 400, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 20

            let totalAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .bold)
            ]
            "Total: \(invoice.formattedTotal)".draw(at: CGPoint(x: 400, y: yPosition), withAttributes: totalAttributes)
        }

        return data
    }
}
