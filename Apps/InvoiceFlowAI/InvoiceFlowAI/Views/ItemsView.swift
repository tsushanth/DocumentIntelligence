import SwiftUI

struct ItemsView: View {
    
    @StateObject private var viewModel = ItemsViewModel()
    @State private var showingAddItem = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.items.isEmpty {
                    emptyState
                } else {
                    itemList
                }
            }
            .navigationTitle("Item Templates")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddItem = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView(viewModel: viewModel)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Item Templates")
                .font(.title2.bold())
            
            Text("Save frequently used items for quick invoicing")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { showingAddItem = true }) {
                Label("Add Item", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(10)
            }
        }
    }
    
    private var itemList: some View {
        List {
            ForEach(viewModel.items) { item in
                ItemTemplateRow(item: item)
            }
            .onDelete(perform: viewModel.deleteItems)
        }
    }
}

struct ItemTemplateRow: View {
    let item: ItemTemplate
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                if let description = item.itemDescription {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text(item.formattedPrice)
                .font(.headline)
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
}

struct AddItemView: View {
    @ObservedObject var viewModel: ItemsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var price = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Item Name", text: $name)
                TextField("Description (optional)", text: $description)
                TextField("Price", text: $price)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.addItem(
                            name: name,
                            description: description.isEmpty ? nil : description,
                            price: Double(price) ?? 0
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || price.isEmpty)
                }
            }
        }
    }
}

@MainActor
class ItemsViewModel: ObservableObject {
    @Published var items: [ItemTemplate] = []
    
    func addItem(name: String, description: String?, price: Double) {
        let item = ItemTemplate(name: name, itemDescription: description, price: price)
        items.append(item)
    }
    
    func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
}

#Preview {
    ItemsView()
}
