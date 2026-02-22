import Foundation
import Network

/// Monitors network connectivity status for offline mode support
@MainActor
final class NetworkMonitor: ObservableObject {

    static let shared = NetworkMonitor()

    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: ConnectionType = .unknown
    @Published private(set) var isExpensive: Bool = false
    @Published private(set) var isConstrained: Bool = false

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")

    enum ConnectionType: String {
        case wifi = "WiFi"
        case cellular = "Cellular"
        case wiredEthernet = "Ethernet"
        case unknown = "Unknown"

        var icon: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .wiredEthernet: return "cable.connector"
            case .unknown: return "network"
            }
        }
    }

    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateStatus(path: path)
            }
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    private func updateStatus(path: NWPath) {
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained

        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else {
            connectionType = .unknown
        }

        // Post notification for other parts of the app
        NotificationCenter.default.post(
            name: .networkStatusDidChange,
            object: nil,
            userInfo: ["isConnected": isConnected]
        )
    }

    /// Check if AI features are available (requires network)
    var canUseAIFeatures: Bool {
        isConnected
    }

    /// Check if sync features are available
    var canSync: Bool {
        isConnected && !isConstrained
    }
}

// MARK: - Notification Name Extension

extension Notification.Name {
    static let networkStatusDidChange = Notification.Name("networkStatusDidChange")
}

// MARK: - Pending Operations Queue

/// Manages operations that failed due to offline status
@MainActor
final class OfflineOperationQueue: ObservableObject {

    static let shared = OfflineOperationQueue()

    @Published private(set) var pendingOperations: [PendingOperation] = []

    private let storageKey = "pending_offline_operations"

    struct PendingOperation: Codable, Identifiable {
        let id: UUID
        let type: OperationType
        let data: Data
        let createdAt: Date

        enum OperationType: String, Codable {
            case syncInvoice
            case sendEmail
            case aiExtraction
        }
    }

    private init() {
        loadPendingOperations()
        setupNetworkObserver()
    }

    private func loadPendingOperations() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let operations = try? JSONDecoder().decode([PendingOperation].self, from: data) {
            pendingOperations = operations
        }
    }

    private func savePendingOperations() {
        if let data = try? JSONEncoder().encode(pendingOperations) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func addOperation(type: PendingOperation.OperationType, data: Data) {
        let operation = PendingOperation(
            id: UUID(),
            type: type,
            data: data,
            createdAt: Date()
        )
        pendingOperations.append(operation)
        savePendingOperations()
    }

    func removeOperation(_ operation: PendingOperation) {
        pendingOperations.removeAll { $0.id == operation.id }
        savePendingOperations()
    }

    func clearAllOperations() {
        pendingOperations.removeAll()
        savePendingOperations()
    }

    private func setupNetworkObserver() {
        NotificationCenter.default.addObserver(
            forName: .networkStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let isConnected = notification.userInfo?["isConnected"] as? Bool,
               isConnected {
                Task { @MainActor in
                    await self?.processPendingOperations()
                }
            }
        }
    }

    private func processPendingOperations() async {
        guard NetworkMonitor.shared.isConnected else { return }

        for operation in pendingOperations {
            do {
                switch operation.type {
                case .syncInvoice:
                    // Handle invoice sync
                    break
                case .sendEmail:
                    // Handle email sending
                    break
                case .aiExtraction:
                    // Handle AI extraction retry
                    break
                }
                removeOperation(operation)
            } catch {
                print("Failed to process pending operation: \(error)")
            }
        }
    }
}
