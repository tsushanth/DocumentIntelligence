import SwiftUI

struct CreateEstimateView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateEstimateViewModel()
    @EnvironmentObject var appState: AppState
    @State private var showingAddItem = false
    @State private var editingItemIndex: Int?

    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    TextField("Client Name", text: $viewModel.clientName)
                    TextField("Client Email", text: $viewModel.clientEmail)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section("Estimate Details") {
                    TextField("Estimate Number", text: $viewModel.estimateNumber)

                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)

                    DatePicker("Valid Until", selection: $viewModel.validUntil, displayedComponents: .date)
                }

                Section("Items") {
                    ForEach(Array(viewModel.lineItems.enumerated()), id: \.element.id) { index, item in
                        Button(action: { editingItemIndex = index }) {
                            EstimateLineItemRow(item: item)
                        }
                        .foregroundColor(.primary)
                    }
                    .onDelete(perform: viewModel.deleteItem)

                    Button(action: { showingAddItem = true }) {
                        Label("Add Item", systemImage: "plus.circle.fill")
                    }
                }

                Section("Discount") {
                    Picker("Discount Type", selection: $viewModel.discountType) {
                        Text("None").tag(Invoice.DiscountType.none)
                        Text("Percentage (%)").tag(Invoice.DiscountType.percentage)
                        Text("Fixed Amount ($)").tag(Invoice.DiscountType.flatAmount)
                    }

                    if viewModel.discountType != .none {
                        HStack {
                            Text(viewModel.discountType == .percentage ? "Percentage" : "Amount")
                            Spacer()
                            if viewModel.discountType == .flatAmount {
                                Text("$")
                                    .foregroundColor(.secondary)
                            }
                            TextField("0", value: $viewModel.discountValue, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            if viewModel.discountType == .percentage {
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
                        TextField("0", value: $viewModel.taxRate, format: .number)
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
                        Text(viewModel.formattedSubtotal)
                            .foregroundColor(.secondary)
                    }

                    if viewModel.hasDiscount {
                        HStack {
                            Text("Discount")
                            Spacer()
                            Text("-\(viewModel.formattedDiscount)")
                                .foregroundColor(.red)
                        }
                    }

                    HStack {
                        Text("Tax (\(viewModel.taxRate, specifier: "%.1f")%)")
                        Spacer()
                        Text(viewModel.formattedTax)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Total")
                            .fontWeight(.bold)
                        Spacer()
                        Text(viewModel.formattedTotal)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }

                Section("Template") {
                    Picker("Style", selection: $viewModel.templateStyle) {
                        ForEach(Invoice.InvoiceTemplate.allCases, id: \.self) { template in
                            Text(template.displayName).tag(template)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Notes") {
                    TextEditor(text: $viewModel.notes)
                        .frame(height: 80)
                }
            }
            .navigationTitle("New Estimate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        viewModel.createEstimate()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isValid)
                }
            }
            .sheet(isPresented: $showingAddItem) {
                EstimateEditLineItemSheet(
                    mode: .add,
                    onSave: { description, quantity, unitPrice in
                        let item = LineItem(description: description, quantity: quantity, unitPrice: unitPrice)
                        viewModel.lineItems.append(item)
                    }
                )
            }
            .sheet(item: $editingItemIndex) { index in
                if index < viewModel.lineItems.count {
                    EstimateEditLineItemSheet(
                        mode: .edit(viewModel.lineItems[index]),
                        onSave: { description, quantity, unitPrice in
                            viewModel.updateItem(at: index, description: description, quantity: quantity, unitPrice: unitPrice)
                        },
                        onDelete: {
                            viewModel.lineItems.remove(at: index)
                        }
                    )
                }
            }
        }
    }
}

struct EstimateLineItemRow: View {
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

// MARK: - Edit Line Item Sheet for Estimates

struct EstimateEditLineItemSheet: View {
    enum Mode {
        case add
        case edit(LineItem)
    }

    let mode: Mode
    var onSave: (String, Double, Double) -> Void
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var description: String = ""
    @State private var quantity: String = "1"
    @State private var unitPrice: String = ""
    @State private var showingDeleteConfirmation = false

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var title: String {
        isEditing ? "Edit Item" : "Add Item"
    }

    private var isValid: Bool {
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(quantity) ?? 0) > 0 &&
        (Double(unitPrice) ?? 0) >= 0
    }

    private var computedAmount: String {
        let qty = Double(quantity) ?? 0
        let price = Double(unitPrice) ?? 0
        let amount = qty * price
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Description", text: $description)

                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("1", text: $quantity)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("Unit Price")
                        Spacer()
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $unitPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                Section {
                    HStack {
                        Text("Amount")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(computedAmount)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }

                if isEditing {
                    Section {
                        Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                            HStack {
                                Spacer()
                                Label("Delete Item", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let qty = Double(quantity) ?? 1
                        let price = Double(unitPrice) ?? 0
                        onSave(description.trimmingCharacters(in: .whitespaces), qty, price)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if case .edit(let item) = mode {
                    description = item.description
                    quantity = String(format: "%.0f", item.quantity)
                    unitPrice = String(format: "%.2f", item.unitPrice)
                }
            }
            .confirmationDialog("Delete this item?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

#Preview {
    CreateEstimateView()
        .environmentObject(AppState())
}
