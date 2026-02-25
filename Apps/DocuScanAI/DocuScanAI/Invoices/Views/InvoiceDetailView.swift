import SwiftUI
import PDFKit

struct InvoiceDetailView: View {

    let invoice: Invoice
    @StateObject private var viewModel: InvoiceDetailViewModel
    @State private var showingShareSheet = false
    @State private var showingEditSheet = false

    init(invoice: Invoice) {
        self.invoice = invoice
        self._viewModel = StateObject(wrappedValue: InvoiceDetailViewModel(invoice: invoice))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                invoiceHeader
                clientCard
                lineItemsCard
                totalsCard
                actionsCard
            }
            .padding()
        }
        .navigationTitle(invoice.invoiceNumber)
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
                    Button(action: viewModel.duplicateInvoice) {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    Button(action: viewModel.markAsSent) {
                        Label("Mark as Sent", systemImage: "paperplane")
                    }
                    Button(action: viewModel.markAsPaid) {
                        Label("Mark as Paid", systemImage: "checkmark.circle")
                    }
                    Divider()
                    Button(role: .destructive, action: viewModel.deleteInvoice) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private var invoiceHeader: some View {
        VStack(spacing: 8) {
            Text(invoice.invoiceNumber)
                .font(.title2.bold())

            HStack {
                StatusBadge(status: invoice.status)
                Text("•")
                    .foregroundColor(.secondary)
                Text(invoice.formattedDate)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var clientCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bill To")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(invoice.clientName)
                .font(.headline)

            if let email = invoice.clientEmail {
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

            ForEach(invoice.lineItems) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.description)
                        Text("\(item.quantity, specifier: "%.0f") x \(item.formattedUnitPrice)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(item.formattedAmount)
                        .fontWeight(.medium)
                }

                if item.id != invoice.lineItems.last?.id {
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
                Text(invoice.formattedSubtotal)
            }

            HStack {
                Text("Tax")
                Spacer()
                Text(invoice.formattedTax)
            }

            Divider()

            HStack {
                Text("Total")
                    .font(.headline)
                Spacer()
                Text(invoice.formattedTotal)
                    .font(.title2.bold())
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var actionsCard: some View {
        VStack(spacing: 12) {
            Button(action: { showingShareSheet = true }) {
                Label("Send Invoice", systemImage: "paperplane.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }

            Button(action: viewModel.downloadPDF) {
                Label("Download PDF", systemImage: "arrow.down.doc")
                    .font(.headline)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
            }
        }
    }
}

@MainActor
class InvoiceDetailViewModel: ObservableObject {
    let invoice: Invoice
    @Published var pdfDocument: PDFDocument?

    init(invoice: Invoice) {
        self.invoice = invoice
    }

    func duplicateInvoice() {}
    func markAsSent() {}
    func markAsPaid() {}
    func deleteInvoice() {}
    func downloadPDF() {}
}

#Preview {
    NavigationStack {
        InvoiceDetailView(invoice: Invoice(
            clientName: "John Doe",
            clientEmail: "john@example.com",
            lineItems: [
                LineItem(description: "Consulting", quantity: 10, unitPrice: 100)
            ],
            taxRate: 8.0
        ))
    }
}
