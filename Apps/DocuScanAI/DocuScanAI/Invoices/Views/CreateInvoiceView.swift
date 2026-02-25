import SwiftUI

struct CreateInvoiceView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateInvoiceViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    NavigationLink(destination: SelectClientView(selectedClient: $viewModel.selectedClient)) {
                        HStack {
                            Text("Client")
                            Spacer()
                            Text(viewModel.selectedClient?.name ?? "Select")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Invoice Details") {
                    TextField("Invoice Number", text: $viewModel.invoiceNumber)
                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                    DatePicker("Due Date", selection: $viewModel.dueDate, displayedComponents: .date)
                }

                Section("Items") {
                    ForEach(viewModel.lineItems) { item in
                        LineItemRow(item: item)
                    }
                    .onDelete(perform: viewModel.deleteItem)

                    Button(action: { viewModel.addItem() }) {
                        Label("Add Item", systemImage: "plus.circle.fill")
                    }
                }

                Section("Summary") {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(viewModel.formattedSubtotal)
                    }

                    HStack {
                        Text("Tax (\(viewModel.taxRate, specifier: "%.1f")%)")
                        Spacer()
                        Text(viewModel.formattedTax)
                    }

                    HStack {
                        Text("Total")
                            .fontWeight(.bold)
                        Spacer()
                        Text(viewModel.formattedTotal)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $viewModel.notes)
                        .frame(height: 80)
                }
            }
            .navigationTitle("New Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        viewModel.createInvoice()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isValid)
                }
            }
        }
    }
}

struct LineItemRow: View {
    let item: LineItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.description)
                .font(.body)

            HStack {
                Text("\(item.quantity, specifier: "%.0f") x \(item.formattedUnitPrice)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(item.formattedAmount)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SelectClientView: View {
    @Binding var selectedClient: Client?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Button(action: {}) {
                Label("Add New Client", systemImage: "plus.circle.fill")
            }
        }
        .navigationTitle("Select Client")
    }
}

#Preview {
    CreateInvoiceView()
        .environmentObject(AppState())
}
