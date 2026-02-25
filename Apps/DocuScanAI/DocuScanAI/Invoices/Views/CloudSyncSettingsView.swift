import SwiftUI

struct CloudSyncSettingsView: View {
    @StateObject private var syncManager = CloudSyncManager.shared

    var body: some View {
        Form {
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
            }

            if syncManager.isCloudAvailable {
                Section("Backup Status") {
                    HStack {
                        Text("Last Backup")
                        Spacer()
                        if let lastSync = syncManager.lastSyncDate {
                            Text(lastSync, style: .date)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Never")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Actions") {
                    Button(action: backup) {
                        HStack {
                            Label("Backup to iCloud", systemImage: "icloud.and.arrow.up")
                            Spacer()
                            if syncManager.isSyncing {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(syncManager.isSyncing)

                    Button(action: restore) {
                        Label("Restore from iCloud", systemImage: "icloud.and.arrow.down")
                    }
                    .disabled(syncManager.isSyncing)
                }

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
            }
        }
        .navigationTitle("Cloud Backup")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func backup() {
        Task { await syncManager.backupToCloud() }
    }

    private func restore() {
        Task { await syncManager.restoreFromCloud() }
    }
}

#Preview {
    NavigationStack {
        CloudSyncSettingsView()
    }
}
