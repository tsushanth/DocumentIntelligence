import SwiftUI
import PhotosUI
import StoreKit
import DocumentCore

struct InvoiceSettingsView: View {

    @EnvironmentObject var appState: InvoiceAppState
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingPaywall = false
    @State private var businessName = ""
    @State private var businessEmail = ""
    @State private var businessAddress = ""
    @State private var businessPhone = ""
    @State private var defaultTaxRate = 8.0
    @State private var defaultCurrency: Currency = .usd

    // Logo picker - use direct PhotosPicker instead of confirmationDialog
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var logoImage: UIImage?
    
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
                        .onChange(of: businessName) { _ in saveBusinessInfo() }

                    TextField("Email", text: $businessEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .onChange(of: businessEmail) { _ in saveBusinessInfo() }

                    TextField("Address", text: $businessAddress)
                        .onChange(of: businessAddress) { _ in saveBusinessInfo() }

                    TextField("Phone", text: $businessPhone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .onChange(of: businessPhone) { _ in saveBusinessInfo() }
                }

                // Logo Section
                Section("Business Logo") {
                    HStack {
                        if let logo = logoImage {
                            Image(uiImage: logo)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(logoImage == nil ? "No logo set" : "Logo uploaded")
                                .font(.subheadline)
                            Text("Appears on your invoices")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Use PhotosPicker directly instead of inside confirmationDialog
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Text(logoImage == nil ? "Add" : "Change")
                                .foregroundColor(.green)
                        }
                    }

                    if logoImage != nil {
                        Button(role: .destructive) {
                            removeLogo()
                        } label: {
                            Label("Remove Logo", systemImage: "trash")
                        }
                    }
                }

                // Signature Section
                Section("Signature") {
                    NavigationLink(destination: SignatureSettingsView()) {
                        HStack {
                            Label {
                                VStack(alignment: .leading) {
                                    Text("Your Signature")
                                    Text(InvoiceStorage.loadBusinessInfo().signatureData != nil ? "Configured" : "Not set")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } icon: {
                                Image(systemName: "signature")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }

                // Invoice Settings
                Section("Invoice Defaults") {
                    Picker("Default Currency", selection: $defaultCurrency) {
                        ForEach(Currency.popular) { currency in
                            Text(currency.shortDisplayName).tag(currency)
                        }
                        Divider()
                        ForEach(Currency.allCases.filter { !Currency.popular.contains($0) }.sorted { $0.name < $1.name }) { currency in
                            Text(currency.displayName).tag(currency)
                        }
                    }
                    .onChange(of: defaultCurrency) { _ in saveCurrency() }

                    HStack {
                        Text("Tax Rate")
                        Spacer()
                        TextField("Rate", value: $defaultTaxRate, format: .percent)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    NavigationLink(destination: InvoiceNumberSettingsView()) {
                        HStack {
                            Text("Invoice Numbering")
                            Spacer()
                            Text(InvoiceStorage.loadBusinessInfo().invoiceNumberSettings.previewNumber)
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }

                // Payment Details
                Section("Payment Information") {
                    NavigationLink(destination: PaymentDetailsSettingsView()) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Payment Details")
                                Text("Bank, PayPal, Venmo, etc.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.green)
                        }
                    }
                }

                // Recurring Invoices
                Section("Automation") {
                    NavigationLink(destination: RecurringInvoiceListView()) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Recurring Invoices")
                                Text("Set up automatic billing")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "repeat.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }

                    NavigationLink(destination: LateFeeSettingsView()) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Late Fees")
                                Text(InvoiceStorage.loadBusinessInfo().defaultLateFeeSettings.enabled ? "Enabled" : "Disabled")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }

                // Notifications
                Section("Notifications") {
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Overdue Reminders")
                                Text(notificationManager.settings.overdueRemindersEnabled ? "Enabled" : "Disabled")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.orange)
                        }
                    }
                }

                // Export & Backup
                Section("Data") {
                    NavigationLink(destination: ExportDataView()) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Export Data")
                                Text("CSV for accounting software")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "square.and.arrow.up.fill")
                                .foregroundColor(.purple)
                        }
                    }

                    NavigationLink(destination: CloudSyncSettingsView()) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Cloud Backup")
                                Text("Backup & restore from iCloud")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "icloud.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                    Link(destination: URL(string: "https://kreativekoala.llc/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                        Label("Terms of Use (EULA)", systemImage: "doc.text")
                    }
                    Button(action: {
                        Task {
                            await appState.restorePurchases()
                        }
                    }) {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                loadBusinessInfo()
            }
            .sheet(isPresented: $showingPaywall) {
                InvoiceFlowPaywallView()
            }
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            logoImage = image
                            saveLogo(image)
                        }
                    }
                }
            }
        }
    }

    private func loadBusinessInfo() {
        let info = InvoiceStorage.loadBusinessInfo()
        businessName = info.name
        businessEmail = info.email
        businessAddress = info.address
        businessPhone = info.phone
        defaultCurrency = info.defaultCurrency
        if let logoData = info.logoData {
            logoImage = UIImage(data: logoData)
        }
    }

    private func saveBusinessInfo() {
        var info = InvoiceStorage.loadBusinessInfo()
        info.name = businessName
        info.email = businessEmail
        info.address = businessAddress
        info.phone = businessPhone
        InvoiceStorage.saveBusinessInfo(info)
    }

    private func saveCurrency() {
        var info = InvoiceStorage.loadBusinessInfo()
        info.defaultCurrency = defaultCurrency
        InvoiceStorage.saveBusinessInfo(info)
    }

    private func saveLogo(_ image: UIImage) {
        var info = InvoiceStorage.loadBusinessInfo()
        // Resize logo to reasonable size
        let maxSize: CGFloat = 300
        let scale = min(maxSize / image.size.width, maxSize / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        info.logoData = resizedImage?.pngData()
        InvoiceStorage.saveBusinessInfo(info)
    }

    private func removeLogo() {
        logoImage = nil
        var info = InvoiceStorage.loadBusinessInfo()
        info.logoData = nil
        InvoiceStorage.saveBusinessInfo(info)
    }
}

// MARK: - Invoice Number Settings

struct InvoiceNumberSettingsView: View {
    @State private var settings: InvoiceNumberSettings = InvoiceNumberSettings()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                VStack(spacing: 8) {
                    Text("Preview")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(settings.previewNumber)
                        .font(.title2.monospaced())
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Format") {
                HStack {
                    Text("Prefix")
                    Spacer()
                    TextField("INV", text: $settings.prefix)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textInputAutocapitalization(.characters)
                }

                Toggle("Include Date", isOn: $settings.includeDate)

                if settings.includeDate {
                    Picker("Date Format", selection: $settings.dateFormat) {
                        ForEach(InvoiceNumberSettings.DateFormatOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                }

                Picker("Separator", selection: $settings.separator) {
                    Text("Dash (-)").tag("-")
                    Text("Underscore (_)").tag("_")
                    Text("Slash (/)").tag("/")
                    Text("None").tag("")
                }

                Stepper("Number Digits: \(settings.digitCount)", value: $settings.digitCount, in: 1...6)
            }

            Section("Sequence") {
                Stepper("Next Number: \(settings.nextNumber)", value: $settings.nextNumber, in: 1...99999)

                Text("The next invoice created will use this number")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                Button("Reset to Defaults") {
                    settings = InvoiceNumberSettings()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Invoice Numbering")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            settings = InvoiceStorage.loadBusinessInfo().invoiceNumberSettings
        }
        .onDisappear {
            saveSettings()
        }
        .onChange(of: settings.prefix) { _ in saveSettings() }
        .onChange(of: settings.includeDate) { _ in saveSettings() }
        .onChange(of: settings.dateFormat) { _ in saveSettings() }
        .onChange(of: settings.separator) { _ in saveSettings() }
        .onChange(of: settings.digitCount) { _ in saveSettings() }
        .onChange(of: settings.nextNumber) { _ in saveSettings() }
    }

    private func saveSettings() {
        var info = InvoiceStorage.loadBusinessInfo()
        info.invoiceNumberSettings = settings
        InvoiceStorage.saveBusinessInfo(info)
    }
}

struct InvoiceFlowPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: InvoiceAppState
    @StateObject private var storeKit = StoreKitManager.shared
    @State private var selectedPlan: PlanType = .monthly
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    enum PlanType {
        case monthly, yearly
    }

    // Get the selected product from StoreKit
    private var selectedProduct: Product? {
        let productID = selectedPlan == .monthly
            ? StoreKitManager.ProductID.invoiceFlowPro
            : StoreKitManager.ProductID.invoiceFlowProYearly
        return storeKit.products.first { $0.id == productID }
    }

    // Get introductory offer text if available
    private var introductoryOfferText: String? {
        guard let product = selectedProduct,
              let subscription = product.subscription,
              let introOffer = subscription.introductoryOffer else {
            return nil
        }

        switch introOffer.type {
        case .introductory:
            return "\(introOffer.period.value) \(introOffer.period.unit.localizedDescription) free trial for new subscribers"
        case .promotional:
            return nil
        default:
            return nil
        }
    }

    // Get monthly product price
    private var monthlyPrice: String {
        if let product = storeKit.products.first(where: { $0.id == StoreKitManager.ProductID.invoiceFlowPro }) {
            return product.displayPrice + "/month"
        }
        return "$6.99/month"
    }

    // Get yearly product price
    private var yearlyPrice: String {
        if let product = storeKit.products.first(where: { $0.id == StoreKitManager.ProductID.invoiceFlowProYearly }) {
            return product.displayPrice + "/year"
        }
        return "$49.99/year"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
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

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        proFeature("infinity", "Unlimited Invoices", "No monthly limits")
                        proFeature("mic.fill", "Voice to Invoice", "Create invoices by speaking")
                        proFeature("camera.fill", "Receipt Scanning", "Auto-create expenses")
                        proFeature("person.2.fill", "Client Database", "Save client info")
                        proFeature("repeat", "Recurring Invoices", "Set up auto-billing")
                        proFeature("dollarsign.circle", "Payment Tracking", "Track who's paid")
                    }
                    .padding(.horizontal, 24)

                    // Plan Selection
                    VStack(spacing: 12) {
                        planOption(
                            type: .yearly,
                            title: "Yearly",
                            price: yearlyPrice,
                            subtitle: "Save 40% - Best Value",
                            isSelected: selectedPlan == .yearly
                        )

                        planOption(
                            type: .monthly,
                            title: "Monthly",
                            price: monthlyPrice,
                            subtitle: "Cancel anytime",
                            isSelected: selectedPlan == .monthly
                        )
                    }
                    .padding(.horizontal, 24)

                    // Subscribe Button
                    Button(action: purchase) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isPurchasing ? "Processing..." : "Subscribe Now")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    .disabled(isPurchasing)
                    .padding(.horizontal, 24)

                    // Restore & Terms
                    VStack(spacing: 8) {
                        Button("Restore Purchases") {
                            Task {
                                await appState.restorePurchases()
                                if appState.isProUser {
                                    dismiss()
                                }
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                        // Only show introductory offer if product actually has one configured
                        if let offerText = introductoryOfferText {
                            Text(offerText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 16) {
                            Link("Privacy Policy", destination: URL(string: "https://kreativekoala.llc/privacy")!)
                            Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Purchase Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .task {
                // Ensure products are loaded
                if storeKit.products.isEmpty {
                    await storeKit.loadProducts()
                }
            }
        }
    }

    private func planOption(type: PlanType, title: String, price: String, subtitle: String, isSelected: Bool) -> some View {
        Button(action: { selectedPlan = type }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(price)
                    .font(.subheadline.bold())
                    .foregroundColor(isSelected ? .green : .primary)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
                    .font(.title2)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
    }

    private func purchase() {
        isPurchasing = true

        Task {
            do {
                let productID = selectedPlan == .monthly
                    ? StoreKitManager.ProductID.invoiceFlowPro
                    : StoreKitManager.ProductID.invoiceFlowProYearly

                guard let product = storeKit.products.first(where: { $0.id == productID }) else {
                    // If products not loaded yet, try loading
                    await storeKit.loadProducts()
                    guard let product = storeKit.products.first(where: { $0.id == productID }) else {
                        throw StoreKitError.productNotFound
                    }
                    _ = try await storeKit.purchase(product)
                    await MainActor.run {
                        appState.isProUser = storeKit.hasActiveSubscription
                        if appState.isProUser { dismiss() }
                    }
                    return
                }

                _ = try await storeKit.purchase(product)
                await MainActor.run {
                    appState.isProUser = storeKit.hasActiveSubscription
                    if appState.isProUser { dismiss() }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }

            await MainActor.run {
                isPurchasing = false
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

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingPermissionAlert = false

    var body: some View {
        Form {
            // Authorization Status
            Section {
                HStack {
                    Image(systemName: notificationManager.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(notificationManager.isAuthorized ? .green : .red)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(notificationManager.isAuthorized ? "Notifications Enabled" : "Notifications Disabled")
                            .font(.headline)
                        Text(notificationManager.isAuthorized ? "You'll receive reminders for overdue invoices" : "Enable notifications in Settings to receive reminders")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if !notificationManager.isAuthorized {
                    Button(action: requestPermission) {
                        Label("Enable Notifications", systemImage: "bell.badge")
                    }
                }
            }

            // Overdue Reminders
            Section("Overdue Reminders") {
                Toggle("Enable Overdue Reminders", isOn: $notificationManager.settings.overdueRemindersEnabled)
                    .onChange(of: notificationManager.settings.overdueRemindersEnabled) { enabled in
                        if enabled && !notificationManager.isAuthorized {
                            requestPermission()
                        }
                        saveAndRefresh()
                    }

                if notificationManager.settings.overdueRemindersEnabled {
                    DatePicker(
                        "Reminder Time",
                        selection: $notificationManager.settings.reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .onChange(of: notificationManager.settings.reminderTime) { _ in
                        saveAndRefresh()
                    }

                    Toggle("Repeat Reminders", isOn: $notificationManager.settings.repeatOverdueReminders)
                        .onChange(of: notificationManager.settings.repeatOverdueReminders) { _ in
                            saveAndRefresh()
                        }

                    if notificationManager.settings.repeatOverdueReminders {
                        Picker("Reminder Frequency", selection: $notificationManager.settings.overdueReminderFrequency) {
                            ForEach(NotificationSettings.ReminderFrequency.allCases, id: \.self) { freq in
                                Text(freq.displayName).tag(freq)
                            }
                        }
                        .onChange(of: notificationManager.settings.overdueReminderFrequency) { _ in
                            saveAndRefresh()
                        }
                    }
                }
            }

            // Due Date Reminders
            Section("Due Date Reminders") {
                Stepper(
                    "Remind \(notificationManager.settings.dueDateReminderDays) day(s) before due",
                    value: $notificationManager.settings.dueDateReminderDays,
                    in: 1...7
                )
                .onChange(of: notificationManager.settings.dueDateReminderDays) { _ in
                    saveAndRefresh()
                }

                Text("Get notified before invoices become overdue")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Status
            if notificationManager.settings.overdueRemindersEnabled {
                Section("Current Status") {
                    let overdueCount = InvoiceStorage.getOverdueInvoices().count
                    HStack {
                        Text("Overdue Invoices")
                        Spacer()
                        Text("\(overdueCount)")
                            .foregroundColor(overdueCount > 0 ? .red : .green)
                            .fontWeight(.semibold)
                    }

                    if overdueCount > 0 {
                        Text("You will receive reminders for these invoices")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await notificationManager.checkAuthorizationStatus()
            }
        }
        .alert("Enable Notifications", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                notificationManager.settings.overdueRemindersEnabled = false
                notificationManager.saveSettings()
            }
        } message: {
            Text("Please enable notifications in Settings to receive overdue invoice reminders.")
        }
    }

    private func requestPermission() {
        Task {
            let granted = await notificationManager.requestAuthorization()
            if !granted {
                await MainActor.run {
                    showingPermissionAlert = true
                }
            } else {
                await MainActor.run {
                    saveAndRefresh()
                }
            }
        }
    }

    private func saveAndRefresh() {
        notificationManager.saveSettings()
        notificationManager.refreshAllNotifications()
    }
}

// MARK: - Recurring Invoices List

struct RecurringInvoiceListView: View {

    @State private var recurringInvoices: [RecurringInvoice] = []
    @State private var showingCreateSheet = false

    var body: some View {
        List {
            if recurringInvoices.isEmpty {
                emptyState
            } else {
                ForEach(recurringInvoices) { recurring in
                    RecurringInvoiceRow(recurring: recurring)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteRecurring(recurring)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                toggleActive(recurring)
                            } label: {
                                Label(
                                    recurring.isActive ? "Pause" : "Resume",
                                    systemImage: recurring.isActive ? "pause.circle" : "play.circle"
                                )
                            }
                            .tint(recurring.isActive ? .orange : .green)
                        }
                }
            }
        }
        .navigationTitle("Recurring Invoices")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCreateSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            loadData()
            InvoiceStorage.processRecurringInvoices()
        }
        .onReceive(NotificationCenter.default.publisher(for: .recurringInvoicesDidUpdate)) { _ in
            loadData()
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateRecurringInvoiceView()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "repeat.circle")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("No Recurring Invoices")
                .font(.headline)

            Text("Set up automatic invoicing for clients you bill regularly")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { showingCreateSheet = true }) {
                Label("Create Recurring Invoice", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
    }

    private func loadData() {
        recurringInvoices = InvoiceStorage.loadRecurringInvoices()
    }

    private func deleteRecurring(_ recurring: RecurringInvoice) {
        InvoiceStorage.deleteRecurringInvoice(recurring)
        NotificationCenter.default.post(name: .recurringInvoicesDidUpdate, object: nil)
    }

    private func toggleActive(_ recurring: RecurringInvoice) {
        var updated = recurring
        updated.isActive.toggle()
        InvoiceStorage.updateRecurringInvoice(updated)
        NotificationCenter.default.post(name: .recurringInvoicesDidUpdate, object: nil)
    }
}

// MARK: - Recurring Invoice Row

struct RecurringInvoiceRow: View {
    let recurring: RecurringInvoice

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(recurring.isActive ? Color.green : Color.gray)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(recurring.clientName)
                    .font(.headline)

                HStack {
                    Text(recurring.frequency.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)

                    Text(recurring.formattedTotal)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if recurring.isActive {
                    Text("Next: \(recurring.formattedNextDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Paused")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            Text("\(recurring.generatedInvoiceIds.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            Image(systemName: "doc.text")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Recurring Invoice View

struct CreateRecurringInvoiceView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateRecurringInvoiceViewModel()
    @State private var showingAddItem = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    NavigationLink(destination: SelectClientView(selectedClient: $viewModel.selectedClient)) {
                        HStack {
                            Text("Client")
                            Spacer()
                            Text(viewModel.selectedClient?.name ?? "Select")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Schedule") {
                    Picker("Frequency", selection: $viewModel.frequency) {
                        ForEach(RecurringInvoice.Frequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }

                    DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: .date)

                    Toggle("Has End Date", isOn: $viewModel.hasEndDate)

                    if viewModel.hasEndDate {
                        DatePicker("End Date", selection: $viewModel.endDate, displayedComponents: .date)
                    }
                }

                Section("Items") {
                    ForEach(Array(viewModel.lineItems.enumerated()), id: \.element.id) { index, item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.description)
                                    .font(.body)
                                Text("\(item.quantity, specifier: "%.0f") x \(item.formattedUnitPrice)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(item.formattedAmount)
                                .fontWeight(.medium)
                        }
                    }
                    .onDelete(perform: viewModel.deleteItem)

                    Button(action: { showingAddItem = true }) {
                        Label("Add Item", systemImage: "plus.circle.fill")
                    }
                }

                Section("Tax") {
                    HStack {
                        Text("Tax Rate")
                        Spacer()
                        TextField("0", value: $viewModel.taxRate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("%")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Summary") {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(viewModel.formattedSubtotal)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Tax")
                        Spacer()
                        Text(viewModel.formattedTax)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Total per Invoice")
                            .fontWeight(.bold)
                        Spacer()
                        Text(viewModel.formattedTotal)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }

                Section("Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("First invoice will be generated on:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.startDate.formatted(date: .long, time: .omitted))
                            .fontWeight(.medium)

                        Text("Then repeats \(viewModel.frequency.displayName.lowercased())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Recurring Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        viewModel.createRecurringInvoice()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isValid)
                }
            }
            .sheet(isPresented: $showingAddItem) {
                EditLineItemSheet(
                    mode: .add,
                    onSave: { description, quantity, unitPrice in
                        let item = LineItem(description: description, quantity: quantity, unitPrice: unitPrice)
                        viewModel.lineItems.append(item)
                    }
                )
            }
        }
    }
}

// MARK: - Create Recurring Invoice ViewModel

@MainActor
class CreateRecurringInvoiceViewModel: ObservableObject {

    @Published var selectedClient: Client?
    @Published var frequency: RecurringInvoice.Frequency = .monthly
    @Published var startDate = Date()
    @Published var hasEndDate = false
    @Published var endDate = Date().addingTimeInterval(365 * 24 * 60 * 60)
    @Published var lineItems: [LineItem] = []
    @Published var taxRate: Double = 8.0
    @Published var notes: String = ""

    var subtotal: Double {
        lineItems.reduce(0) { $0 + $1.amount }
    }

    var tax: Double {
        subtotal * (taxRate / 100)
    }

    var total: Double {
        subtotal + tax
    }

    var formattedSubtotal: String {
        formatCurrency(subtotal)
    }

    var formattedTax: String {
        formatCurrency(tax)
    }

    var formattedTotal: String {
        formatCurrency(total)
    }

    var isValid: Bool {
        selectedClient != nil && !lineItems.isEmpty
    }

    func deleteItem(at offsets: IndexSet) {
        lineItems.remove(atOffsets: offsets)
    }

    func createRecurringInvoice() {
        guard let client = selectedClient else { return }

        let templateInvoice = Invoice(
            invoiceNumber: "",
            clientName: client.name,
            clientEmail: client.email,
            clientAddress: client.address,
            date: Date(),
            dueDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
            lineItems: lineItems,
            taxRate: taxRate,
            notes: notes.isEmpty ? nil : notes,
            status: .draft,
            pdfFileName: nil
        )

        let recurring = RecurringInvoice(
            templateInvoice: templateInvoice,
            frequency: frequency,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            nextGenerationDate: startDate,
            isActive: true
        )

        InvoiceStorage.addRecurringInvoice(recurring)
        NotificationCenter.default.post(name: .recurringInvoicesDidUpdate, object: nil)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let businessInfo = InvoiceStorage.loadBusinessInfo()
        return businessInfo.defaultCurrency.format(amount)
    }
}

// MARK: - Payment Details Settings View

struct PaymentDetailsSettingsView: View {
    @State private var paymentDetails: PaymentDetails = PaymentDetails()
    @State private var showingPreview = false

    var body: some View {
        Form {
            // Info Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Payment details appear at the bottom of your invoices", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Bank Transfer
            Section {
                Toggle(isOn: $paymentDetails.showBankDetails) {
                    Label {
                        Text("Bank Transfer")
                    } icon: {
                        Image(systemName: "building.columns.fill")
                            .foregroundColor(.blue)
                    }
                }
                .onChange(of: paymentDetails.showBankDetails) { _ in saveSettings() }

                if paymentDetails.showBankDetails {
                    TextField("Bank Name", text: $paymentDetails.bankName)
                        .onChange(of: paymentDetails.bankName) { _ in saveSettings() }

                    TextField("Account Name", text: $paymentDetails.accountName)
                        .onChange(of: paymentDetails.accountName) { _ in saveSettings() }

                    TextField("Account Number", text: $paymentDetails.accountNumber)
                        .keyboardType(.numberPad)
                        .onChange(of: paymentDetails.accountNumber) { _ in saveSettings() }

                    TextField("Routing Number (ABA)", text: $paymentDetails.routingNumber)
                        .keyboardType(.numberPad)
                        .onChange(of: paymentDetails.routingNumber) { _ in saveSettings() }

                    TextField("SWIFT Code (International)", text: $paymentDetails.swiftCode)
                        .textInputAutocapitalization(.characters)
                        .onChange(of: paymentDetails.swiftCode) { _ in saveSettings() }

                    TextField("IBAN (International)", text: $paymentDetails.iban)
                        .textInputAutocapitalization(.characters)
                        .onChange(of: paymentDetails.iban) { _ in saveSettings() }
                }
            } header: {
                Text("Bank Transfer")
            } footer: {
                if paymentDetails.showBankDetails {
                    Text("Clients can pay via wire transfer or ACH")
                }
            }

            // PayPal
            Section {
                Toggle(isOn: $paymentDetails.showPayPal) {
                    Label {
                        Text("PayPal")
                    } icon: {
                        Image(systemName: "p.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                .onChange(of: paymentDetails.showPayPal) { _ in saveSettings() }

                if paymentDetails.showPayPal {
                    TextField("PayPal Email", text: $paymentDetails.paypalEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .onChange(of: paymentDetails.paypalEmail) { _ in saveSettings() }

                    TextField("PayPal.me Username", text: $paymentDetails.paypalMeLink)
                        .autocapitalization(.none)
                        .onChange(of: paymentDetails.paypalMeLink) { _ in saveSettings() }

                    if !paymentDetails.paypalMeLink.isEmpty {
                        HStack {
                            Text("Link Preview")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("paypal.me/\(paymentDetails.paypalMeLink)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            } header: {
                Text("PayPal")
            } footer: {
                if paymentDetails.showPayPal {
                    Text("Adds a Pay with PayPal button to invoices")
                }
            }

            // Venmo
            Section {
                Toggle(isOn: $paymentDetails.showVenmo) {
                    Label {
                        Text("Venmo")
                    } icon: {
                        Image(systemName: "v.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                .onChange(of: paymentDetails.showVenmo) { _ in saveSettings() }

                if paymentDetails.showVenmo {
                    TextField("Venmo Username", text: $paymentDetails.venmoUsername)
                        .autocapitalization(.none)
                        .onChange(of: paymentDetails.venmoUsername) { _ in saveSettings() }

                    if !paymentDetails.venmoUsername.isEmpty {
                        HStack {
                            Text("Username")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("@\(paymentDetails.venmoUsername)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            } header: {
                Text("Venmo")
            }

            // Zelle
            Section {
                Toggle(isOn: $paymentDetails.showZelle) {
                    Label {
                        Text("Zelle")
                    } icon: {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.purple)
                    }
                }
                .onChange(of: paymentDetails.showZelle) { _ in saveSettings() }

                if paymentDetails.showZelle {
                    TextField("Zelle Email", text: $paymentDetails.zelleEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .onChange(of: paymentDetails.zelleEmail) { _ in saveSettings() }

                    TextField("Zelle Phone", text: $paymentDetails.zellePhone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .onChange(of: paymentDetails.zellePhone) { _ in saveSettings() }
                }
            } header: {
                Text("Zelle")
            }

            // Stripe Payment Link
            Section {
                Toggle(isOn: $paymentDetails.showStripePayment) {
                    Label {
                        Text("Stripe Pay Now Button")
                    } icon: {
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(.indigo)
                    }
                }
                .onChange(of: paymentDetails.showStripePayment) { _ in saveSettings() }

                if paymentDetails.showStripePayment {
                    TextField("Stripe Payment Link URL", text: $paymentDetails.stripePaymentLinkBase)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .onChange(of: paymentDetails.stripePaymentLinkBase) { _ in saveSettings() }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("How to get your Stripe Payment Link:")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("1. Go to Stripe Dashboard → Payment Links")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("2. Create a new payment link (or use existing)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("3. Copy the link and paste it above")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Online Payments")
            } footer: {
                if paymentDetails.showStripePayment {
                    Text("Adds a clickable 'Pay Now' button to invoices for instant card payments")
                }
            }

            // Custom Instructions
            Section {
                Toggle(isOn: $paymentDetails.showCustomInstructions) {
                    Label {
                        Text("Custom Instructions")
                    } icon: {
                        Image(systemName: "text.alignleft")
                            .foregroundColor(.orange)
                    }
                }
                .onChange(of: paymentDetails.showCustomInstructions) { _ in saveSettings() }

                if paymentDetails.showCustomInstructions {
                    TextEditor(text: $paymentDetails.customInstructions)
                        .frame(minHeight: 100)
                        .onChange(of: paymentDetails.customInstructions) { _ in saveSettings() }

                    Text("Add any additional payment instructions (e.g., check mailing address, crypto wallets)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Custom")
            }

            // Preview Section
            if paymentDetails.hasAnyPaymentMethod {
                Section("Preview") {
                    PaymentDetailsPreview(paymentDetails: paymentDetails)
                }
            }
        }
        .navigationTitle("Payment Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadSettings()
        }
    }

    private func loadSettings() {
        paymentDetails = InvoiceStorage.loadBusinessInfo().paymentDetails
    }

    private func saveSettings() {
        var info = InvoiceStorage.loadBusinessInfo()
        info.paymentDetails = paymentDetails
        InvoiceStorage.saveBusinessInfo(info)
    }
}

// MARK: - Payment Details Preview

struct PaymentDetailsPreview: View {
    let paymentDetails: PaymentDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PAYMENT METHODS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)

            if paymentDetails.showBankDetails {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Bank Transfer", systemImage: "building.columns.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Group {
                        if !paymentDetails.bankName.isEmpty {
                            Text("Bank: \(paymentDetails.bankName)")
                        }
                        if !paymentDetails.accountName.isEmpty {
                            Text("Name: \(paymentDetails.accountName)")
                        }
                        if !paymentDetails.accountNumber.isEmpty {
                            Text("Account: ****\(String(paymentDetails.accountNumber.suffix(4)))")
                        }
                        if !paymentDetails.routingNumber.isEmpty {
                            Text("Routing: \(paymentDetails.routingNumber)")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }

            if paymentDetails.showPayPal && (!paymentDetails.paypalEmail.isEmpty || !paymentDetails.paypalMeLink.isEmpty) {
                HStack {
                    Label("Pay with PayPal", systemImage: "p.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }

            if paymentDetails.showVenmo && !paymentDetails.venmoUsername.isEmpty {
                HStack {
                    Label("Pay with Venmo", systemImage: "v.circle.fill")
                    Spacer()
                    Text("@\(paymentDetails.venmoUsername)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }

            if paymentDetails.showZelle && (!paymentDetails.zelleEmail.isEmpty || !paymentDetails.zellePhone.isEmpty) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Zelle", systemImage: "dollarsign.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if !paymentDetails.zelleEmail.isEmpty {
                        Text(paymentDetails.zelleEmail)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if !paymentDetails.zellePhone.isEmpty {
                        Text(paymentDetails.zellePhone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(8)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)
            }

            if paymentDetails.showStripePayment && !paymentDetails.stripePaymentLinkBase.isEmpty {
                HStack {
                    Spacer()
                    Label("Pay Now", systemImage: "creditcard.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.indigo)
                        .cornerRadius(8)
                    Spacer()
                }
            }

            if paymentDetails.showCustomInstructions && !paymentDetails.customInstructions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Additional Instructions")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text(paymentDetails.customInstructions)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    InvoiceSettingsView()
        .environmentObject(InvoiceAppState())
}
