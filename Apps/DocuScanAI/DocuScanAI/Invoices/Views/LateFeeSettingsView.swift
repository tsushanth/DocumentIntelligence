import SwiftUI

struct LateFeeSettingsView: View {

    @State private var settings: LateFeeSettings
    @State private var maxFeeEnabled: Bool
    @State private var maxFeeAmount: String
    @FocusState private var isAmountFocused: Bool

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
                }

                Section("Fee Amount") {
                    HStack {
                        if settings.feeType == .flatFee || settings.feeType == .dailyFlat {
                            Text("$")
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
                    Section("Maximum Fee") {
                        Toggle("Cap Maximum Fee", isOn: $maxFeeEnabled)
                            .onChange(of: maxFeeEnabled) { enabled in
                                settings.maxLateFee = enabled ? (Double(maxFeeAmount) ?? 100) : nil
                                saveSettings()
                            }

                        if maxFeeEnabled {
                            HStack {
                                Text("$")
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
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Late Fees")
        .navigationBarTitleDisplayMode(.inline)
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
