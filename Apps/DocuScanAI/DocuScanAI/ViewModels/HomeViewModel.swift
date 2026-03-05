import SwiftUI
import Combine

/// View model for home screen — observes DocumentStore for persistence
@MainActor
class HomeViewModel: ObservableObject {

    @Published var newFolderName = ""

    private let store = DocumentStore.shared
    private var cancellables = Set<AnyCancellable>()

    var documents: [ScannedDocument] { store.documents }
    var folders: [DocumentFolder] { store.folders }

    init() {
        // Forward store changes to trigger view updates
        store.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func createFolder() {
        guard !newFolderName.isEmpty else { return }
        store.createFolder(name: newFolderName)
        newFolderName = ""
    }

    func deleteDocuments(at offsets: IndexSet) {
        store.deleteDocuments(at: offsets)
    }

    func deleteFolders(at offsets: IndexSet) {
        store.deleteFolders(at: offsets)
    }

    func sortByDate() {
        store.documents.sort { $0.createdAt > $1.createdAt }
    }

    func sortByName() {
        store.documents.sort { $0.title < $1.title }
    }
}
