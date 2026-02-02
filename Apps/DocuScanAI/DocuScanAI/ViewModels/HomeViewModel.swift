import SwiftUI
import Combine

/// View model for home screen
@MainActor
class HomeViewModel: ObservableObject {
    
    @Published var documents: [ScannedDocument] = []
    @Published var folders: [DocumentFolder] = []
    @Published var newFolderName = ""
    @Published var isLoading = false
    
    init() {
        loadDocuments()
    }
    
    func loadDocuments() {
        // Load from DocumentStore
        // For now, using sample data
    }
    
    func createFolder() {
        guard !newFolderName.isEmpty else { return }
        let folder = DocumentFolder(name: newFolderName)
        folders.append(folder)
        newFolderName = ""
    }
    
    func deleteDocuments(at offsets: IndexSet) {
        documents.remove(atOffsets: offsets)
    }
    
    func deleteFolders(at offsets: IndexSet) {
        folders.remove(atOffsets: offsets)
    }
    
    func sortByDate() {
        documents.sort { $0.createdAt > $1.createdAt }
    }
    
    func sortByName() {
        documents.sort { $0.title < $1.title }
    }
    
    func moveDocument(_ document: ScannedDocument, to folder: DocumentFolder) {
        // Move document to folder
    }
}
