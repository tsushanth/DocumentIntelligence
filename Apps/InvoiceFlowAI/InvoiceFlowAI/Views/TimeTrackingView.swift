import SwiftUI

struct TimeEntry: Identifiable, Codable {
    var id = UUID()
    var clientName: String
    var projectDescription: String
    var startTime: Date
    var endTime: Date?
    var hourlyRate: Double

    var duration: TimeInterval {
        (endTime ?? Date()).timeIntervalSince(startTime)
    }

    var formattedDuration: String {
        let total = Int(duration)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    var amount: Double {
        (duration / 3600) * hourlyRate
    }

    var formattedAmount: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        return f.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    var formattedDate: String {
        startTime.formatted(date: .abbreviated, time: .shortened)
    }
}

@MainActor
class TimeTrackingViewModel: ObservableObject {
    @Published var entries: [TimeEntry] = []
    @Published var isRunning = false
    @Published var activeEntry: TimeEntry?
    @Published var clientName = ""
    @Published var projectDescription = ""
    @Published var hourlyRate: String = "50"
    @Published var elapsedTime: TimeInterval = 0

    private var timer: Timer?

    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("time_entries.json")
    }

    init() {
        load()
    }

    func startTimer() {
        guard !clientName.isEmpty else { return }
        let entry = TimeEntry(
            clientName: clientName,
            projectDescription: projectDescription.isEmpty ? "General" : projectDescription,
            startTime: Date(),
            hourlyRate: Double(hourlyRate) ?? 50
        )
        activeEntry = entry
        isRunning = true
        elapsedTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.elapsedTime = self?.activeEntry?.duration ?? 0
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        guard var entry = activeEntry else { return }
        entry.endTime = Date()
        entries.insert(entry, at: 0)
        activeEntry = nil
        save()
    }

    func deleteEntries(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    func createInvoiceFromEntry(_ entry: TimeEntry) {
        let hours = entry.duration / 3600
        let item = LineItem(
            description: "\(entry.projectDescription) (\(String(format: "%.1f", hours)) hrs @ $\(String(format: "%.0f", entry.hourlyRate))/hr)",
            quantity: hours,
            unitPrice: entry.hourlyRate
        )
        let invoice = Invoice(
            invoiceNumber: InvoiceStorage.shared.generateInvoiceNumber(),
            clientName: entry.clientName,
            date: Date(),
            lineItems: [item],
            taxRate: 0
        )
        InvoiceStorage.addInvoice(invoice)
    }

    var formattedElapsed: String {
        let total = Int(elapsedTime)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: Self.fileURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.fileURL),
              let decoded = try? JSONDecoder().decode([TimeEntry].self, from: data) else { return }
        entries = decoded
    }
}

struct TimeTrackingView: View {
    @StateObject private var viewModel = TimeTrackingViewModel()
    @State private var showingInvoiceCreated = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Timer card
                timerCard
                    .padding()

                // History
                if viewModel.entries.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No Time Entries")
                            .font(.title3.bold())
                        Text("Start a timer to track billable hours")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.entries) { entry in
                            TimeEntryRow(entry: entry) {
                                viewModel.createInvoiceFromEntry(entry)
                                showingInvoiceCreated = true
                            }
                        }
                        .onDelete(perform: viewModel.deleteEntries)
                    }
                }
            }
            .navigationTitle("Time Tracking")
            .alert("Invoice Created", isPresented: $showingInvoiceCreated) {
                Button("OK") {}
            } message: {
                Text("A new invoice has been created from this time entry.")
            }
        }
    }

    private var timerCard: some View {
        VStack(spacing: 16) {
            // Timer display
            Text(viewModel.formattedElapsed)
                .font(.system(size: 56, weight: .light, design: .monospaced))
                .foregroundColor(viewModel.isRunning ? .green : .primary)

            if !viewModel.isRunning {
                VStack(spacing: 12) {
                    TextField("Client Name", text: $viewModel.clientName)
                        .textFieldStyle(.roundedBorder)

                    TextField("Project / Description", text: $viewModel.projectDescription)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Text("Rate:")
                            .foregroundColor(.secondary)
                        TextField("50", text: $viewModel.hourlyRate)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        Text("$/hr")
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                VStack(spacing: 4) {
                    Text(viewModel.activeEntry?.clientName ?? "")
                        .font(.headline)
                    Text(viewModel.activeEntry?.projectDescription ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Button(action: {
                if viewModel.isRunning {
                    viewModel.stopTimer()
                } else {
                    viewModel.startTimer()
                }
            }) {
                Text(viewModel.isRunning ? "Stop" : "Start Timer")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isRunning ? Color.red : Color.green)
                    .cornerRadius(12)
            }
            .disabled(!viewModel.isRunning && viewModel.clientName.isEmpty)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct TimeEntryRow: View {
    let entry: TimeEntry
    let onCreateInvoice: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.clientName)
                    .font(.headline)
                Spacer()
                Text(entry.formattedDuration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text(entry.projectDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(entry.formattedAmount)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }

            Text(entry.formattedDate)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button {
                onCreateInvoice()
            } label: {
                Label("Invoice", systemImage: "doc.text")
            }
            .tint(.green)
        }
    }
}

#Preview {
    TimeTrackingView()
}
