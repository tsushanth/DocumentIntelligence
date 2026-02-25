import SwiftUI

@MainActor
class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?

    private init() {}

    func sync() async {
        isSyncing = true
        defer { isSyncing = false }

        // Will integrate with iCloud sync
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        lastSyncDate = Date()
    }
}
