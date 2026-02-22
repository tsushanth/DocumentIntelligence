import Foundation
import Combine

// MARK: - Cloud Sync Manager

@MainActor
final class CloudSyncManager: ObservableObject {

    static let shared = CloudSyncManager()

    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var syncError: String?
    @Published private(set) var isCloudAvailable = false

    private let fileManager = FileManager.default
    private var metadataQuery: NSMetadataQuery?

    private init() {
        checkCloudAvailability()
        loadLastSyncDate()
    }

    // MARK: - Cloud Availability

    func checkCloudAvailability() {
        // Check if iCloud is available
        if let containerURL = fileManager.url(forUbiquityContainerIdentifier: nil) {
            isCloudAvailable = true
            print("iCloud container available at: \(containerURL)")
        } else {
            isCloudAvailable = false
            print("iCloud not available")
        }
    }

    // MARK: - Sync Operations

    /// Backup local data to iCloud
    func backupToCloud() async {
        guard isCloudAvailable else {
            syncError = "iCloud is not available. Please sign in to iCloud in Settings."
            return
        }

        guard !isSyncing else { return }

        isSyncing = true
        syncError = nil

        do {
            // Get iCloud Documents directory
            guard let cloudURL = getCloudDocumentsURL() else {
                throw CloudSyncError.cloudNotAvailable
            }

            // Create backup directory in iCloud
            let backupURL = cloudURL.appendingPathComponent("InvoiceFlowBackup", isDirectory: true)
            try createDirectoryIfNeeded(at: backupURL)

            // Backup invoices
            try await backupInvoices(to: backupURL)

            // Backup clients
            try await backupClients(to: backupURL)

            // Backup estimates
            try await backupEstimates(to: backupURL)

            // Backup recurring invoices
            try await backupRecurringInvoices(to: backupURL)

            // Backup business info (including signature)
            try await backupBusinessInfo(to: backupURL)

            // Backup item templates
            try await backupItemTemplates(to: backupURL)

            // Update last sync date
            lastSyncDate = Date()
            saveLastSyncDate()

            isSyncing = false

        } catch {
            isSyncing = false
            syncError = "Backup failed: \(error.localizedDescription)"
            print("Cloud backup error: \(error)")
        }
    }

    /// Restore data from iCloud
    func restoreFromCloud() async {
        guard isCloudAvailable else {
            syncError = "iCloud is not available. Please sign in to iCloud in Settings."
            return
        }

        guard !isSyncing else { return }

        isSyncing = true
        syncError = nil

        do {
            guard let cloudURL = getCloudDocumentsURL() else {
                throw CloudSyncError.cloudNotAvailable
            }

            let backupURL = cloudURL.appendingPathComponent("InvoiceFlowBackup", isDirectory: true)

            // Check if backup exists
            guard fileManager.fileExists(atPath: backupURL.path) else {
                throw CloudSyncError.noBackupFound
            }

            // Restore invoices
            try await restoreInvoices(from: backupURL)

            // Restore clients
            try await restoreClients(from: backupURL)

            // Restore estimates
            try await restoreEstimates(from: backupURL)

            // Restore recurring invoices
            try await restoreRecurringInvoices(from: backupURL)

            // Restore business info
            try await restoreBusinessInfo(from: backupURL)

            // Restore item templates
            try await restoreItemTemplates(from: backupURL)

            lastSyncDate = Date()
            saveLastSyncDate()

            isSyncing = false

            // Post notification to refresh UI
            NotificationCenter.default.post(name: .cloudSyncDidComplete, object: nil)

        } catch {
            isSyncing = false
            syncError = "Restore failed: \(error.localizedDescription)"
            print("Cloud restore error: \(error)")
        }
    }

    // MARK: - Backup Methods

    private func backupInvoices(to cloudURL: URL) async throws {
        let localInvoices = InvoiceStorage.loadInvoices()
        let data = try JSONEncoder().encode(localInvoices)
        let fileURL = cloudURL.appendingPathComponent("invoices.json")
        try data.write(to: fileURL)

        // Also backup PDFs
        let pdfsURL = cloudURL.appendingPathComponent("PDFs", isDirectory: true)
        try createDirectoryIfNeeded(at: pdfsURL)

        for invoice in localInvoices {
            if let pdfFileName = invoice.pdfFileName,
               let localPDFURL = invoice.pdfURL,
               fileManager.fileExists(atPath: localPDFURL.path) {
                let cloudPDFURL = pdfsURL.appendingPathComponent(pdfFileName)
                try? fileManager.copyItem(at: localPDFURL, to: cloudPDFURL)
            }
        }
    }

    private func backupClients(to cloudURL: URL) async throws {
        let clients = InvoiceStorage.loadClients()
        let data = try JSONEncoder().encode(clients)
        let fileURL = cloudURL.appendingPathComponent("clients.json")
        try data.write(to: fileURL)
    }

    private func backupEstimates(to cloudURL: URL) async throws {
        let estimates = InvoiceStorage.loadEstimates()
        let data = try JSONEncoder().encode(estimates)
        let fileURL = cloudURL.appendingPathComponent("estimates.json")
        try data.write(to: fileURL)
    }

    private func backupRecurringInvoices(to cloudURL: URL) async throws {
        let recurring = InvoiceStorage.loadRecurringInvoices()
        let data = try JSONEncoder().encode(recurring)
        let fileURL = cloudURL.appendingPathComponent("recurring.json")
        try data.write(to: fileURL)
    }

    private func backupBusinessInfo(to cloudURL: URL) async throws {
        let businessInfo = InvoiceStorage.loadBusinessInfo()
        let data = try JSONEncoder().encode(businessInfo)
        let fileURL = cloudURL.appendingPathComponent("businessInfo.json")
        try data.write(to: fileURL)
    }

    private func backupItemTemplates(to cloudURL: URL) async throws {
        let items = InvoiceStorage.loadItemTemplates()
        let data = try JSONEncoder().encode(items)
        let fileURL = cloudURL.appendingPathComponent("itemTemplates.json")
        try data.write(to: fileURL)
    }

    // MARK: - Restore Methods

    private func restoreInvoices(from cloudURL: URL) async throws {
        let fileURL = cloudURL.appendingPathComponent("invoices.json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return }

        let data = try Data(contentsOf: fileURL)
        let invoices = try JSONDecoder().decode([Invoice].self, from: data)
        InvoiceStorage.replaceAllInvoices(invoices)

        // Restore PDFs
        let pdfsURL = cloudURL.appendingPathComponent("PDFs", isDirectory: true)
        if fileManager.fileExists(atPath: pdfsURL.path) {
            let localDir = InvoiceStorage.getInvoicesDirectory()
            let contents = try? fileManager.contentsOfDirectory(at: pdfsURL, includingPropertiesForKeys: nil)
            for fileURL in contents ?? [] {
                let destURL = localDir.appendingPathComponent(fileURL.lastPathComponent)
                try? fileManager.copyItem(at: fileURL, to: destURL)
            }
        }
    }

    private func restoreClients(from cloudURL: URL) async throws {
        let fileURL = cloudURL.appendingPathComponent("clients.json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return }

        let data = try Data(contentsOf: fileURL)
        let clients = try JSONDecoder().decode([Client].self, from: data)
        InvoiceStorage.replaceAllClients(clients)
    }

    private func restoreEstimates(from cloudURL: URL) async throws {
        let fileURL = cloudURL.appendingPathComponent("estimates.json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return }

        let data = try Data(contentsOf: fileURL)
        let estimates = try JSONDecoder().decode([Estimate].self, from: data)
        InvoiceStorage.replaceAllEstimates(estimates)
    }

    private func restoreRecurringInvoices(from cloudURL: URL) async throws {
        let fileURL = cloudURL.appendingPathComponent("recurring.json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return }

        let data = try Data(contentsOf: fileURL)
        let recurring = try JSONDecoder().decode([RecurringInvoice].self, from: data)
        InvoiceStorage.replaceAllRecurringInvoices(recurring)
    }

    private func restoreBusinessInfo(from cloudURL: URL) async throws {
        let fileURL = cloudURL.appendingPathComponent("businessInfo.json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return }

        let data = try Data(contentsOf: fileURL)
        let businessInfo = try JSONDecoder().decode(BusinessInfo.self, from: data)
        InvoiceStorage.saveBusinessInfo(businessInfo)
    }

    private func restoreItemTemplates(from cloudURL: URL) async throws {
        let fileURL = cloudURL.appendingPathComponent("itemTemplates.json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return }

        let data = try Data(contentsOf: fileURL)
        let items = try JSONDecoder().decode([ItemTemplate].self, from: data)
        InvoiceStorage.replaceAllItemTemplates(items)
    }

    // MARK: - Helpers

    private func getCloudDocumentsURL() -> URL? {
        return fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
    }

    private func createDirectoryIfNeeded(at url: URL) throws {
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private func loadLastSyncDate() {
        if let date = UserDefaults.standard.object(forKey: "CloudSyncLastDate") as? Date {
            lastSyncDate = date
        }
    }

    private func saveLastSyncDate() {
        UserDefaults.standard.set(lastSyncDate, forKey: "CloudSyncLastDate")
    }

    /// Get backup info from iCloud
    func getCloudBackupInfo() async -> CloudBackupInfo? {
        guard isCloudAvailable,
              let cloudURL = getCloudDocumentsURL() else {
            return nil
        }

        let backupURL = cloudURL.appendingPathComponent("InvoiceFlowBackup", isDirectory: true)

        guard fileManager.fileExists(atPath: backupURL.path) else {
            return nil
        }

        // Get backup modification date
        let attributes = try? fileManager.attributesOfItem(atPath: backupURL.path)
        let modDate = attributes?[.modificationDate] as? Date

        // Count items
        var invoiceCount = 0
        var clientCount = 0

        if let invoicesURL = try? backupURL.appendingPathComponent("invoices.json"),
           let data = try? Data(contentsOf: invoicesURL),
           let invoices = try? JSONDecoder().decode([Invoice].self, from: data) {
            invoiceCount = invoices.count
        }

        if let clientsURL = try? backupURL.appendingPathComponent("clients.json"),
           let data = try? Data(contentsOf: clientsURL),
           let clients = try? JSONDecoder().decode([Client].self, from: data) {
            clientCount = clients.count
        }

        return CloudBackupInfo(
            date: modDate ?? Date(),
            invoiceCount: invoiceCount,
            clientCount: clientCount
        )
    }
}

// MARK: - Cloud Sync Error

enum CloudSyncError: LocalizedError {
    case cloudNotAvailable
    case noBackupFound
    case backupFailed(String)
    case restoreFailed(String)

    var errorDescription: String? {
        switch self {
        case .cloudNotAvailable:
            return "iCloud is not available. Please sign in to iCloud in Settings."
        case .noBackupFound:
            return "No backup found in iCloud. Please create a backup first."
        case .backupFailed(let reason):
            return "Backup failed: \(reason)"
        case .restoreFailed(let reason):
            return "Restore failed: \(reason)"
        }
    }
}

// MARK: - Cloud Backup Info

struct CloudBackupInfo {
    let date: Date
    let invoiceCount: Int
    let clientCount: Int

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let cloudSyncDidComplete = Notification.Name("cloudSyncDidComplete")
}
