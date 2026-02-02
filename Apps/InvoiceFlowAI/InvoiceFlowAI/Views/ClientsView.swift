import SwiftUI

struct ClientsView: View {
    
    @StateObject private var viewModel = ClientsViewModel()
    @State private var showingAddClient = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.clients.isEmpty {
                    emptyState
                } else {
                    clientList
                }
            }
            .navigationTitle("Clients")
            .searchable(text: $searchText, prompt: "Search clients")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddClient = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddClient) {
                AddClientView(viewModel: viewModel)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Clients Yet")
                .font(.title2.bold())
            
            Text("Add your first client to get started")
                .foregroundColor(.secondary)
            
            Button(action: { showingAddClient = true }) {
                Label("Add Client", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(10)
            }
        }
    }
    
    private var clientList: some View {
        List {
            ForEach(filteredClients) { client in
                NavigationLink(destination: ClientDetailView(client: client)) {
                    ClientRow(client: client)
                }
            }
            .onDelete(perform: viewModel.deleteClients)
        }
    }
    
    private var filteredClients: [Client] {
        if searchText.isEmpty {
            return viewModel.clients
        }
        return viewModel.clients.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
}

struct ClientRow: View {
    let client: Client
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 45, height: 45)
                .overlay(
                    Text(client.initials)
                        .font(.headline)
                        .foregroundColor(.green)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(client.name)
                    .font(.headline)
                
                if let email = client.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ClientDetailView: View {
    let client: Client
    
    var body: some View {
        List {
            Section("Contact") {
                if let email = client.email {
                    LabeledContent("Email", value: email)
                }
                if let phone = client.phone {
                    LabeledContent("Phone", value: phone)
                }
                if let address = client.address {
                    LabeledContent("Address", value: address)
                }
            }
            
            Section("Invoices") {
                Text("No invoices yet")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle(client.name)
    }
}

struct AddClientView: View {
    @ObservedObject var viewModel: ClientsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Client Info") {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                    TextField("Phone", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section("Address") {
                    TextEditor(text: $address)
                        .frame(height: 80)
                }
            }
            .navigationTitle("New Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.addClient(
                            name: name,
                            email: email.isEmpty ? nil : email,
                            phone: phone.isEmpty ? nil : phone,
                            address: address.isEmpty ? nil : address
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ClientsView()
}
