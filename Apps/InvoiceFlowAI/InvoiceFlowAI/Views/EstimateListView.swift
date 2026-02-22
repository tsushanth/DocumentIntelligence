import SwiftUI

struct EstimateListView: View {

    @StateObject private var viewModel = EstimateListViewModel()
    @EnvironmentObject var appState: InvoiceAppState
    @State private var showingNewEstimate = false

    private var thisMonthEstimates: [Estimate] {
        viewModel.estimates.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
    }

    private var earlierEstimates: [Estimate] {
        viewModel.estimates.filter { !Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
    }

    var body: some View {
        Group {
            if viewModel.estimates.isEmpty {
                emptyState
            } else {
                estimateList
            }
        }
        .navigationTitle("Estimates")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingNewEstimate = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showingNewEstimate) {
            CreateEstimateView()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.badge.clock")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            Text("No Estimates Yet")
                .font(.title2.bold())

            Text("Create estimates and convert them to invoices when accepted")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: { showingNewEstimate = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Estimate")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 220)
                .padding(.vertical, 14)
                .background(Color.orange)
                .cornerRadius(12)
            }
            .padding(.top, 8)
        }
    }

    private var estimateList: some View {
        List {
            // Summary section
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pending Value")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(viewModel.totalPending))
                            .font(.title3.bold())
                            .foregroundColor(.orange)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Accepted This Month")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(viewModel.totalAcceptedThisMonth))
                            .font(.title3.bold())
                            .foregroundColor(.green)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("This Month") {
                ForEach(thisMonthEstimates) { estimate in
                    NavigationLink(destination: EstimateDetailView(estimate: estimate)) {
                        EstimateRow(estimate: estimate)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deleteEstimate(thisMonthEstimates[index])
                    }
                }
            }

            if !earlierEstimates.isEmpty {
                Section("Earlier") {
                    ForEach(earlierEstimates) { estimate in
                        NavigationLink(destination: EstimateDetailView(estimate: estimate)) {
                            EstimateRow(estimate: estimate)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deleteEstimate(earlierEstimates[index])
                        }
                    }
                }
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct EstimateRow: View {
    let estimate: Estimate

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(estimate.clientName)
                    .font(.headline)

                Text(estimate.estimateNumber)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(estimate.formattedTotal)
                    .font(.headline)
                    .foregroundColor(.orange)

                EstimateStatusBadge(status: estimate.status)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EstimateStatusBadge: View {
    let status: Estimate.Status

    var body: some View {
        Text(status.displayName)
            .font(.caption2.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color)
            .cornerRadius(4)
    }
}

#Preview {
    NavigationStack {
        EstimateListView()
            .environmentObject(InvoiceAppState())
    }
}
