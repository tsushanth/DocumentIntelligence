import SwiftUI

struct HomeView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    @State private var searchText = ""
    @State private var showingNewFolder = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.documents.isEmpty && viewModel.folders.isEmpty {
                    emptyState
                } else {
                    documentList
                }
            }
            .navigationTitle("Documents")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search documents")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingNewFolder = true }) {
                            Label("New Folder", systemImage: "folder.badge.plus")
                        }
                        Button(action: viewModel.sortByDate) {
                            Label("Sort by Date", systemImage: "calendar")
                        }
                        Button(action: viewModel.sortByName) {
                            Label("Sort by Name", systemImage: "textformat")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("New Folder", isPresented: $showingNewFolder) {
                TextField("Folder Name", text: $viewModel.newFolderName)
                Button("Cancel", role: .cancel) {}
                Button("Create") {
                    viewModel.createFolder()
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("No Documents Yet")
                .font(.title2.bold())
            
            Text("Tap the Scan tab to scan your first document")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var documentList: some View {
        List {
            if !viewModel.folders.isEmpty {
                Section("Folders") {
                    ForEach(viewModel.folders) { folder in
                        NavigationLink(destination: FolderDetailView(folder: folder)) {
                            FolderRow(folder: folder)
                        }
                    }
                    .onDelete(perform: viewModel.deleteFolders)
                }
            }
            
            Section("Recent Documents") {
                ForEach(filteredDocuments) { document in
                    NavigationLink(destination: DocumentDetailView(document: document)) {
                        DocumentRow(document: document)
                    }
                }
                .onDelete(perform: viewModel.deleteDocuments)
            }
        }
    }
    
    private var filteredDocuments: [ScannedDocument] {
        if searchText.isEmpty {
            return viewModel.documents
        }
        return viewModel.documents.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
}

struct FolderRow: View {
    let folder: DocumentFolder
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(folder.name)
                    .font(.body)
                Text("\(folder.documentCount) documents")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DocumentRow: View {
    let document: ScannedDocument
    
    var body: some View {
        HStack(spacing: 12) {
            if let thumbnail = document.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 65)
                    .cornerRadius(6)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 65)
                    .overlay(
                        Image(systemName: "doc.fill")
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(document.displayTitle)
                    .font(.body)
                    .lineLimit(2)
                
                Text("\(document.pageCount) pages • \(document.formattedDate)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if document.hasAIInsights {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("AI Insights")
                    }
                    .font(.caption2)
                    .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
