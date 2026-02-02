import SwiftUI

@MainActor
class ClientsViewModel: ObservableObject {
    
    @Published var clients: [Client] = []
    
    init() {
        loadClients()
    }
    
    func loadClients() {
        // Will integrate with Core Data
    }
    
    func addClient(name: String, email: String?, phone: String?, address: String?) {
        let client = Client(
            name: name,
            email: email,
            phone: phone,
            address: address
        )
        clients.append(client)
    }
    
    func deleteClients(at offsets: IndexSet) {
        clients.remove(atOffsets: offsets)
    }
}
