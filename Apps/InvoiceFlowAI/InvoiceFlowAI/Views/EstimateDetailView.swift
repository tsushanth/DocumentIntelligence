import SwiftUI
import PDFKit
import MessageUI

struct EstimateDetailView: View {

    @StateObject private var viewModel: EstimateDetailViewModel
    @State private var showingShareSheet = false
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingEmailComposer = false
    @State private var showingConvertConfirmation = false
    @State private var convertedInvoice: Invoice?
    @State private var showingConvertedInvoice = false
    @Environment(\.dismiss) private var dismiss

    init(estimate: Estimate) {
        self._viewModel = StateObject(wrappedValue: EstimateDetailViewModel(estimate: estimate))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                estimateHeader

                // Client Info
                clientCard

                // Line Items
                lineItemsCard

                // Totals
                totalsCard

                // Actions
                actionsCard
            }
            .padding()
        }
        .navigationTitle(viewModel.estimate.estimateNumber)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                }

                Menu {
                    Button(action: { showingEditSheet = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(action: { viewModel.duplicateEstimate() }) {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    if MFMailComposeViewController.canSendMail() {
                        Button(action: { showingEmailComposer = true }) {
                            Label("Email Estimate", systemImage: "envelope")
                        }
                    }
                    Button(action: { viewModel.markAsSent() }) {
                        Label("Mark as Sent", systemImage: "paperplane")
                    }
                    Button(action: { viewModel.markAsAccepted() }) {
                        Label("Mark as Accepted", systemImage: "checkmark.circle")
                    }
                    Button(action: { viewModel.markAsDeclined() }) {
                        Label("Mark as Declined", systemImage: "xmark.circle")
                    }
                    if viewModel.estimate.status == .accepted && viewModel.estimate.convertedToInvoiceId == nil {
                        Divider()
                        Button(action: { showingConvertConfirmation = true }) {
                            Label("Convert to Invoice", systemImage: "arrow.right.doc.on.clipboard")
                        }
                    }
                    Divider()
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet, onDismiss: {
            if viewModel.estimate.status == .draft {
                viewModel.markAsSent()
            }
        }) {
            if let pdfURL = viewModel.estimate.pdfURL {
                ShareSheet(activityItems: [pdfURL])
            }
        }
        .confirmationDialog("Delete Estimate?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                viewModel.deleteEstimate()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the estimate and its PDF.")
        }
        .confirmationDialog("Convert to Invoice?", isPresented: $showingConvertConfirmation, titleVisibility: .visible) {
            Button("Convert") {
                convertedInvoice = viewModel.convertToInvoice()
                showingConvertedInvoice = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will create a new invoice from this estimate. The estimate will be marked as converted.")
        }
        .alert("Saved to Files", isPresented: $viewModel.showingSavedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The PDF has been saved to your Downloads folder.")
        }
        .sheet(isPresented: $showingEditSheet) {
            EditEstimateView(estimate: viewModel.estimate) { updatedEstimate in
                viewModel.updateEstimate(updatedEstimate)
            }
        }
        .sheet(isPresented: $showingEmailComposer) {
            if let pdfURL = viewModel.estimate.pdfURL,
               let pdfData = try? Data(contentsOf: pdfURL) {
                MailComposeView(
                    recipients: viewModel.estimate.clientEmail.map { [$0] } ?? [],
                    subject: "Estimate \(viewModel.estimate.estimateNumber)",
                    body: viewModel.emailBody,
                    attachmentData: pdfData,
                    attachmentMimeType: "application/pdf",
                    attachmentFileName: "\(viewModel.estimate.estimateNumber).pdf"
                ) { result in
                    if case .sent = result {
                        viewModel.markAsSent()
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showingConvertedInvoice) {
            if let invoice = convertedInvoice {
                InvoiceDetailView(invoice: invoice)
            }
        }
    }

    private var estimateHeader: some View {
        VStack(spacing: 8) {
            Text(viewModel.estimate.estimateNumber)
                .font(.title2.bold())

            HStack {
                EstimateStatusBadge(status: viewModel.estimate.status)
                Text("\u{2022}")
                    .foregroundColor(.secondary)
                Text(viewModel.estimate.formattedDate)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)

            if viewModel.estimate.status == .sent || viewModel.estimate.status == .draft {
                Text("Valid until \(viewModel.estimate.formattedValidUntil)")
                    .font(.caption)
                    .foregroundColor(viewModel.estimate.isExpired ? .red : .secondary)
            }

            if viewModel.estimate.status == .converted, let invoiceId = viewModel.estimate.convertedToInvoiceId {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.purple)
                    Text("Converted to invoice")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var clientCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prepared For")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(viewModel.estimate.clientName)
                .font(.headline)

            if let email = viewModel.estimate.clientEmail {
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var lineItemsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Items")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(viewModel.estimate.lineItems) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.description)
                        Text("\(item.quantity, specifier: "%.0f") \u{00D7} \(item.formattedUnitPrice)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(item.formattedAmount)
                        .fontWeight(.medium)
                }

                if item.id != viewModel.estimate.lineItems.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var totalsCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Subtotal")
                Spacer()
                Text(viewModel.estimate.formattedSubtotal)
            }

            if viewModel.estimate.discountType != .none && viewModel.estimate.discountAmount > 0 {
                HStack {
                    Text("Discount")
                    Spacer()
                    Text("-\(viewModel.estimate.formattedDiscount)")
                        .foregroundColor(.red)
                }
            }

            HStack {
                Text("Tax")
                Spacer()
                Text(viewModel.estimate.formattedTax)
            }

            Divider()

            HStack {
                Text("Total")
                    .font(.headline)
                Spacer()
                Text(viewModel.estimate.formattedTotal)
                    .font(.title2.bold())
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var actionsCard: some View {
        VStack(spacing: 12) {
            // Primary action based on status
            Button(action: { handlePrimaryAction() }) {
                Label(primaryButtonLabel, systemImage: primaryButtonIcon)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(primaryButtonColor)
                    .cornerRadius(12)
            }

            // Convert to Invoice button for accepted estimates
            if viewModel.estimate.status == .accepted && viewModel.estimate.convertedToInvoiceId == nil {
                Button(action: { showingConvertConfirmation = true }) {
                    Label("Convert to Invoice", systemImage: "arrow.right.doc.on.clipboard")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(12)
                }
            }

            Button(action: { viewModel.downloadPDF() }) {
                Label("Download PDF", systemImage: "arrow.down.doc")
                    .font(.headline)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
            }
        }
    }

    private func handlePrimaryAction() {
        switch viewModel.estimate.status {
        case .draft, .sent:
            showingShareSheet = true
        case .accepted:
            if viewModel.estimate.convertedToInvoiceId == nil {
                showingConvertConfirmation = true
            }
        case .declined, .expired, .converted:
            showingShareSheet = true
        }
    }

    private var primaryButtonLabel: String {
        switch viewModel.estimate.status {
        case .draft: return "Send Estimate"
        case .sent: return "Resend Estimate"
        case .accepted: return "Share Estimate"
        case .declined: return "Share Estimate"
        case .expired: return "Share Estimate"
        case .converted: return "View Estimate"
        }
    }

    private var primaryButtonIcon: String {
        switch viewModel.estimate.status {
        case .draft: return "paperplane.fill"
        case .sent: return "arrow.clockwise"
        case .accepted: return "square.and.arrow.up"
        case .declined: return "square.and.arrow.up"
        case .expired: return "square.and.arrow.up"
        case .converted: return "doc.fill"
        }
    }

    private var primaryButtonColor: Color {
        switch viewModel.estimate.status {
        case .draft: return .orange
        case .sent: return .blue
        case .accepted: return .green
        case .declined: return .gray
        case .expired: return .gray
        case .converted: return .purple
        }
    }
}

// MARK: - Estimate Detail ViewModel

@MainActor
class EstimateDetailViewModel: ObservableObject {
    @Published var estimate: Estimate
    @Published var pdfDocument: PDFDocument?
    @Published var showingSavedAlert = false

    private let estimateId: UUID

    init(estimate: Estimate) {
        self.estimate = estimate
        self.estimateId = estimate.id

        NotificationCenter.default.addObserver(
            forName: .estimatesDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reloadEstimate()
            }
        }
    }

    private func reloadEstimate() {
        let estimates = InvoiceStorage.loadEstimates()
        if let updated = estimates.first(where: { $0.id == estimateId }) {
            self.estimate = updated
        }
    }

    var emailBody: String {
        let businessInfo = InvoiceStorage.loadBusinessInfo()
        let businessName = businessInfo.name.isEmpty ? "Our Company" : businessInfo.name

        return """
        Dear \(estimate.clientName),

        Please find attached estimate \(estimate.estimateNumber) for \(estimate.formattedTotal).

        Estimate Date: \(estimate.formattedDate)
        Valid Until: \(estimate.formattedValidUntil)

        This estimate is valid for 30 days from the date above. If you have any questions or would like to proceed, please don't hesitate to contact us.

        Thank you for considering our services!

        Best regards,
        \(businessName)
        """
    }

    func duplicateEstimate() {
        var newEstimate = estimate
        newEstimate.id = UUID()
        newEstimate.estimateNumber = InvoiceStorage.generateEstimateNumber()
        newEstimate.status = .draft
        newEstimate.createdAt = Date()
        newEstimate.date = Date()
        newEstimate.validUntil = Date().addingTimeInterval(30 * 24 * 60 * 60)
        newEstimate.pdfFileName = "\(newEstimate.estimateNumber).pdf"
        newEstimate.convertedToInvoiceId = nil

        if let pdfData = generatePDFData(for: newEstimate),
           let pdfURL = newEstimate.pdfURL {
            try? pdfData.write(to: pdfURL)
        }

        InvoiceStorage.addEstimate(newEstimate)
        NotificationCenter.default.post(name: .estimatesDidUpdate, object: nil)
    }

    func markAsSent() {
        estimate.status = .sent
        InvoiceStorage.updateEstimate(estimate)
        NotificationCenter.default.post(name: .estimatesDidUpdate, object: nil)
    }

    func markAsAccepted() {
        estimate.status = .accepted
        InvoiceStorage.updateEstimate(estimate)
        NotificationCenter.default.post(name: .estimatesDidUpdate, object: nil)
    }

    func markAsDeclined() {
        estimate.status = .declined
        InvoiceStorage.updateEstimate(estimate)
        NotificationCenter.default.post(name: .estimatesDidUpdate, object: nil)
    }

    func deleteEstimate() {
        InvoiceStorage.deleteEstimate(estimate)
        NotificationCenter.default.post(name: .estimatesDidUpdate, object: nil)
    }

    func updateEstimate(_ updatedEstimate: Estimate) {
        estimate = updatedEstimate
        InvoiceStorage.updateEstimate(estimate)

        if let pdfData = generatePDFData(for: estimate),
           let pdfURL = estimate.pdfURL {
            try? pdfData.write(to: pdfURL)
        }

        NotificationCenter.default.post(name: .estimatesDidUpdate, object: nil)
    }

    func convertToInvoice() -> Invoice {
        // Create invoice from estimate
        var invoice = estimate.toInvoice()

        // Generate PDF
        let pdfFileName = "\(invoice.invoiceNumber).pdf"
        let pdfURL = InvoiceStorage.getInvoicesDirectory().appendingPathComponent(pdfFileName)
        invoice.pdfFileName = pdfFileName

        let businessInfo = InvoiceStorage.loadBusinessInfo()
        if let pdfData = PDFTemplateGenerator.generate(for: invoice, businessInfo: businessInfo) {
            try? pdfData.write(to: pdfURL)
        }

        // Save the invoice
        InvoiceStorage.addInvoice(invoice)

        // Update estimate status
        estimate.status = .converted
        estimate.convertedToInvoiceId = invoice.id
        InvoiceStorage.updateEstimate(estimate)

        // Notify
        NotificationCenter.default.post(name: .invoicesDidUpdate, object: nil)
        NotificationCenter.default.post(name: .estimatesDidUpdate, object: nil)

        return invoice
    }

    func downloadPDF() {
        guard let pdfURL = estimate.pdfURL,
              FileManager.default.fileExists(atPath: pdfURL.path) else {
            return
        }

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsURL.appendingPathComponent("\(estimate.estimateNumber).pdf")

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: pdfURL, to: destinationURL)
            showingSavedAlert = true
        } catch {
            #if DEBUG
            print("Failed to copy PDF: \(error)")
            #endif
        }
    }

    private func generatePDFData(for estimate: Estimate) -> Data? {
        let businessInfo = InvoiceStorage.loadBusinessInfo()
        return PDFTemplateGenerator.generate(for: estimate, businessInfo: businessInfo)
    }
}

// MARK: - Edit Estimate View

struct EditEstimateView: View {
    @Environment(\.dismiss) private var dismiss
    let estimate: Estimate
    var onSave: (Estimate) -> Void

    @State private var clientName: String
    @State private var clientEmail: String
    @State private var lineItems: [LineItem]
    @State private var taxRate: String
    @State private var notes: String
    @State private var date: Date
    @State private var validUntil: Date

    @State private var discountType: Invoice.DiscountType
    @State private var discountValue: String
    @State private var templateStyle: Invoice.InvoiceTemplate

    @State private var showingAddItem = false
    @State private var editingItemIndex: Int?

    init(estimate: Estimate, onSave: @escaping (Estimate) -> Void) {
        self.estimate = estimate
        self.onSave = onSave
        _clientName = State(initialValue: estimate.clientName)
        _clientEmail = State(initialValue: estimate.clientEmail ?? "")
        _lineItems = State(initialValue: estimate.lineItems)
        _taxRate = State(initialValue: String(format: "%.1f", estimate.taxRate))
        _notes = State(initialValue: estimate.notes ?? "")
        _date = State(initialValue: estimate.date)
        _validUntil = State(initialValue: estimate.validUntil)
        _discountType = State(initialValue: estimate.discountType)
        _discountValue = State(initialValue: String(format: "%.2f", estimate.discountValue))
        _templateStyle = State(initialValue: estimate.templateStyle)
    }

    private var subtotal: Double {
        lineItems.reduce(0) { $0 + $1.amount }
    }

    private var discountAmount: Double {
        let value = Double(discountValue) ?? 0
        switch discountType {
        case .none:
            return 0
        case .percentage:
            return subtotal * (value / 100)
        case .flatAmount:
            return min(value, subtotal)
        }
    }

    private var subtotalAfterDiscount: Double {
        subtotal - discountAmount
    }

    private var tax: Double {
        subtotalAfterDiscount * ((Double(taxRate) ?? 0) / 100)
    }

    private var total: Double {
        subtotalAfterDiscount + tax
    }

    private var hasDiscount: Bool {
        discountType != .none && (Double(discountValue) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    TextField("Client Name", text: $clientName)
                    TextField("Email (optional)", text: $clientEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                }

                Section("Estimate Details") {
                    LabeledContent("Estimate #", value: estimate.estimateNumber)

                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    DatePicker("Valid Until", selection: $validUntil, displayedComponents: .date)
                }

                Section("Items") {
                    ForEach(Array(lineItems.enumerated()), id: \.element.id) { index, item in
                        Button(action: { editingItemIndex = index }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.description)
                                        .font(.body)
                                    Text("\(item.quantity, specifier: "%.0f") \u{00D7} \(item.formattedUnitPrice)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(item.formattedAmount)
                                    .foregroundColor(.orange)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                    .onDelete { indexSet in
                        lineItems.remove(atOffsets: indexSet)
                    }

                    Button(action: { showingAddItem = true }) {
                        Label("Add Item", systemImage: "plus.circle.fill")
                    }
                }

                Section("Discount") {
                    Picker("Discount Type", selection: $discountType) {
                        Text("None").tag(Invoice.DiscountType.none)
                        Text("Percentage (%)").tag(Invoice.DiscountType.percentage)
                        Text("Fixed Amount ($)").tag(Invoice.DiscountType.flatAmount)
                    }

                    if discountType != .none {
                        HStack {
                            Text(discountType == .percentage ? "Percentage" : "Amount")
                            Spacer()
                            if discountType == .flatAmount {
                                Text("$")
                                    .foregroundColor(.secondary)
                            }
                            TextField("0", text: $discountValue)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            if discountType == .percentage {
                                Text("%")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section("Tax") {
                    HStack {
                        Text("Tax Rate")
                        Spacer()
                        TextField("0", text: $taxRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("%")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Summary") {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(formatCurrency(subtotal))
                            .foregroundColor(.secondary)
                    }

                    if hasDiscount {
                        HStack {
                            Text("Discount")
                            Spacer()
                            Text("-\(formatCurrency(discountAmount))")
                                .foregroundColor(.red)
                        }
                    }

                    HStack {
                        Text("Tax")
                        Spacer()
                        Text(formatCurrency(tax))
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Total")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(formatCurrency(total))
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }

                Section("Estimate Template") {
                    Picker("Style", selection: $templateStyle) {
                        ForEach(Invoice.InvoiceTemplate.allCases, id: \.self) { template in
                            Text(template.displayName).tag(template)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
            }
            .navigationTitle("Edit Estimate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updated = estimate
                        updated.clientName = clientName
                        updated.clientEmail = clientEmail.isEmpty ? nil : clientEmail
                        updated.lineItems = lineItems
                        updated.taxRate = Double(taxRate) ?? 0
                        updated.notes = notes.isEmpty ? nil : notes
                        updated.date = date
                        updated.validUntil = validUntil
                        updated.discountType = discountType
                        updated.discountValue = Double(discountValue) ?? 0
                        updated.templateStyle = templateStyle
                        onSave(updated)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(clientName.isEmpty || lineItems.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddItem) {
                EstimateEditLineItemSheet(
                    mode: .add,
                    onSave: { description, quantity, unitPrice in
                        let item = LineItem(description: description, quantity: quantity, unitPrice: unitPrice)
                        lineItems.append(item)
                    }
                )
            }
            .sheet(item: $editingItemIndex) { index in
                if index < lineItems.count {
                    EstimateEditLineItemSheet(
                        mode: .edit(lineItems[index]),
                        onSave: { description, quantity, unitPrice in
                            lineItems[index] = LineItem(
                                id: lineItems[index].id,
                                description: description,
                                quantity: quantity,
                                unitPrice: unitPrice
                            )
                        },
                        onDelete: {
                            lineItems.remove(at: index)
                        }
                    )
                }
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

#Preview {
    NavigationStack {
        EstimateDetailView(estimate: Estimate(
            estimateNumber: "EST-202402-001",
            clientName: "John Doe",
            clientEmail: "john@example.com",
            lineItems: [
                LineItem(description: "Consulting", quantity: 10, unitPrice: 100)
            ],
            taxRate: 8.0
        ))
    }
}
