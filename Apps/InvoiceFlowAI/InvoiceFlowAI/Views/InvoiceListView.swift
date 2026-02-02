import SwiftUI

struct InvoiceListView: View {
    
    @StateObject private var viewModel = InvoiceListViewModel()
    @EnvironmentObject var appState: InvoiceAppState
    @State private var showingCreateOptions = false
    @State private var showingNewInvoice = false
    @State private var showingVoiceInput = false
    @State private var showingReceiptScan = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.invoices.isEmpty {
                    emptyState
                } else {
                    invoiceList
                }
            }
            .navigationTitle("Invoices")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingNewInvoice = true }) {
                            Label("Create Invoice", systemImage: "plus")
                        }
                        Button(action: { showingVoiceInput = true }) {
                            Label("Voice to Invoice", systemImage: "mic.fill")
                        }
                        Button(action: { showingReceiptScan = true }) {
                            Label("Scan Receipt", systemImage: "camera.fill")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingNewInvoice) {
                CreateInvoiceView()
            }
            .sheet(isPresented: $showingVoiceInput) {
                VoiceToInvoiceView()
            }
            .sheet(isPresented: $showingReceiptScan) {
                ScanReceiptView()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("No Invoices Yet")
                .font(.title2.bold())
            
            Text("Create your first invoice in seconds")
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                createButton("Create Invoice", icon: "plus", color: .green) {
                    showingNewInvoice = true
                }
                
                createButton("Voice to Invoice", icon: "mic.fill", color: .blue) {
                    showingVoiceInput = true
                }
                
                createButton("Scan Receipt", icon: "camera.fill", color: .orange) {
                    showingReceiptScan = true
                }
            }
            .padding(.top, 8)
        }
    }
    
    private func createButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(width: 220)
            .padding(.vertical, 14)
            .background(color)
            .cornerRadius(12)
        }
    }
    
    private var invoiceList: some View {
        List {
            if !appState.isProUser {
                Section {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("\(appState.freeInvoiceLimit - appState.invoicesThisMonth) free invoices remaining this month")
                            .font(.subheadline)
                    }
                }
            }
            
            Section("This Month") {
                ForEach(viewModel.invoices.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }) { invoice in
                    NavigationLink(destination: InvoiceDetailView(invoice: invoice)) {
                        InvoiceRow(invoice: invoice)
                    }
                }
            }
            
            if viewModel.invoices.contains(where: { !Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }) {
                Section("Earlier") {
                    ForEach(viewModel.invoices.filter { !Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }) { invoice in
                        NavigationLink(destination: InvoiceDetailView(invoice: invoice)) {
                            InvoiceRow(invoice: invoice)
                        }
                    }
                }
            }
        }
    }
}

struct InvoiceRow: View {
    let invoice: Invoice
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(invoice.clientName)
                    .font(.headline)
                
                Text(invoice.invoiceNumber)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(invoice.formattedTotal)
                    .font(.headline)
                    .foregroundColor(.green)
                
                StatusBadge(status: invoice.status)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: Invoice.Status
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption2.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color)
            .cornerRadius(4)
    }
}

#Preview {
    InvoiceListView()
        .environmentObject(InvoiceAppState())
}
