import SwiftUI

struct EstimateDetailView: View {

    let estimate: Estimate
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text(estimate.estimateNumber)
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text(estimate.clientName)
                        .font(.title2.bold())

                    EstimateStatusBadge(status: estimate.status)
                }
                .padding()

                // Details Card
                VStack(alignment: .leading, spacing: 16) {
                    detailRow("Date", value: estimate.formattedDate)
                    detailRow("Valid Until", value: estimate.formattedValidUntil)

                    Divider()

                    // Line Items
                    ForEach(estimate.lineItems) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.description)
                                    .font(.body)
                                Text("\(item.quantity, specifier: "%.0f") x \(item.formattedUnitPrice)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(item.formattedAmount)
                                .font(.body.weight(.medium))
                        }
                    }

                    Divider()

                    // Totals
                    HStack {
                        Text("Subtotal")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(estimate.formattedSubtotal)
                    }

                    if estimate.taxRate > 0 {
                        HStack {
                            Text("Tax (\(estimate.taxRate, specifier: "%.1f")%)")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(estimate.formattedTax)
                        }
                    }

                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text(estimate.formattedTotal)
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                // Notes
                if let notes = estimate.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        Text(notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Actions
                VStack(spacing: 12) {
                    if estimate.status == .draft || estimate.status == .sent {
                        Button(action: convertToInvoice) {
                            Label("Convert to Invoice", systemImage: "doc.text.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                    }

                    Button(action: shareEstimate) {
                        Label("Share Estimate", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }

                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label("Delete Estimate", systemImage: "trash")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Estimate")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this estimate?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                var estimates = InvoiceStorage.loadEstimates()
                estimates.removeAll { $0.id == estimate.id }
                InvoiceStorage.saveEstimates(estimates)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func detailRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }

    private func convertToInvoice() {
        // Create invoice from estimate
        let invoice = Invoice(
            invoiceNumber: InvoiceStorage.generateNextInvoiceNumber(),
            clientName: estimate.clientName,
            clientEmail: estimate.clientEmail,
            date: Date(),
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            lineItems: estimate.lineItems,
            taxRate: estimate.taxRate,
            notes: estimate.notes,
            status: .draft
        )
        var invoices = InvoiceStorage.loadInvoices()
        invoices.append(invoice)
        InvoiceStorage.saveInvoices(invoices)

        // Update estimate status
        var estimates = InvoiceStorage.loadEstimates()
        if let index = estimates.firstIndex(where: { $0.id == estimate.id }) {
            estimates[index].status = .accepted
            InvoiceStorage.saveEstimates(estimates)
        }

        dismiss()
    }

    private func shareEstimate() {
        // Generate PDF and share - placeholder
        let text = """
        Estimate \(estimate.estimateNumber)
        Client: \(estimate.clientName)
        Total: \(estimate.formattedTotal)
        Status: \(estimate.status.displayName)
        """
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    NavigationStack {
        EstimateDetailView(estimate: Estimate(
            estimateNumber: "EST-001",
            clientName: "John Doe",
            clientEmail: "john@example.com",
            date: Date(),
            validUntil: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
            lineItems: [LineItem(description: "Web Design", quantity: 1, unitPrice: 500)],
            taxRate: 10,
            notes: "Thank you for your business"
        ))
    }
}
