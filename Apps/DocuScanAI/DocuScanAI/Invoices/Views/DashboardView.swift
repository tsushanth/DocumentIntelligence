import SwiftUI
import Charts

// MARK: - Invoice.Status displayName Extension

extension Invoice.Status {
    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Dashboard View

struct DashboardView: View {

    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedTimeRange: TimeRange = .thisMonth

    enum TimeRange: String, CaseIterable {
        case thisWeek = "Week"
        case thisMonth = "Month"
        case thisQuarter = "Quarter"
        case thisYear = "Year"
        case allTime = "All Time"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time Range Picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Summary Cards
                summaryCards

                // Revenue Chart
                revenueChart

                // Invoice Status Breakdown
                statusBreakdown

                // Top Clients
                topClients

                // Recent Activity
                recentActivity
            }
            .padding(.vertical)
        }
        .navigationTitle("Dashboard")
        .refreshable {
            viewModel.refresh()
        }
        .onAppear {
            viewModel.refresh()
        }
        .onChange(of: selectedTimeRange) { _ in
            viewModel.setTimeRange(selectedTimeRange)
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            SummaryCard(
                title: "Total Revenue",
                value: viewModel.totalRevenue,
                icon: "dollarsign.circle.fill",
                color: .green
            )

            SummaryCard(
                title: "Outstanding",
                value: viewModel.outstandingBalance,
                icon: "clock.fill",
                color: .orange
            )

            SummaryCard(
                title: "Overdue",
                value: viewModel.overdueAmount,
                icon: "exclamationmark.triangle.fill",
                color: .red
            )

            SummaryCard(
                title: "Invoices",
                value: "\(viewModel.invoiceCount)",
                icon: "doc.text.fill",
                color: .blue,
                isAmount: false
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Revenue Chart

    private var revenueChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Revenue Trend")
                .font(.headline)
                .padding(.horizontal)

            if viewModel.revenueData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No Data")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Create invoices to see revenue trends")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                Chart(viewModel.revenueData) { dataPoint in
                    BarMark(
                        x: .value("Period", dataPoint.label),
                        y: .value("Revenue", dataPoint.value)
                    )
                    .foregroundStyle(Color.green.gradient)
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(formatCompactCurrency(amount))
                            }
                        }
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // MARK: - Status Breakdown

    private var statusBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Invoice Status")
                .font(.headline)

            if viewModel.statusBreakdown.isEmpty {
                Text("No invoices yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                HStack(spacing: 16) {
                    // Pie Chart (iOS 16 compatible)
                    PieChartView(data: viewModel.statusBreakdown)
                        .frame(width: 120, height: 120)

                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.statusBreakdown) { item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 10, height: 10)
                                Text(item.status)
                                    .font(.caption)
                                Spacer()
                                Text("\(item.count)")
                                    .font(.caption.bold())
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // MARK: - Top Clients

    private var topClients: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Clients")
                    .font(.headline)
                Spacer()
                Text("by Revenue")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.topClients.isEmpty {
                Text("No client data yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(Array(viewModel.topClients.enumerated()), id: \.element.name) { index, client in
                    HStack {
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .frame(width: 20)

                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(client.initials)
                                    .font(.caption.bold())
                                    .foregroundColor(.green)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(client.name)
                                .font(.subheadline.weight(.medium))
                            Text("\(client.invoiceCount) invoice\(client.invoiceCount == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(client.formattedRevenue)
                            .font(.subheadline.bold())
                            .foregroundColor(.green)
                    }

                    if index < viewModel.topClients.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // MARK: - Recent Activity

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)

            if viewModel.recentInvoices.isEmpty {
                Text("No recent activity")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(viewModel.recentInvoices.prefix(5)) { invoice in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(invoice.clientName)
                                .font(.subheadline.weight(.medium))
                            Text(invoice.invoiceNumber)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(invoice.formattedTotal)
                                .font(.subheadline.bold())
                            StatusBadge(status: invoice.status)
                        }
                    }

                    if invoice.id != viewModel.recentInvoices.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private func formatCompactCurrency(_ amount: Double) -> String {
        if amount >= 1_000_000 {
            return "$\(String(format: "%.1f", amount / 1_000_000))M"
        } else if amount >= 1_000 {
            return "$\(String(format: "%.1f", amount / 1_000))K"
        }
        return "$\(Int(amount))"
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var isAmount: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(isAmount ? .title2.bold() : .title.bold())
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Pie Chart View (iOS 16 Compatible)

struct PieChartView: View {
    let data: [DashboardViewModel.StatusBreakdownItem]

    var body: some View {
        GeometryReader { geometry in
            let total = data.reduce(0) { $0 + $1.count }
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2
            let innerRadius = radius * 0.5

            ZStack {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                    let startAngle = angleForIndex(index, total: total)
                    let endAngle = angleForIndex(index + 1, total: total)

                    PieSlice(
                        startAngle: startAngle,
                        endAngle: endAngle,
                        innerRadius: innerRadius,
                        outerRadius: radius
                    )
                    .fill(item.color)
                }
            }
            .position(center)
        }
    }

    private func angleForIndex(_ index: Int, total: Int) -> Angle {
        guard total > 0 else { return .degrees(-90) }
        let sum = data.prefix(index).reduce(0) { $0 + $1.count }
        let fraction = Double(sum) / Double(total)
        return .degrees(fraction * 360 - 90)
    }
}

struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let innerRadius: CGFloat
    let outerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)

        path.addArc(center: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()

        return path
    }
}

// MARK: - Dashboard ViewModel

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var totalRevenue: String = "$0"
    @Published var outstandingBalance: String = "$0"
    @Published var overdueAmount: String = "$0"
    @Published var invoiceCount: Int = 0
    @Published var revenueData: [ChartDataPoint] = []
    @Published var statusBreakdown: [StatusBreakdownItem] = []
    @Published var topClients: [TopClient] = []
    @Published var recentInvoices: [Invoice] = []

    private var timeRange: DashboardView.TimeRange = .thisMonth

    struct ChartDataPoint: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
    }

    struct StatusBreakdownItem: Identifiable {
        let id = UUID()
        let status: String
        let count: Int
        let color: Color
    }

    struct TopClient: Identifiable {
        let id = UUID()
        let name: String
        let initials: String
        let revenue: Double
        let invoiceCount: Int

        var formattedRevenue: String {
            Currency.usd.format(revenue)
        }
    }

    func setTimeRange(_ range: DashboardView.TimeRange) {
        self.timeRange = range
        refresh()
    }

    func refresh() {
        let invoices = InvoiceStorage.loadInvoices()
        let filteredInvoices = filterInvoices(invoices)

        calculateSummary(from: filteredInvoices, allInvoices: invoices)
        calculateRevenueData(from: filteredInvoices)
        calculateStatusBreakdown(from: filteredInvoices)
        calculateTopClients(from: filteredInvoices)
        recentInvoices = Array(invoices.prefix(10))
    }

    private func filterInvoices(_ invoices: [Invoice]) -> [Invoice] {
        let calendar = Calendar.current
        let now = Date()

        let startDate: Date

        switch timeRange {
        case .thisWeek:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .thisMonth:
            startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        case .thisQuarter:
            let quarter = (calendar.component(.month, from: now) - 1) / 3
            let quarterStart = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: quarter * 3 + 1)) ?? now
            startDate = quarterStart
        case .thisYear:
            startDate = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
        case .allTime:
            return invoices
        }

        return invoices.filter { $0.date >= startDate }
    }

    private func calculateSummary(from invoices: [Invoice], allInvoices: [Invoice]) {
        // Total revenue (paid invoices)
        let paid = invoices.filter { $0.status == .paid }.reduce(0) { $0 + $1.total }
        let partialPaid = invoices.filter { $0.status == .partiallyPaid }.reduce(0) { $0 + $1.amountPaid }
        totalRevenue = Currency.usd.format(paid + partialPaid)

        // Outstanding balance (all unpaid)
        let outstanding = allInvoices
            .filter { $0.status != .paid && $0.status != .draft }
            .reduce(0) { $0 + $1.balanceDue }
        outstandingBalance = Currency.usd.format(outstanding)

        // Overdue amount
        let overdue = allInvoices
            .filter { $0.status == .overdue }
            .reduce(0) { $0 + $1.balanceDue }
        overdueAmount = Currency.usd.format(overdue)

        // Invoice count
        invoiceCount = invoices.count
    }

    private func calculateRevenueData(from invoices: [Invoice]) {
        let calendar = Calendar.current
        var dataByPeriod: [String: Double] = [:]

        let paidInvoices = invoices.filter { $0.status == .paid || $0.status == .partiallyPaid }

        for invoice in paidInvoices {
            let key: String
            switch timeRange {
            case .thisWeek:
                let formatter = DateFormatter()
                formatter.dateFormat = "EEE"
                key = formatter.string(from: invoice.date)
            case .thisMonth:
                let day = calendar.component(.day, from: invoice.date)
                key = "Day \(day)"
            case .thisQuarter, .thisYear, .allTime:
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                key = formatter.string(from: invoice.date)
            }

            let revenue = invoice.status == .paid ? invoice.total : invoice.amountPaid
            dataByPeriod[key, default: 0] += revenue
        }

        // Sort and convert to array
        let sortedKeys: [String]
        switch timeRange {
        case .thisWeek:
            sortedKeys = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].filter { dataByPeriod[$0] != nil }
        case .thisMonth:
            sortedKeys = dataByPeriod.keys.sorted { key1, key2 in
                let day1 = Int(key1.replacingOccurrences(of: "Day ", with: "")) ?? 0
                let day2 = Int(key2.replacingOccurrences(of: "Day ", with: "")) ?? 0
                return day1 < day2
            }
        default:
            let monthOrder = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            sortedKeys = dataByPeriod.keys.sorted { monthOrder.firstIndex(of: $0) ?? 0 < monthOrder.firstIndex(of: $1) ?? 0 }
        }

        revenueData = sortedKeys.map { ChartDataPoint(label: $0, value: dataByPeriod[$0] ?? 0) }
    }

    private func calculateStatusBreakdown(from invoices: [Invoice]) {
        var breakdown: [Invoice.Status: Int] = [:]

        for invoice in invoices {
            breakdown[invoice.status, default: 0] += 1
        }

        statusBreakdown = breakdown.map { status, count in
            StatusBreakdownItem(
                status: status.displayName,
                count: count,
                color: status.color
            )
        }.sorted { $0.count > $1.count }
    }

    private func calculateTopClients(from invoices: [Invoice]) {
        var clientRevenue: [String: (revenue: Double, count: Int)] = [:]

        for invoice in invoices where invoice.status == .paid || invoice.status == .partiallyPaid {
            let revenue = invoice.status == .paid ? invoice.total : invoice.amountPaid
            let current = clientRevenue[invoice.clientName] ?? (0, 0)
            clientRevenue[invoice.clientName] = (current.revenue + revenue, current.count + 1)
        }

        topClients = clientRevenue
            .map { name, data in
                TopClient(
                    name: name,
                    initials: getInitials(from: name),
                    revenue: data.revenue,
                    invoiceCount: data.count
                )
            }
            .sorted { $0.revenue > $1.revenue }
            .prefix(5)
            .map { $0 }
    }

    private func getInitials(from name: String) -> String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
}
