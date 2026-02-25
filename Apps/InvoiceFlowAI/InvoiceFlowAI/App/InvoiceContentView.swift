import SwiftUI

struct InvoiceContentView: View {
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            InvoiceListView()
                .tabItem {
                    Label("Invoices", systemImage: "doc.text.fill")
                }
                .tag(0)

            ClientsView()
                .tabItem {
                    Label("Clients", systemImage: "person.2.fill")
                }
                .tag(1)

            ItemsView()
                .tabItem {
                    Label("Items", systemImage: "list.bullet.rectangle")
                }
                .tag(2)

            InvoiceSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .tint(.green)
        .onChange(of: selectedTab) { _, newValue in
            let screenNames = ["Invoices", "Clients", "Items", "Settings"]
            if newValue < screenNames.count {
                FirebaseAnalyticsManager.shared.logScreenView(screenName: screenNames[newValue])
            }
        }
        .onAppear {
            FirebaseAnalyticsManager.shared.logScreenView(screenName: "Invoices")
        }
    }
}

#Preview {
    InvoiceContentView()
        .environmentObject(InvoiceAppState())
}
