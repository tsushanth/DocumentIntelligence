import UIKit

// MARK: - PDF Template Generator

struct PDFTemplateGenerator {

    static func generate(for invoice: Invoice, businessInfo: BusinessInfo) -> Data? {
        switch invoice.templateStyle {
        case .modern:
            return generateModernTemplate(invoice: invoice, businessInfo: businessInfo)
        case .classic:
            return generateClassicTemplate(invoice: invoice, businessInfo: businessInfo)
        case .minimal:
            return generateMinimalTemplate(invoice: invoice, businessInfo: businessInfo)
        }
    }

    // MARK: - Modern Template (Green accent, right-aligned header)

    private static func generateModernTemplate(invoice: Invoice, businessInfo: BusinessInfo) -> Data? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            context.beginPage()

            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let headerFont = UIFont.boldSystemFont(ofSize: 14)
            let bodyFont = UIFont.systemFont(ofSize: 12)
            let smallFont = UIFont.systemFont(ofSize: 10)
            let accentColor = UIColor.systemGreen

            var yPosition: CGFloat = 50
            var textXOffset: CGFloat = 50

            // Business Logo
            if let logoData = businessInfo.logoData,
               let logoImage = UIImage(data: logoData) {
                let logoMaxHeight: CGFloat = 60
                let logoMaxWidth: CGFloat = 120
                let logoAspect = logoImage.size.width / logoImage.size.height
                let logoHeight = min(logoMaxHeight, logoImage.size.height)
                let logoWidth = min(logoMaxWidth, logoHeight * logoAspect)
                let logoRect = CGRect(x: 50, y: yPosition, width: logoWidth, height: logoHeight)
                logoImage.draw(in: logoRect)
                textXOffset = 50 + logoWidth + 15
            }

            // Business Name
            let businessName = businessInfo.name.isEmpty ? "Your Business Name" : businessInfo.name
            let businessNameAttr: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.black]
            businessName.draw(at: CGPoint(x: textXOffset, y: yPosition), withAttributes: businessNameAttr)
            yPosition += 35

            // Business Details
            let smallAttr: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: UIColor.gray]
            if !businessInfo.address.isEmpty {
                businessInfo.address.draw(at: CGPoint(x: textXOffset, y: yPosition), withAttributes: smallAttr)
                yPosition += 15
            }
            if !businessInfo.email.isEmpty {
                businessInfo.email.draw(at: CGPoint(x: textXOffset, y: yPosition), withAttributes: smallAttr)
                yPosition += 15
            }
            if !businessInfo.phone.isEmpty {
                businessInfo.phone.draw(at: CGPoint(x: textXOffset, y: yPosition), withAttributes: smallAttr)
                yPosition += 15
            }

            yPosition += 20

            // INVOICE title on right
            let invoiceTitleAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 28), .foregroundColor: accentColor]
            let titleSize = "INVOICE".size(withAttributes: invoiceTitleAttr)
            "INVOICE".draw(at: CGPoint(x: pageRect.width - 50 - titleSize.width, y: 50), withAttributes: invoiceTitleAttr)

            // Invoice details on right
            let detailsAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.darkGray]
            var rightY: CGFloat = 85
            "Invoice #: \(invoice.invoiceNumber)".draw(at: CGPoint(x: pageRect.width - 200, y: rightY), withAttributes: detailsAttr)
            rightY += 18
            "Date: \(invoice.formattedDate)".draw(at: CGPoint(x: pageRect.width - 200, y: rightY), withAttributes: detailsAttr)
            rightY += 18
            "Due: \(invoice.formattedDueDate)".draw(at: CGPoint(x: pageRect.width - 200, y: rightY), withAttributes: detailsAttr)

            yPosition = max(yPosition, rightY + 40)

            // Bill To
            let billToAttr: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: UIColor.black]
            "BILL TO".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: billToAttr)
            yPosition += 20

            let clientAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]
            invoice.clientName.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: clientAttr)
            yPosition += 16

            if let email = invoice.clientEmail {
                email.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: smallAttr)
                yPosition += 14
            }

            if let address = invoice.clientAddress {
                address.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: smallAttr)
                yPosition += 14
            }

            yPosition += 30

            // Table Header with accent color
            accentColor.withAlphaComponent(0.1).setFill()
            let headerRect = CGRect(x: 50, y: yPosition, width: pageRect.width - 100, height: 25)
            UIBezierPath(rect: headerRect).fill()

            let tableHeaderAttr: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: UIColor.black]
            "Description".draw(at: CGPoint(x: 55, y: yPosition + 5), withAttributes: tableHeaderAttr)
            "Qty".draw(at: CGPoint(x: 350, y: yPosition + 5), withAttributes: tableHeaderAttr)
            "Price".draw(at: CGPoint(x: 410, y: yPosition + 5), withAttributes: tableHeaderAttr)
            "Amount".draw(at: CGPoint(x: 490, y: yPosition + 5), withAttributes: tableHeaderAttr)
            yPosition += 30

            // Line Items
            let itemAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]
            for item in invoice.lineItems {
                item.description.draw(at: CGPoint(x: 55, y: yPosition), withAttributes: itemAttr)
                "\(Int(item.quantity))".draw(at: CGPoint(x: 355, y: yPosition), withAttributes: itemAttr)
                item.formattedUnitPrice(in: invoice.currency).draw(at: CGPoint(x: 410, y: yPosition), withAttributes: itemAttr)
                item.formattedAmount(in: invoice.currency).draw(at: CGPoint(x: 490, y: yPosition), withAttributes: itemAttr)
                yPosition += 22
            }

            yPosition += 20

            // Divider
            UIColor.gray.setStroke()
            let dividerPath = UIBezierPath()
            dividerPath.move(to: CGPoint(x: 350, y: yPosition))
            dividerPath.addLine(to: CGPoint(x: pageRect.width - 50, y: yPosition))
            dividerPath.stroke()
            yPosition += 15

            // Totals
            drawTotals(invoice: invoice, pageRect: pageRect, yPosition: &yPosition, bodyFont: bodyFont, headerFont: headerFont)

            // Notes
            drawNotes(invoice: invoice, pageRect: pageRect, yPosition: &yPosition, headerFont: headerFont, smallFont: smallFont)

            // Payment Details
            drawPaymentDetails(businessInfo: businessInfo, invoice: invoice, pageRect: pageRect, yPosition: &yPosition, headerFont: headerFont, bodyFont: bodyFont, smallFont: smallFont)

            // Signature
            drawSignature(businessInfo: businessInfo, pageRect: pageRect, yPosition: &yPosition, smallFont: smallFont)

            // Footer
            drawFooter(pageRect: pageRect, smallFont: smallFont)
        }
    }

    // MARK: - Classic Template (Blue accent, centered header)

    private static func generateClassicTemplate(invoice: Invoice, businessInfo: BusinessInfo) -> Data? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            context.beginPage()

            let titleFont = UIFont.boldSystemFont(ofSize: 28)
            let headerFont = UIFont.boldSystemFont(ofSize: 14)
            let bodyFont = UIFont.systemFont(ofSize: 12)
            let smallFont = UIFont.systemFont(ofSize: 10)
            let accentColor = UIColor.systemBlue

            var yPosition: CGFloat = 40

            // Top blue bar
            accentColor.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: pageRect.width, height: 8)).fill()

            // Centered INVOICE title
            let invoiceTitleAttr: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: accentColor]
            let titleSize = "INVOICE".size(withAttributes: invoiceTitleAttr)
            "INVOICE".draw(at: CGPoint(x: (pageRect.width - titleSize.width) / 2, y: yPosition), withAttributes: invoiceTitleAttr)
            yPosition += 45

            // Invoice number centered below
            let invoiceNumAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.darkGray]
            let numText = "Invoice #: \(invoice.invoiceNumber)"
            let numSize = numText.size(withAttributes: invoiceNumAttr)
            numText.draw(at: CGPoint(x: (pageRect.width - numSize.width) / 2, y: yPosition), withAttributes: invoiceNumAttr)
            yPosition += 30

            // Two-column layout: From (left) and To (right)
            let columnWidth = (pageRect.width - 150) / 2

            // FROM section
            let sectionHeaderAttr: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: accentColor]
            "FROM".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionHeaderAttr)

            // TO section
            "BILL TO".draw(at: CGPoint(x: 50 + columnWidth + 50, y: yPosition), withAttributes: sectionHeaderAttr)
            yPosition += 20

            let detailAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]
            let smallAttr: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: UIColor.gray]

            // Business info (left)
            var leftY = yPosition
            let businessName = businessInfo.name.isEmpty ? "Your Business" : businessInfo.name
            businessName.draw(at: CGPoint(x: 50, y: leftY), withAttributes: detailAttr)
            leftY += 16
            if !businessInfo.address.isEmpty {
                businessInfo.address.draw(at: CGPoint(x: 50, y: leftY), withAttributes: smallAttr)
                leftY += 14
            }
            if !businessInfo.email.isEmpty {
                businessInfo.email.draw(at: CGPoint(x: 50, y: leftY), withAttributes: smallAttr)
                leftY += 14
            }

            // Client info (right)
            var rightY = yPosition
            invoice.clientName.draw(at: CGPoint(x: 50 + columnWidth + 50, y: rightY), withAttributes: detailAttr)
            rightY += 16
            if let email = invoice.clientEmail {
                email.draw(at: CGPoint(x: 50 + columnWidth + 50, y: rightY), withAttributes: smallAttr)
                rightY += 14
            }

            yPosition = max(leftY, rightY) + 20

            // Dates section
            let dateBoxY = yPosition
            let dateBoxWidth: CGFloat = 150
            UIColor.systemGray6.setFill()
            UIBezierPath(rect: CGRect(x: pageRect.width - 50 - dateBoxWidth, y: dateBoxY, width: dateBoxWidth, height: 60)).fill()

            let dateLabelAttr: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: UIColor.gray]
            let dateValueAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]
            "Invoice Date:".draw(at: CGPoint(x: pageRect.width - 45 - dateBoxWidth, y: dateBoxY + 8), withAttributes: dateLabelAttr)
            invoice.formattedDate.draw(at: CGPoint(x: pageRect.width - 45 - dateBoxWidth, y: dateBoxY + 22), withAttributes: dateValueAttr)
            "Due Date:".draw(at: CGPoint(x: pageRect.width - 45 - dateBoxWidth, y: dateBoxY + 38), withAttributes: dateLabelAttr)
            invoice.formattedDueDate.draw(at: CGPoint(x: pageRect.width - 45 - dateBoxWidth, y: dateBoxY + 52), withAttributes: dateValueAttr)

            // Logo on top right if available
            if let logoData = businessInfo.logoData,
               let logoImage = UIImage(data: logoData) {
                let logoMaxHeight: CGFloat = 50
                let logoMaxWidth: CGFloat = 100
                let logoAspect = logoImage.size.width / logoImage.size.height
                let logoHeight = min(logoMaxHeight, logoImage.size.height)
                let logoWidth = min(logoMaxWidth, logoHeight * logoAspect)
                let logoRect = CGRect(x: pageRect.width - 50 - logoWidth, y: 40, width: logoWidth, height: logoHeight)
                logoImage.draw(in: logoRect)
            }

            yPosition = dateBoxY + 80

            // Table with borders
            accentColor.setFill()
            UIBezierPath(rect: CGRect(x: 50, y: yPosition, width: pageRect.width - 100, height: 28)).fill()

            let tableHeaderAttr: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: UIColor.white]
            "Description".draw(at: CGPoint(x: 55, y: yPosition + 7), withAttributes: tableHeaderAttr)
            "Qty".draw(at: CGPoint(x: 350, y: yPosition + 7), withAttributes: tableHeaderAttr)
            "Price".draw(at: CGPoint(x: 410, y: yPosition + 7), withAttributes: tableHeaderAttr)
            "Amount".draw(at: CGPoint(x: 490, y: yPosition + 7), withAttributes: tableHeaderAttr)
            yPosition += 32

            // Line Items with alternating rows
            let itemAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]
            for (index, item) in invoice.lineItems.enumerated() {
                if index % 2 == 0 {
                    UIColor.systemGray6.setFill()
                    UIBezierPath(rect: CGRect(x: 50, y: yPosition - 2, width: pageRect.width - 100, height: 22)).fill()
                }
                item.description.draw(at: CGPoint(x: 55, y: yPosition), withAttributes: itemAttr)
                "\(Int(item.quantity))".draw(at: CGPoint(x: 355, y: yPosition), withAttributes: itemAttr)
                item.formattedUnitPrice(in: invoice.currency).draw(at: CGPoint(x: 410, y: yPosition), withAttributes: itemAttr)
                item.formattedAmount(in: invoice.currency).draw(at: CGPoint(x: 490, y: yPosition), withAttributes: itemAttr)
                yPosition += 24
            }

            yPosition += 20

            // Totals
            drawTotals(invoice: invoice, pageRect: pageRect, yPosition: &yPosition, bodyFont: bodyFont, headerFont: headerFont)

            // Notes
            drawNotes(invoice: invoice, pageRect: pageRect, yPosition: &yPosition, headerFont: headerFont, smallFont: smallFont)

            // Payment Details
            drawPaymentDetails(businessInfo: businessInfo, invoice: invoice, pageRect: pageRect, yPosition: &yPosition, headerFont: headerFont, bodyFont: bodyFont, smallFont: smallFont)

            // Signature
            drawSignature(businessInfo: businessInfo, pageRect: pageRect, yPosition: &yPosition, smallFont: smallFont)

            // Footer with blue bar
            accentColor.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: pageRect.height - 30, width: pageRect.width, height: 8)).fill()

            let footerAttr: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: UIColor.gray]
            let footerText = "Thank you for your business!"
            let footerSize = footerText.size(withAttributes: footerAttr)
            footerText.draw(at: CGPoint(x: (pageRect.width - footerSize.width) / 2, y: pageRect.height - 50), withAttributes: footerAttr)
        }
    }

    // MARK: - Minimal Template (Clean, lots of whitespace)

    private static func generateMinimalTemplate(invoice: Invoice, businessInfo: BusinessInfo) -> Data? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            context.beginPage()

            let titleFont = UIFont.systemFont(ofSize: 32, weight: .light)
            let headerFont = UIFont.systemFont(ofSize: 11, weight: .medium)
            let bodyFont = UIFont.systemFont(ofSize: 11, weight: .regular)
            let smallFont = UIFont.systemFont(ofSize: 9, weight: .regular)

            var yPosition: CGFloat = 60

            // Business Logo (if available) centered at top
            if let logoData = businessInfo.logoData,
               let logoImage = UIImage(data: logoData) {
                let logoMaxHeight: CGFloat = 50
                let logoMaxWidth: CGFloat = 150
                let logoAspect = logoImage.size.width / logoImage.size.height
                let logoHeight = min(logoMaxHeight, logoImage.size.height)
                let logoWidth = min(logoMaxWidth, logoHeight * logoAspect)
                let logoRect = CGRect(x: (pageRect.width - logoWidth) / 2, y: yPosition, width: logoWidth, height: logoHeight)
                logoImage.draw(in: logoRect)
                yPosition += logoHeight + 20
            } else {
                // Business Name centered
                let businessName = businessInfo.name.isEmpty ? "" : businessInfo.name
                if !businessName.isEmpty {
                    let nameAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 16, weight: .medium), .foregroundColor: UIColor.black]
                    let nameSize = businessName.size(withAttributes: nameAttr)
                    businessName.draw(at: CGPoint(x: (pageRect.width - nameSize.width) / 2, y: yPosition), withAttributes: nameAttr)
                    yPosition += 25
                }
            }

            // "Invoice" title - light weight
            let titleAttr: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.black]
            let titleSize = "Invoice".size(withAttributes: titleAttr)
            "Invoice".draw(at: CGPoint(x: (pageRect.width - titleSize.width) / 2, y: yPosition), withAttributes: titleAttr)
            yPosition += 50

            // Thin line
            UIColor.lightGray.setStroke()
            let topLine = UIBezierPath()
            topLine.move(to: CGPoint(x: 80, y: yPosition))
            topLine.addLine(to: CGPoint(x: pageRect.width - 80, y: yPosition))
            topLine.lineWidth = 0.5
            topLine.stroke()
            yPosition += 30

            // Invoice details in a clean row
            let detailLabelAttr: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: UIColor.gray]
            let detailValueAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]

            // Three columns: Invoice #, Date, Due Date
            let colWidth = (pageRect.width - 160) / 3

            "INVOICE NO.".draw(at: CGPoint(x: 80, y: yPosition), withAttributes: detailLabelAttr)
            "DATE".draw(at: CGPoint(x: 80 + colWidth, y: yPosition), withAttributes: detailLabelAttr)
            "DUE DATE".draw(at: CGPoint(x: 80 + colWidth * 2, y: yPosition), withAttributes: detailLabelAttr)
            yPosition += 14

            invoice.invoiceNumber.draw(at: CGPoint(x: 80, y: yPosition), withAttributes: detailValueAttr)
            invoice.formattedDate.draw(at: CGPoint(x: 80 + colWidth, y: yPosition), withAttributes: detailValueAttr)
            invoice.formattedDueDate.draw(at: CGPoint(x: 80 + colWidth * 2, y: yPosition), withAttributes: detailValueAttr)
            yPosition += 30

            // Bill To
            "BILL TO".draw(at: CGPoint(x: 80, y: yPosition), withAttributes: detailLabelAttr)
            yPosition += 14
            invoice.clientName.draw(at: CGPoint(x: 80, y: yPosition), withAttributes: detailValueAttr)
            yPosition += 14
            if let email = invoice.clientEmail {
                email.draw(at: CGPoint(x: 80, y: yPosition), withAttributes: [.font: smallFont, .foregroundColor: UIColor.darkGray])
                yPosition += 12
            }

            yPosition += 30

            // Line separator
            UIColor.lightGray.setStroke()
            let midLine = UIBezierPath()
            midLine.move(to: CGPoint(x: 80, y: yPosition))
            midLine.addLine(to: CGPoint(x: pageRect.width - 80, y: yPosition))
            midLine.lineWidth = 0.5
            midLine.stroke()
            yPosition += 20

            // Simple table header
            let tableHeaderAttr: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: UIColor.darkGray]
            "DESCRIPTION".draw(at: CGPoint(x: 80, y: yPosition), withAttributes: tableHeaderAttr)
            "QTY".draw(at: CGPoint(x: 360, y: yPosition), withAttributes: tableHeaderAttr)
            "RATE".draw(at: CGPoint(x: 410, y: yPosition), withAttributes: tableHeaderAttr)
            "AMOUNT".draw(at: CGPoint(x: 480, y: yPosition), withAttributes: tableHeaderAttr)
            yPosition += 20

            // Items
            let itemAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]
            for item in invoice.lineItems {
                item.description.draw(at: CGPoint(x: 80, y: yPosition), withAttributes: itemAttr)
                "\(Int(item.quantity))".draw(at: CGPoint(x: 365, y: yPosition), withAttributes: itemAttr)
                item.formattedUnitPrice(in: invoice.currency).draw(at: CGPoint(x: 410, y: yPosition), withAttributes: itemAttr)
                item.formattedAmount(in: invoice.currency).draw(at: CGPoint(x: 480, y: yPosition), withAttributes: itemAttr)
                yPosition += 20
            }

            yPosition += 20

            // Bottom line
            UIColor.lightGray.setStroke()
            let bottomLine = UIBezierPath()
            bottomLine.move(to: CGPoint(x: 350, y: yPosition))
            bottomLine.addLine(to: CGPoint(x: pageRect.width - 80, y: yPosition))
            bottomLine.lineWidth = 0.5
            bottomLine.stroke()
            yPosition += 15

            // Minimal totals
            let totalsLabelAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.gray]
            let totalsValueAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]

            "Subtotal".draw(at: CGPoint(x: 400, y: yPosition), withAttributes: totalsLabelAttr)
            invoice.formattedSubtotal.draw(at: CGPoint(x: 480, y: yPosition), withAttributes: totalsValueAttr)
            yPosition += 18

            if invoice.discountType != .none && invoice.discountAmount > 0 {
                "Discount".draw(at: CGPoint(x: 400, y: yPosition), withAttributes: totalsLabelAttr)
                "-\(invoice.formattedDiscount)".draw(at: CGPoint(x: 480, y: yPosition), withAttributes: [.font: bodyFont, .foregroundColor: UIColor.systemRed])
                yPosition += 18
            }

            "Tax".draw(at: CGPoint(x: 400, y: yPosition), withAttributes: totalsLabelAttr)
            invoice.formattedTax.draw(at: CGPoint(x: 480, y: yPosition), withAttributes: totalsValueAttr)
            yPosition += 25

            // Total with emphasis
            let totalLabelAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14, weight: .medium), .foregroundColor: UIColor.black]
            "Total".draw(at: CGPoint(x: 400, y: yPosition), withAttributes: totalLabelAttr)
            invoice.formattedTotal.draw(at: CGPoint(x: 480, y: yPosition), withAttributes: totalLabelAttr)
            yPosition += 40

            // Notes
            if let notes = invoice.notes, !notes.isEmpty {
                "NOTES".draw(at: CGPoint(x: 80, y: yPosition), withAttributes: detailLabelAttr)
                yPosition += 14
                let notesAttr: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: UIColor.darkGray]
                let notesRect = CGRect(x: 80, y: yPosition, width: pageRect.width - 160, height: 80)
                notes.draw(in: notesRect, withAttributes: notesAttr)
                yPosition += 60
            }

            // Payment Details
            drawPaymentDetails(businessInfo: businessInfo, invoice: invoice, pageRect: pageRect, yPosition: &yPosition, headerFont: headerFont, bodyFont: bodyFont, smallFont: smallFont)

            // Signature
            drawSignature(businessInfo: businessInfo, pageRect: pageRect, yPosition: &yPosition, smallFont: smallFont)

            // Minimal footer
            let footerAttr: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: UIColor.lightGray]
            let footerText = "Thank you"
            let footerSize = footerText.size(withAttributes: footerAttr)
            footerText.draw(at: CGPoint(x: (pageRect.width - footerSize.width) / 2, y: pageRect.height - 50), withAttributes: footerAttr)
        }
    }

    // MARK: - Shared Helpers

    private static func drawTotals(invoice: Invoice, pageRect: CGRect, yPosition: inout CGFloat, bodyFont: UIFont, headerFont: UIFont) {
        let totalsLabelAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.darkGray]
        let totalsValueAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]
        let discountValueAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.systemRed]
        let totalBoldAttr: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: UIColor.black]

        "Subtotal:".draw(at: CGPoint(x: 400, y: yPosition), withAttributes: totalsLabelAttr)
        invoice.formattedSubtotal.draw(at: CGPoint(x: 490, y: yPosition), withAttributes: totalsValueAttr)
        yPosition += 20

        if invoice.discountType != .none && invoice.discountAmount > 0 {
            "Discount (\(invoice.discountDescription)):".draw(at: CGPoint(x: 370, y: yPosition), withAttributes: totalsLabelAttr)
            "-\(invoice.formattedDiscount)".draw(at: CGPoint(x: 490, y: yPosition), withAttributes: discountValueAttr)
            yPosition += 20
        }

        "Tax (\(String(format: "%.1f", invoice.taxRate))%):".draw(at: CGPoint(x: 400, y: yPosition), withAttributes: totalsLabelAttr)
        invoice.formattedTax.draw(at: CGPoint(x: 490, y: yPosition), withAttributes: totalsValueAttr)
        yPosition += 25

        "TOTAL:".draw(at: CGPoint(x: 400, y: yPosition), withAttributes: totalBoldAttr)
        invoice.formattedTotal.draw(at: CGPoint(x: 490, y: yPosition), withAttributes: totalBoldAttr)
        yPosition += 40
    }

    private static func drawNotes(invoice: Invoice, pageRect: CGRect, yPosition: inout CGFloat, headerFont: UIFont, smallFont: UIFont) {
        if let notes = invoice.notes, !notes.isEmpty {
            let notesHeaderAttr: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: UIColor.black]
            "Notes:".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: notesHeaderAttr)
            yPosition += 18

            let notesAttr: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: UIColor.darkGray]
            let notesRect = CGRect(x: 50, y: yPosition, width: pageRect.width - 100, height: 100)
            notes.draw(in: notesRect, withAttributes: notesAttr)
        }
    }

    private static func drawFooter(pageRect: CGRect, smallFont: UIFont) {
        let footerAttr: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: UIColor.gray]
        let footerText = "Thank you for your business!"
        let footerSize = footerText.size(withAttributes: footerAttr)
        footerText.draw(at: CGPoint(x: (pageRect.width - footerSize.width) / 2, y: pageRect.height - 50), withAttributes: footerAttr)
    }

    // MARK: - Signature Section

    private static func drawSignature(
        businessInfo: BusinessInfo,
        pageRect: CGRect,
        yPosition: inout CGFloat,
        smallFont: UIFont
    ) {
        // Only draw if signature is enabled and exists
        guard businessInfo.includeSignatureOnInvoices,
              let signatureData = businessInfo.signatureData,
              let signatureImage = UIImage(data: signatureData) else {
            return
        }

        // Check if we have enough space
        let signatureHeight: CGFloat = 60
        let sectionHeight: CGFloat = 100
        let maxY = pageRect.height - 80

        guard yPosition + sectionHeight < maxY else { return }

        yPosition += 20

        // Signature label
        let labelAttr: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: UIColor.gray]
        "Authorized Signature:".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: labelAttr)
        yPosition += 15

        // Draw signature image
        let aspectRatio = signatureImage.size.width / signatureImage.size.height
        let signatureWidth = min(signatureHeight * aspectRatio, 200)
        let signatureRect = CGRect(x: 50, y: yPosition, width: signatureWidth, height: signatureHeight)
        signatureImage.draw(in: signatureRect)

        // Draw signature line
        yPosition += signatureHeight + 5
        UIColor.gray.setStroke()
        let signatureLine = UIBezierPath()
        signatureLine.move(to: CGPoint(x: 50, y: yPosition))
        signatureLine.addLine(to: CGPoint(x: 250, y: yPosition))
        signatureLine.lineWidth = 0.5
        signatureLine.stroke()

        yPosition += 20
    }

    // MARK: - Payment Details Section

    private static func drawPaymentDetails(
        businessInfo: BusinessInfo,
        invoice: Invoice,
        pageRect: CGRect,
        yPosition: inout CGFloat,
        headerFont: UIFont,
        bodyFont: UIFont,
        smallFont: UIFont
    ) {
        let paymentDetails = businessInfo.paymentDetails

        guard paymentDetails.hasAnyPaymentMethod else { return }

        // Check if we have enough space, otherwise start conservatively
        let startY = yPosition
        let maxY = pageRect.height - 100  // Leave room for footer

        // Section header
        let sectionHeaderAttr: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: UIColor.black]
        let labelAttr: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: UIColor.gray]
        let valueAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]
        let linkAttr: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: UIColor.systemBlue]

        "PAYMENT METHODS".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionHeaderAttr)
        yPosition += 20

        // Bank Transfer
        if paymentDetails.showBankDetails {
            guard yPosition < maxY else { return }

            "Bank Transfer".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 11), .foregroundColor: UIColor.black])
            yPosition += 14

            if !paymentDetails.bankName.isEmpty {
                "Bank: \(paymentDetails.bankName)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: labelAttr)
                yPosition += 12
            }
            if !paymentDetails.accountName.isEmpty {
                "Account Name: \(paymentDetails.accountName)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: labelAttr)
                yPosition += 12
            }
            if !paymentDetails.accountNumber.isEmpty {
                "Account #: \(paymentDetails.accountNumber)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: labelAttr)
                yPosition += 12
            }
            if !paymentDetails.routingNumber.isEmpty {
                "Routing #: \(paymentDetails.routingNumber)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: labelAttr)
                yPosition += 12
            }
            if !paymentDetails.swiftCode.isEmpty {
                "SWIFT: \(paymentDetails.swiftCode)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: labelAttr)
                yPosition += 12
            }
            if !paymentDetails.iban.isEmpty {
                "IBAN: \(paymentDetails.iban)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: labelAttr)
                yPosition += 12
            }
            yPosition += 8
        }

        // PayPal
        if paymentDetails.showPayPal && (!paymentDetails.paypalEmail.isEmpty || !paymentDetails.paypalMeLink.isEmpty) {
            guard yPosition < maxY else { return }

            "PayPal".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 11), .foregroundColor: UIColor.black])
            yPosition += 14

            if !paymentDetails.paypalMeLink.isEmpty {
                let link = paymentDetails.paypalMeLink.hasPrefix("http") ? paymentDetails.paypalMeLink : "paypal.me/\(paymentDetails.paypalMeLink)"
                link.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: linkAttr)
                yPosition += 12
            } else if !paymentDetails.paypalEmail.isEmpty {
                paymentDetails.paypalEmail.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: labelAttr)
                yPosition += 12
            }
            yPosition += 8
        }

        // Venmo
        if paymentDetails.showVenmo && !paymentDetails.venmoUsername.isEmpty {
            guard yPosition < maxY else { return }

            "Venmo".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 11), .foregroundColor: UIColor.black])
            yPosition += 14
            "@\(paymentDetails.venmoUsername)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: labelAttr)
            yPosition += 20
        }

        // Zelle
        if paymentDetails.showZelle && (!paymentDetails.zelleEmail.isEmpty || !paymentDetails.zellePhone.isEmpty) {
            guard yPosition < maxY else { return }

            "Zelle".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 11), .foregroundColor: UIColor.black])
            yPosition += 14

            if !paymentDetails.zelleEmail.isEmpty {
                paymentDetails.zelleEmail.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: labelAttr)
                yPosition += 12
            }
            if !paymentDetails.zellePhone.isEmpty {
                paymentDetails.zellePhone.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: labelAttr)
                yPosition += 12
            }
            yPosition += 8
        }

        // Stripe Pay Now Button
        if paymentDetails.showStripePayment && !paymentDetails.stripePaymentLinkBase.isEmpty {
            guard yPosition < maxY - 30 else { return }

            // Draw a "Pay Now" button-like rectangle
            let buttonWidth: CGFloat = 120
            let buttonHeight: CGFloat = 30
            let buttonX = (pageRect.width - buttonWidth) / 2
            let buttonY = yPosition

            UIColor.systemIndigo.setFill()
            let buttonPath = UIBezierPath(roundedRect: CGRect(x: buttonX, y: buttonY, width: buttonWidth, height: buttonHeight), cornerRadius: 6)
            buttonPath.fill()

            let buttonTextAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: UIColor.white]
            let buttonText = "PAY NOW"
            let textSize = buttonText.size(withAttributes: buttonTextAttr)
            buttonText.draw(at: CGPoint(x: buttonX + (buttonWidth - textSize.width) / 2, y: buttonY + (buttonHeight - textSize.height) / 2), withAttributes: buttonTextAttr)

            yPosition += buttonHeight + 8

            // Show payment link below
            if let paymentURL = paymentDetails.stripePaymentLink(amount: invoice.balanceDue, invoiceNumber: invoice.invoiceNumber, currency: invoice.currency) {
                let urlString = paymentURL.absoluteString
                let truncatedURL = urlString.count > 60 ? String(urlString.prefix(60)) + "..." : urlString
                let urlAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 8), .foregroundColor: UIColor.systemBlue]
                let urlSize = truncatedURL.size(withAttributes: urlAttr)
                truncatedURL.draw(at: CGPoint(x: (pageRect.width - urlSize.width) / 2, y: yPosition), withAttributes: urlAttr)
                yPosition += 15
            }
        }

        // Custom Instructions
        if paymentDetails.showCustomInstructions && !paymentDetails.customInstructions.isEmpty {
            guard yPosition < maxY else { return }

            "Additional Payment Instructions".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 11), .foregroundColor: UIColor.black])
            yPosition += 14

            let instructionsRect = CGRect(x: 50, y: yPosition, width: pageRect.width - 100, height: 60)
            paymentDetails.customInstructions.draw(in: instructionsRect, withAttributes: labelAttr)
            yPosition += 60
        }
    }

    // MARK: - Estimate PDF Generation

    static func generate(for estimate: Estimate, businessInfo: BusinessInfo) -> Data? {
        switch estimate.templateStyle {
        case .modern:
            return generateModernEstimateTemplate(estimate: estimate, businessInfo: businessInfo)
        case .classic:
            return generateClassicEstimateTemplate(estimate: estimate, businessInfo: businessInfo)
        case .minimal:
            return generateMinimalEstimateTemplate(estimate: estimate, businessInfo: businessInfo)
        }
    }

    private static func generateModernEstimateTemplate(estimate: Estimate, businessInfo: BusinessInfo) -> Data? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            context.beginPage()

            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let headerFont = UIFont.boldSystemFont(ofSize: 14)
            let bodyFont = UIFont.systemFont(ofSize: 12)
            let smallFont = UIFont.systemFont(ofSize: 10)
            let accentColor = UIColor.systemOrange // Orange for estimates

            var yPosition: CGFloat = 50
            var textXOffset: CGFloat = 50

            // Business Logo
            if let logoData = businessInfo.logoData,
               let logoImage = UIImage(data: logoData) {
                let logoMaxHeight: CGFloat = 60
                let logoMaxWidth: CGFloat = 120
                let logoAspect = logoImage.size.width / logoImage.size.height
                let logoHeight = min(logoMaxHeight, logoImage.size.height)
                let logoWidth = min(logoMaxWidth, logoHeight * logoAspect)
                let logoRect = CGRect(x: 50, y: yPosition, width: logoWidth, height: logoHeight)
                logoImage.draw(in: logoRect)
                textXOffset = 50 + logoWidth + 15
            }

            // Business Name
            let businessName = businessInfo.name.isEmpty ? "Your Business Name" : businessInfo.name
            let businessNameAttr: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.black]
            businessName.draw(at: CGPoint(x: textXOffset, y: yPosition), withAttributes: businessNameAttr)
            yPosition += 35

            let smallAttr: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: UIColor.gray]
            if !businessInfo.address.isEmpty {
                businessInfo.address.draw(at: CGPoint(x: textXOffset, y: yPosition), withAttributes: smallAttr)
                yPosition += 15
            }
            if !businessInfo.email.isEmpty {
                businessInfo.email.draw(at: CGPoint(x: textXOffset, y: yPosition), withAttributes: smallAttr)
                yPosition += 15
            }
            if !businessInfo.phone.isEmpty {
                businessInfo.phone.draw(at: CGPoint(x: textXOffset, y: yPosition), withAttributes: smallAttr)
                yPosition += 15
            }

            yPosition += 20

            // ESTIMATE title on right
            let estimateTitleAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 28), .foregroundColor: accentColor]
            let titleSize = "ESTIMATE".size(withAttributes: estimateTitleAttr)
            "ESTIMATE".draw(at: CGPoint(x: pageRect.width - 50 - titleSize.width, y: 50), withAttributes: estimateTitleAttr)

            // Estimate details on right
            let detailsAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.darkGray]
            var rightY: CGFloat = 85
            "Estimate #: \(estimate.estimateNumber)".draw(at: CGPoint(x: pageRect.width - 200, y: rightY), withAttributes: detailsAttr)
            rightY += 18
            "Date: \(estimate.formattedDate)".draw(at: CGPoint(x: pageRect.width - 200, y: rightY), withAttributes: detailsAttr)
            rightY += 18
            "Valid Until: \(estimate.formattedValidUntil)".draw(at: CGPoint(x: pageRect.width - 200, y: rightY), withAttributes: detailsAttr)

            yPosition = max(yPosition, rightY + 40)

            // Prepared For
            let billToAttr: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: UIColor.black]
            "PREPARED FOR".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: billToAttr)
            yPosition += 20

            let clientAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]
            estimate.clientName.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: clientAttr)
            yPosition += 16

            if let email = estimate.clientEmail {
                email.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: smallAttr)
                yPosition += 14
            }

            if let address = estimate.clientAddress {
                address.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: smallAttr)
                yPosition += 14
            }

            yPosition += 30

            // Table Header
            accentColor.withAlphaComponent(0.1).setFill()
            let headerRect = CGRect(x: 50, y: yPosition, width: pageRect.width - 100, height: 25)
            UIBezierPath(rect: headerRect).fill()

            let tableHeaderAttr: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: UIColor.black]
            "Description".draw(at: CGPoint(x: 55, y: yPosition + 5), withAttributes: tableHeaderAttr)
            "Qty".draw(at: CGPoint(x: 350, y: yPosition + 5), withAttributes: tableHeaderAttr)
            "Price".draw(at: CGPoint(x: 410, y: yPosition + 5), withAttributes: tableHeaderAttr)
            "Amount".draw(at: CGPoint(x: 490, y: yPosition + 5), withAttributes: tableHeaderAttr)
            yPosition += 30

            // Line Items
            let itemAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]
            for item in estimate.lineItems {
                item.description.draw(at: CGPoint(x: 55, y: yPosition), withAttributes: itemAttr)
                "\(Int(item.quantity))".draw(at: CGPoint(x: 355, y: yPosition), withAttributes: itemAttr)
                item.formattedUnitPrice(in: estimate.currency).draw(at: CGPoint(x: 410, y: yPosition), withAttributes: itemAttr)
                item.formattedAmount(in: estimate.currency).draw(at: CGPoint(x: 490, y: yPosition), withAttributes: itemAttr)
                yPosition += 22
            }

            yPosition += 20

            // Divider
            UIColor.gray.setStroke()
            let dividerPath = UIBezierPath()
            dividerPath.move(to: CGPoint(x: 350, y: yPosition))
            dividerPath.addLine(to: CGPoint(x: pageRect.width - 50, y: yPosition))
            dividerPath.stroke()
            yPosition += 15

            // Totals
            drawEstimateTotals(estimate: estimate, pageRect: pageRect, yPosition: &yPosition, bodyFont: bodyFont, headerFont: headerFont)

            // Notes
            drawEstimateNotes(estimate: estimate, pageRect: pageRect, yPosition: &yPosition, headerFont: headerFont, smallFont: smallFont)

            // Footer
            drawEstimateFooter(pageRect: pageRect, smallFont: smallFont)
        }
    }

    private static func generateClassicEstimateTemplate(estimate: Estimate, businessInfo: BusinessInfo) -> Data? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            context.beginPage()

            let titleFont = UIFont.boldSystemFont(ofSize: 28)
            let headerFont = UIFont.boldSystemFont(ofSize: 14)
            let bodyFont = UIFont.systemFont(ofSize: 12)
            let smallFont = UIFont.systemFont(ofSize: 10)
            let accentColor = UIColor.systemOrange

            var yPosition: CGFloat = 40

            // Top orange bar
            accentColor.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: pageRect.width, height: 8)).fill()

            // Centered ESTIMATE title
            let estimateTitleAttr: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: accentColor]
            let titleSize = "ESTIMATE".size(withAttributes: estimateTitleAttr)
            "ESTIMATE".draw(at: CGPoint(x: (pageRect.width - titleSize.width) / 2, y: yPosition), withAttributes: estimateTitleAttr)
            yPosition += 45

            // Estimate number centered
            let estimateNumAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.darkGray]
            let numText = "Estimate #: \(estimate.estimateNumber)"
            let numSize = numText.size(withAttributes: estimateNumAttr)
            numText.draw(at: CGPoint(x: (pageRect.width - numSize.width) / 2, y: yPosition), withAttributes: estimateNumAttr)
            yPosition += 30

            let columnWidth = (pageRect.width - 150) / 2
            let sectionHeaderAttr: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: accentColor]
            "FROM".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionHeaderAttr)
            "PREPARED FOR".draw(at: CGPoint(x: 50 + columnWidth + 50, y: yPosition), withAttributes: sectionHeaderAttr)
            yPosition += 20

            let detailAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]
            let smallAttr: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: UIColor.gray]

            var leftY = yPosition
            let businessName = businessInfo.name.isEmpty ? "Your Business" : businessInfo.name
            businessName.draw(at: CGPoint(x: 50, y: leftY), withAttributes: detailAttr)
            leftY += 16
            if !businessInfo.address.isEmpty {
                businessInfo.address.draw(at: CGPoint(x: 50, y: leftY), withAttributes: smallAttr)
                leftY += 14
            }
            if !businessInfo.email.isEmpty {
                businessInfo.email.draw(at: CGPoint(x: 50, y: leftY), withAttributes: smallAttr)
                leftY += 14
            }

            var rightY = yPosition
            estimate.clientName.draw(at: CGPoint(x: 50 + columnWidth + 50, y: rightY), withAttributes: detailAttr)
            rightY += 16
            if let email = estimate.clientEmail {
                email.draw(at: CGPoint(x: 50 + columnWidth + 50, y: rightY), withAttributes: smallAttr)
                rightY += 14
            }

            yPosition = max(leftY, rightY) + 20

            // Date box
            let dateBoxY = yPosition
            let dateBoxWidth: CGFloat = 150
            UIColor.systemGray6.setFill()
            UIBezierPath(rect: CGRect(x: pageRect.width - 50 - dateBoxWidth, y: dateBoxY, width: dateBoxWidth, height: 60)).fill()

            let dateLabelAttr: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: UIColor.gray]
            let dateValueAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]
            "Estimate Date:".draw(at: CGPoint(x: pageRect.width - 45 - dateBoxWidth, y: dateBoxY + 8), withAttributes: dateLabelAttr)
            estimate.formattedDate.draw(at: CGPoint(x: pageRect.width - 45 - dateBoxWidth, y: dateBoxY + 22), withAttributes: dateValueAttr)
            "Valid Until:".draw(at: CGPoint(x: pageRect.width - 45 - dateBoxWidth, y: dateBoxY + 38), withAttributes: dateLabelAttr)
            estimate.formattedValidUntil.draw(at: CGPoint(x: pageRect.width - 45 - dateBoxWidth, y: dateBoxY + 52), withAttributes: dateValueAttr)

            if let logoData = businessInfo.logoData, let logoImage = UIImage(data: logoData) {
                let logoMaxHeight: CGFloat = 50
                let logoMaxWidth: CGFloat = 100
                let logoAspect = logoImage.size.width / logoImage.size.height
                let logoHeight = min(logoMaxHeight, logoImage.size.height)
                let logoWidth = min(logoMaxWidth, logoHeight * logoAspect)
                let logoRect = CGRect(x: pageRect.width - 50 - logoWidth, y: 40, width: logoWidth, height: logoHeight)
                logoImage.draw(in: logoRect)
            }

            yPosition = dateBoxY + 80

            // Table
            accentColor.setFill()
            UIBezierPath(rect: CGRect(x: 50, y: yPosition, width: pageRect.width - 100, height: 28)).fill()

            let tableHeaderAttr: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: UIColor.white]
            "Description".draw(at: CGPoint(x: 55, y: yPosition + 7), withAttributes: tableHeaderAttr)
            "Qty".draw(at: CGPoint(x: 350, y: yPosition + 7), withAttributes: tableHeaderAttr)
            "Price".draw(at: CGPoint(x: 410, y: yPosition + 7), withAttributes: tableHeaderAttr)
            "Amount".draw(at: CGPoint(x: 490, y: yPosition + 7), withAttributes: tableHeaderAttr)
            yPosition += 32

            let itemAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]
            for (index, item) in estimate.lineItems.enumerated() {
                if index % 2 == 0 {
                    UIColor.systemGray6.setFill()
                    UIBezierPath(rect: CGRect(x: 50, y: yPosition - 2, width: pageRect.width - 100, height: 22)).fill()
                }
                item.description.draw(at: CGPoint(x: 55, y: yPosition), withAttributes: itemAttr)
                "\(Int(item.quantity))".draw(at: CGPoint(x: 355, y: yPosition), withAttributes: itemAttr)
                item.formattedUnitPrice(in: estimate.currency).draw(at: CGPoint(x: 410, y: yPosition), withAttributes: itemAttr)
                item.formattedAmount(in: estimate.currency).draw(at: CGPoint(x: 490, y: yPosition), withAttributes: itemAttr)
                yPosition += 24
            }

            yPosition += 20

            drawEstimateTotals(estimate: estimate, pageRect: pageRect, yPosition: &yPosition, bodyFont: bodyFont, headerFont: headerFont)
            drawEstimateNotes(estimate: estimate, pageRect: pageRect, yPosition: &yPosition, headerFont: headerFont, smallFont: smallFont)

            accentColor.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: pageRect.height - 30, width: pageRect.width, height: 8)).fill()

            let footerAttr: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: UIColor.gray]
            let footerText = "This is an estimate, not an invoice."
            let footerSize = footerText.size(withAttributes: footerAttr)
            footerText.draw(at: CGPoint(x: (pageRect.width - footerSize.width) / 2, y: pageRect.height - 50), withAttributes: footerAttr)
        }
    }

    private static func generateMinimalEstimateTemplate(estimate: Estimate, businessInfo: BusinessInfo) -> Data? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            context.beginPage()

            let titleFont = UIFont.systemFont(ofSize: 32, weight: .light)
            let headerFont = UIFont.systemFont(ofSize: 11, weight: .medium)
            let bodyFont = UIFont.systemFont(ofSize: 11, weight: .regular)
            let smallFont = UIFont.systemFont(ofSize: 9, weight: .regular)

            var yPosition: CGFloat = 60

            if let logoData = businessInfo.logoData, let logoImage = UIImage(data: logoData) {
                let logoMaxHeight: CGFloat = 50
                let logoMaxWidth: CGFloat = 150
                let logoAspect = logoImage.size.width / logoImage.size.height
                let logoHeight = min(logoMaxHeight, logoImage.size.height)
                let logoWidth = min(logoMaxWidth, logoHeight * logoAspect)
                let logoRect = CGRect(x: (pageRect.width - logoWidth) / 2, y: yPosition, width: logoWidth, height: logoHeight)
                logoImage.draw(in: logoRect)
                yPosition += logoHeight + 20
            } else {
                let businessName = businessInfo.name.isEmpty ? "" : businessInfo.name
                if !businessName.isEmpty {
                    let nameAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 16, weight: .medium), .foregroundColor: UIColor.black]
                    let nameSize = businessName.size(withAttributes: nameAttr)
                    businessName.draw(at: CGPoint(x: (pageRect.width - nameSize.width) / 2, y: yPosition), withAttributes: nameAttr)
                    yPosition += 25
                }
            }

            let titleAttr: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.black]
            let titleSize = "Estimate".size(withAttributes: titleAttr)
            "Estimate".draw(at: CGPoint(x: (pageRect.width - titleSize.width) / 2, y: yPosition), withAttributes: titleAttr)
            yPosition += 50

            UIColor.lightGray.setStroke()
            let topLine = UIBezierPath()
            topLine.move(to: CGPoint(x: 80, y: yPosition))
            topLine.addLine(to: CGPoint(x: pageRect.width - 80, y: yPosition))
            topLine.lineWidth = 0.5
            topLine.stroke()
            yPosition += 30

            let detailLabelAttr: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: UIColor.gray]
            let detailValueAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]

            let colWidth = (pageRect.width - 160) / 3

            "ESTIMATE NO.".draw(at: CGPoint(x: 80, y: yPosition), withAttributes: detailLabelAttr)
            "DATE".draw(at: CGPoint(x: 80 + colWidth, y: yPosition), withAttributes: detailLabelAttr)
            "VALID UNTIL".draw(at: CGPoint(x: 80 + colWidth * 2, y: yPosition), withAttributes: detailLabelAttr)
            yPosition += 14

            estimate.estimateNumber.draw(at: CGPoint(x: 80, y: yPosition), withAttributes: detailValueAttr)
            estimate.formattedDate.draw(at: CGPoint(x: 80 + colWidth, y: yPosition), withAttributes: detailValueAttr)
            estimate.formattedValidUntil.draw(at: CGPoint(x: 80 + colWidth * 2, y: yPosition), withAttributes: detailValueAttr)
            yPosition += 30

            "PREPARED FOR".draw(at: CGPoint(x: 80, y: yPosition), withAttributes: detailLabelAttr)
            yPosition += 14
            estimate.clientName.draw(at: CGPoint(x: 80, y: yPosition), withAttributes: detailValueAttr)
            yPosition += 14
            if let email = estimate.clientEmail {
                email.draw(at: CGPoint(x: 80, y: yPosition), withAttributes: [.font: smallFont, .foregroundColor: UIColor.darkGray])
                yPosition += 12
            }

            yPosition += 30

            UIColor.lightGray.setStroke()
            let midLine = UIBezierPath()
            midLine.move(to: CGPoint(x: 80, y: yPosition))
            midLine.addLine(to: CGPoint(x: pageRect.width - 80, y: yPosition))
            midLine.lineWidth = 0.5
            midLine.stroke()
            yPosition += 20

            let tableHeaderAttr: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: UIColor.darkGray]
            "DESCRIPTION".draw(at: CGPoint(x: 80, y: yPosition), withAttributes: tableHeaderAttr)
            "QTY".draw(at: CGPoint(x: 360, y: yPosition), withAttributes: tableHeaderAttr)
            "RATE".draw(at: CGPoint(x: 410, y: yPosition), withAttributes: tableHeaderAttr)
            "AMOUNT".draw(at: CGPoint(x: 480, y: yPosition), withAttributes: tableHeaderAttr)
            yPosition += 20

            let itemAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]
            for item in estimate.lineItems {
                item.description.draw(at: CGPoint(x: 80, y: yPosition), withAttributes: itemAttr)
                "\(Int(item.quantity))".draw(at: CGPoint(x: 365, y: yPosition), withAttributes: itemAttr)
                item.formattedUnitPrice(in: estimate.currency).draw(at: CGPoint(x: 410, y: yPosition), withAttributes: itemAttr)
                item.formattedAmount(in: estimate.currency).draw(at: CGPoint(x: 480, y: yPosition), withAttributes: itemAttr)
                yPosition += 20
            }

            yPosition += 20

            UIColor.lightGray.setStroke()
            let bottomLine = UIBezierPath()
            bottomLine.move(to: CGPoint(x: 350, y: yPosition))
            bottomLine.addLine(to: CGPoint(x: pageRect.width - 80, y: yPosition))
            bottomLine.lineWidth = 0.5
            bottomLine.stroke()
            yPosition += 15

            let totalsLabelAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.gray]
            let totalsValueAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]

            "Subtotal".draw(at: CGPoint(x: 400, y: yPosition), withAttributes: totalsLabelAttr)
            estimate.formattedSubtotal.draw(at: CGPoint(x: 480, y: yPosition), withAttributes: totalsValueAttr)
            yPosition += 18

            if estimate.discountType != .none && estimate.discountAmount > 0 {
                "Discount".draw(at: CGPoint(x: 400, y: yPosition), withAttributes: totalsLabelAttr)
                "-\(estimate.formattedDiscount)".draw(at: CGPoint(x: 480, y: yPosition), withAttributes: [.font: bodyFont, .foregroundColor: UIColor.systemRed])
                yPosition += 18
            }

            "Tax".draw(at: CGPoint(x: 400, y: yPosition), withAttributes: totalsLabelAttr)
            estimate.formattedTax.draw(at: CGPoint(x: 480, y: yPosition), withAttributes: totalsValueAttr)
            yPosition += 25

            let totalLabelAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14, weight: .medium), .foregroundColor: UIColor.black]
            "Total".draw(at: CGPoint(x: 400, y: yPosition), withAttributes: totalLabelAttr)
            estimate.formattedTotal.draw(at: CGPoint(x: 480, y: yPosition), withAttributes: totalLabelAttr)
            yPosition += 40

            if let notes = estimate.notes, !notes.isEmpty {
                "NOTES".draw(at: CGPoint(x: 80, y: yPosition), withAttributes: detailLabelAttr)
                yPosition += 14
                let notesAttr: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: UIColor.darkGray]
                let notesRect = CGRect(x: 80, y: yPosition, width: pageRect.width - 160, height: 80)
                notes.draw(in: notesRect, withAttributes: notesAttr)
            }

            let footerAttr: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: UIColor.lightGray]
            let footerText = "This is an estimate"
            let footerSize = footerText.size(withAttributes: footerAttr)
            footerText.draw(at: CGPoint(x: (pageRect.width - footerSize.width) / 2, y: pageRect.height - 50), withAttributes: footerAttr)
        }
    }

    // MARK: - Estimate Helpers

    private static func drawEstimateTotals(estimate: Estimate, pageRect: CGRect, yPosition: inout CGFloat, bodyFont: UIFont, headerFont: UIFont) {
        let totalsLabelAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.darkGray]
        let totalsValueAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]
        let discountValueAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.systemRed]
        let totalBoldAttr: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: UIColor.black]

        "Subtotal:".draw(at: CGPoint(x: 400, y: yPosition), withAttributes: totalsLabelAttr)
        estimate.formattedSubtotal.draw(at: CGPoint(x: 490, y: yPosition), withAttributes: totalsValueAttr)
        yPosition += 20

        if estimate.discountType != .none && estimate.discountAmount > 0 {
            "Discount (\(estimate.discountDescription)):".draw(at: CGPoint(x: 370, y: yPosition), withAttributes: totalsLabelAttr)
            "-\(estimate.formattedDiscount)".draw(at: CGPoint(x: 490, y: yPosition), withAttributes: discountValueAttr)
            yPosition += 20
        }

        "Tax (\(String(format: "%.1f", estimate.taxRate))%):".draw(at: CGPoint(x: 400, y: yPosition), withAttributes: totalsLabelAttr)
        estimate.formattedTax.draw(at: CGPoint(x: 490, y: yPosition), withAttributes: totalsValueAttr)
        yPosition += 25

        "TOTAL:".draw(at: CGPoint(x: 400, y: yPosition), withAttributes: totalBoldAttr)
        estimate.formattedTotal.draw(at: CGPoint(x: 490, y: yPosition), withAttributes: totalBoldAttr)
        yPosition += 40
    }

    private static func drawEstimateNotes(estimate: Estimate, pageRect: CGRect, yPosition: inout CGFloat, headerFont: UIFont, smallFont: UIFont) {
        if let notes = estimate.notes, !notes.isEmpty {
            let notesHeaderAttr: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: UIColor.black]
            "Notes:".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: notesHeaderAttr)
            yPosition += 18

            let notesAttr: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: UIColor.darkGray]
            let notesRect = CGRect(x: 50, y: yPosition, width: pageRect.width - 100, height: 100)
            notes.draw(in: notesRect, withAttributes: notesAttr)
        }
    }

    private static func drawEstimateFooter(pageRect: CGRect, smallFont: UIFont) {
        let footerAttr: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: UIColor.gray]
        let footerText = "This is an estimate, not an invoice."
        let footerSize = footerText.size(withAttributes: footerAttr)
        footerText.draw(at: CGPoint(x: (pageRect.width - footerSize.width) / 2, y: pageRect.height - 50), withAttributes: footerAttr)
    }
}
