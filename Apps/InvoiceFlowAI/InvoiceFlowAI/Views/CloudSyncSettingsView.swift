import SwiftUI

struct CloudSyncSettingsView: View {
    @StateObject private var syncManager = CloudSyncManager.shared
    @State private var showingBackupConfirmation = false
    @State private var showingRestoreConfirmation = false
    @State private var cloudBackupInfo: CloudBackupInfo?
    @State private var isLoadingBackupInfo = false

    var body: some View {
        Form {
            // iCloud Status
            Section {
                HStack {
                    Image(systemName: syncManager.isCloudAvailable ? "icloud.fill" : "icloud.slash.fill")
                        .font(.title2)
                        .foregroundColor(syncManager.isCloudAvailable ? .blue : .gray)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(syncManager.isCloudAvailable ? "iCloud Connected" : "iCloud Not Available")
                            .font(.headline)
                        Text(syncManager.isCloudAvailable ?
                             "Your data can be backed up to iCloud" :
                             "Sign in to iCloud in Settings to enable backup")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if !syncManager.isCloudAvailable {
                    Button(action: openSettings) {
                        Label("Open Settings", systemImage: "gear")
                    }
                }
            }

            // Last Sync Info
            if syncManager.isCloudAvailable {
                Section("Backup Status") {
                    if let lastSync = syncManager.lastSyncDate {
                        HStack {
                            Text("Last Backup")
                            Spacer()
                            Text(formatDate(lastSync))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            Text("Last Backup")
                            Spacer()
                            Text("Never")
                                .foregroundColor(.secondary)
                        }
                    }

                    // Cloud backup info
                    if let info = cloudBackupInfo {
                        HStack {
                            Text("Cloud Backup Date")
                            Spacer()
                            Text(info.formattedDate)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Invoices in Backup")
                            Spacer()
                            Text("\(info.invoiceCount)")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Clients in Backup")
                            Spacer()
                            Text("\(info.clientCount)")
                                .foregroundColor(.secondary)
                        }
                    } else if isLoadingBackupInfo {
                        HStack {
                            Text("Checking cloud backup...")
                            Spacer()
                            ProgressView()
                        }
                    }
                }

                // Backup Actions
                Section("Backup & Restore") {
                    Button(action: { showingBackupConfirmation = true }) {
                        HStack {
                            Label("Backup to iCloud", systemImage: "icloud.and.arrow.up")
                            Spacer()
                            if syncManager.isSyncing {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(syncManager.isSyncing)

                    Button(action: { showingRestoreConfirmation = true }) {
                        Label("Restore from iCloud", systemImage: "icloud.and.arrow.down")
                    }
                    .disabled(syncManager.isSyncing || cloudBackupInfo == nil)
                }

                // Error Display
                if let error = syncManager.syncError {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }

                // Info Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("About iCloud Backup", systemImage: "info.circle.fill")
                            .font(.headline)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 8) {
                            bulletPoint("Backs up all invoices, clients, estimates, and settings")
                            bulletPoint("Includes your business logo and signature")
                            bulletPoint("PDF files are also backed up")
                            bulletPoint("Restore on a new device to recover your data")
                            bulletPoint("Backups are stored securely in your iCloud account")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Cloud Backup")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCloudBackupInfo()
        }
        .confirmationDialog("Backup to iCloud?", isPresented: $showingBackupConfirmation) {
            Button("Backup Now") {
                Task {
                    await syncManager.backupToCloud()
                    loadCloudBackupInfo()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will backup all your invoices, clients, and settings to iCloud. Existing backup will be overwritten.")
        }
        .confirmationDialog("Restore from iCloud?", isPresented: $showingRestoreConfirmation) {
            Button("Restore", role: .destructive) {
                Task {
                    await syncManager.restoreFromCloud()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will replace all local data with the backup from iCloud. This action cannot be undone.")
        }
    }

    @ViewBuilder
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func loadCloudBackupInfo() {
        isLoadingBackupInfo = true
        Task {
            let info = await syncManager.getCloudBackupInfo()
            await MainActor.run {
                cloudBackupInfo = info
                isLoadingBackupInfo = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        CloudSyncSettingsView()
    }
}
