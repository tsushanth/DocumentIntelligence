import SwiftUI

struct LateFeeSettingsView: View {

    @State private var settings: LateFeeSettings
    @State private var maxFeeEnabled: Bool
    @State private var maxFeeAmount: String
    @FocusState private var isAmountFocused: Bool

    private let businessInfo = InvoiceStorage.loadBusinessInfo()

    init() {
        let loaded = InvoiceStorage.loadBusinessInfo().defaultLateFeeSettings
        _settings = State(initialValue: loaded)
        _maxFeeEnabled = State(initialValue: loaded.maxLateFee != nil)
        _maxFeeAmount = State(initialValue: loaded.maxLateFee.map { String(format: "%.2f", $0) } ?? "100")
    }

    var body: some View {
        Form {
            Section {
                Toggle("Enable Late Fees", isOn: $settings.enabled)
                    .onChange(of: settings.enabled) { _ in saveSettings() }
            } footer: {
                Text("When enabled, late fees will be automatically calculated for overdue invoices.")
            }

            if settings.enabled {
                Section {
                    Picker("Late Fee Type", selection: $settings.feeType) {
                        ForEach(LateFeeSettings.FeeType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .onChange(of: settings.feeType) { _ in saveSettings() }
                } header: {
                    Text("Fee Type")
                } footer: {
                    Text(settings.feeType.description)
                }

                Section {
                    HStack {
                        if settings.feeType == .flatFee || settings.feeType == .dailyFlat {
                            Text(businessInfo.defaultCurrency.symbol)
                                .foregroundColor(.secondary)
                        }

                        TextField("Amount", value: $settings.feeAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($isAmountFocused)
                            .onChange(of: settings.feeAmount) { _ in saveSettings() }

                        if settings.feeType == .percentage || settings.feeType == .dailyPercentage {
                            Text("%")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Fee Amount")
                } footer: {
                    Text(feeExampleText)
                }

                Section {
                    Stepper("\(settings.gracePeriodDays) day\(settings.gracePeriodDays == 1 ? "" : "s")", value: $settings.gracePeriodDays, in: 0...30)
                        .onChange(of: settings.gracePeriodDays) { _ in saveSettings() }
                } header: {
                    Text("Grace Period")
                } footer: {
                    Text("Days after the due date before late fees begin to apply.")
                }

                if settings.feeType == .dailyPercentage || settings.feeType == .dailyFlat {
                    Section {
                        Toggle("Cap Maximum Fee", isOn: $maxFeeEnabled)
                            .onChange(of: maxFeeEnabled) { enabled in
                                if enabled {
                                    settings.maxLateFee = Double(maxFeeAmount) ?? 100
                                } else {
                                    settings.maxLateFee = nil
                                }
                                saveSettings()
                            }

                        if maxFeeEnabled {
                            HStack {
                                Text(businessInfo.defaultCurrency.symbol)
                                    .foregroundColor(.secondary)
                                TextField("Maximum", text: $maxFeeAmount)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .focused($isAmountFocused)
                                    .onChange(of: maxFeeAmount) { newValue in
                                        settings.maxLateFee = Double(newValue)
                                        saveSettings()
                                    }
                            }
                        }
                    } header: {
                        Text("Maximum Fee")
                    } footer: {
                        Text("Limit the total late fee amount to prevent excessive charges.")
                    }
                }

                Section("Preview") {
                    previewSection
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label("How Late Fees Work", systemImage: "info.circle.fill")
                        .font(.headline)
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("Late fees are calculated automatically for overdue invoices")
                        bulletPoint("Fees appear on the invoice and in the balance due")
                        bulletPoint("The grace period gives clients extra time before fees apply")
                        bulletPoint("Daily fees accumulate each day the invoice is overdue")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Late Fees")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
            }
        }
    }

    private func hideKeyboard() {
        isAmountFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    @ViewBuilder
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
    }

    private var feeExampleText: String {
        let exampleInvoiceTotal = 1000.0
        let exampleFee: Double

        switch settings.feeType {
        case .flatFee:
            exampleFee = settings.feeAmount
            return "Example: A late invoice would incur a \(businessInfo.defaultCurrency.format(exampleFee)) late fee."
        case .percentage:
            exampleFee = exampleInvoiceTotal * (settings.feeAmount / 100)
            return "Example: A \(businessInfo.defaultCurrency.format(exampleInvoiceTotal)) invoice would incur a \(businessInfo.defaultCurrency.format(exampleFee)) late fee."
        case .dailyPercentage:
            exampleFee = exampleInvoiceTotal * (settings.feeAmount / 100)
            return "Example: A \(businessInfo.defaultCurrency.format(exampleInvoiceTotal)) invoice would incur \(businessInfo.defaultCurrency.format(exampleFee))/day."
        case .dailyFlat:
            return "Example: Late invoices would incur \(businessInfo.defaultCurrency.format(settings.feeAmount))/day."
        }
    }

    @ViewBuilder
    private var previewSection: some View {
        let exampleTotal = 500.0
        let exampleDaysOverdue = 14

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Example Invoice")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(businessInfo.defaultCurrency.format(exampleTotal))
            }

            HStack {
                Text("Days Overdue")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(exampleDaysOverdue) days")
            }

            Divider()

            let calculatedFee = calculateExampleFee(invoiceTotal: exampleTotal, daysOverdue: exampleDaysOverdue)

            HStack {
                Text("Late Fee")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.red)
                Spacer()
                Text(businessInfo.defaultCurrency.format(calculatedFee))
                    .foregroundColor(.red)
            }

            HStack {
                Text("Total Due")
                    .font(.subheadline.bold())
                Spacer()
                Text(businessInfo.defaultCurrency.format(exampleTotal + calculatedFee))
                    .fontWeight(.bold)
            }
        }
    }

    private func calculateExampleFee(invoiceTotal: Double, daysOverdue: Int) -> Double {
        let effectiveDays = max(0, daysOverdue - settings.gracePeriodDays)
        guard effectiveDays > 0 else { return 0 }

        var fee: Double

        switch settings.feeType {
        case .flatFee:
            fee = settings.feeAmount
        case .percentage:
            fee = invoiceTotal * (settings.feeAmount / 100)
        case .dailyPercentage:
            fee = invoiceTotal * (settings.feeAmount / 100) * Double(effectiveDays)
        case .dailyFlat:
            fee = settings.feeAmount * Double(effectiveDays)
        }

        if let maxFee = settings.maxLateFee {
            fee = min(fee, maxFee)
        }

        return fee
    }

    private func saveSettings() {
        var businessInfo = InvoiceStorage.loadBusinessInfo()
        businessInfo.defaultLateFeeSettings = settings
        InvoiceStorage.saveBusinessInfo(businessInfo)
    }
}

#Preview {
    NavigationStack {
        LateFeeSettingsView()
    }
}
