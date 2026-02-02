import SwiftUI

struct InvoiceSettingsView: View {
    
    @EnvironmentObject var appState: InvoiceAppState
    @State private var showingPaywall = false
    @State private var businessName = ""
    @State private var businessEmail = ""
    @State private var defaultTaxRate = 8.0
    
    var body: some View {
        NavigationStack {
            List {
                // Subscription
                Section {
                    if appState.isProUser {
                        HStack {
                            Image(systemName: "star.circle.fill")
                                .foregroundColor(.yellow)
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("Pro Member")
                                    .font(.headline)
                                Text("Unlimited invoices")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        Button(action: { showingPaywall = true }) {
                            HStack {
                                Image(systemName: "star.circle")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text("Upgrade to Pro")
                                        .font(.headline)
                                    Text("\(appState.freeInvoiceLimit - appState.invoicesThisMonth)/\(appState.freeInvoiceLimit) free invoices left")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                // Business Info
                Section("Business Information") {
                    TextField("Business Name", text: $businessName)
                    TextField("Email", text: $businessEmail)
                        .textContentType(.emailAddress)
                    
                    NavigationLink(destination: Text("Logo Settings")) {
                        HStack {
                            Text("Logo")
                            Spacer()
                            Text("Not Set")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Invoice Settings
                Section("Invoice Defaults") {
                    HStack {
                        Text("Tax Rate")
                        Spacer()
                        TextField("Rate", value: $defaultTaxRate, format: .percent)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    NavigationLink(destination: Text("Payment Terms")) {
                        HStack {
                            Text("Payment Terms")
                            Spacer()
                            Text("Net 30")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink(destination: Text("Invoice Template")) {
                        Label("Invoice Template", systemImage: "doc.richtext")
                    }
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                    NavigationLink(destination: Text("Privacy")) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    NavigationLink(destination: Text("Terms")) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                    Button(action: {}) {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPaywall) {
                InvoiceFlowPaywallView()
            }
        }
    }
}

struct InvoiceFlowPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(.green)
                        Text("InvoiceFlow Pro")
                            .font(.title.bold())
                        Text("The fastest way to invoice")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        proFeature("infinity", "Unlimited Invoices", "No monthly limits")
                        proFeature("mic.fill", "Voice to Invoice", "Create invoices by speaking")
                        proFeature("camera.fill", "Receipt Scanning", "Auto-create expenses")
                        proFeature("person.2.fill", "Client Database", "Save client info")
                        proFeature("repeat", "Recurring Invoices", "Set up auto-billing")
                        proFeature("dollarsign.circle", "Payment Tracking", "Track who's paid")
                    }
                    .padding(.horizontal, 24)
                    
                    VStack(spacing: 8) {
                        Text("$6.99/month")
                            .font(.title2.bold())
                        Text("Cancel anytime")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    Button(action: {}) {
                        Text("Subscribe Now")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func proFeature(_ icon: String, _ title: String, _ desc: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(desc).font(.subheadline).foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    InvoiceSettingsView()
        .environmentObject(InvoiceAppState())
}
