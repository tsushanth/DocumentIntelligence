import SwiftUI

struct FolderDetailView: View {
    
    let folder: DocumentFolder
    @State private var searchText = ""
    
    private var folderDocuments: [ScannedDocument] {
        let store = DocumentStore.shared
        return store.documents.filter { folder.documentIds.contains($0.id) }
    }

    var body: some View {
        Group {
            if folderDocuments.isEmpty {
                emptyState
            } else {
                documentList
            }
        }
        .navigationTitle(folder.name)
        .searchable(text: $searchText, prompt: "Search in folder")
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Folder is Empty")
                .font(.title3.bold())
            
            Text("Move documents here to organize them")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private var documentList: some View {
        List {
            ForEach(folderDocuments) { document in
                NavigationLink(destination: DocumentDetailView(document: document)) {
                    DocumentRow(document: document)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        FolderDetailView(folder: DocumentFolder(name: "Test Folder"))
    }
}
