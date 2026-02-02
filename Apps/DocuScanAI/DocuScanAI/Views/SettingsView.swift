import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject var appState: AppState
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationStack {
            List {
                // Subscription Section
                Section {
                    if appState.isProUser {
                        HStack {
                            Image(systemName: "star.circle.fill")
                                .foregroundColor(.yellow)
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("Pro Member")
                                    .font(.headline)
                                Text("All features unlocked")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        Button(action: { showingPaywall = true }) {
                            HStack {
                                Image(systemName: "star.circle")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text("Upgrade to Pro")
                                        .font(.headline)
                                    Text("Unlock AI features, remove watermarks & more")
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
                
                // General Settings
                Section("General") {
                    NavigationLink(destination: Text("Document Quality Settings")) {
                        Label("Scan Quality", systemImage: "slider.horizontal.3")
                    }
                    
                    NavigationLink(destination: Text("Default Filter Settings")) {
                        Label("Default Filter", systemImage: "camera.filters")
                    }
                    
                    NavigationLink(destination: Text("Storage Settings")) {
                        Label("Storage", systemImage: "internaldrive")
                    }
                }
                
                // AI Settings
                Section("AI Features") {
                    Toggle(isOn: .constant(true)) {
                        Label("Auto-Title", systemImage: "textformat")
                    }
                    
                    Toggle(isOn: .constant(true)) {
                        Label("Auto-OCR", systemImage: "doc.text.viewfinder")
                    }
                    
                    NavigationLink(destination: Text("API Key Settings")) {
                        Label("OpenAI API Key", systemImage: "key")
                    }
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: Text("Privacy Policy")) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    
                    NavigationLink(destination: Text("Terms of Service")) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                    
                    Button(action: restorePurchases) {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPaywall) {
                DocuScanPaywallView()
            }
        }
    }
    
    private func restorePurchases() {
        // Will integrate with StoreKitManager
    }
}

struct DocuScanPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(.yellow)
                        
                        Text("DocuScan AI Pro")
                            .font(.title.bold())
                        
                        Text("Unlock the full power of AI")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        proFeature("sparkles", "AI Summaries", "Get instant summaries of any document")
                        proFeature("textformat", "Smart Titles", "Auto-generate descriptive titles")
                        proFeature("list.bullet.rectangle", "Field Extraction", "Extract dates, amounts, and more")
                        proFeature("doc.text.magnifyingglass", "Full OCR", "Search inside all your documents")
                        proFeature("icloud", "Cloud Sync", "Access documents on all devices")
                        proFeature("xmark.circle", "No Watermarks", "Export clean PDFs")
                    }
                    .padding(.horizontal, 24)
                    
                    // Price
                    VStack(spacing: 8) {
                        Text("$4.99/month")
                            .font(.title2.bold())
                        Text("Cancel anytime")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Subscribe button
                    Button(action: subscribe) {
                        Text("Subscribe Now")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    
                    Button("Restore Purchases") {
                        // Restore
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    
                    Text("Subscription auto-renews monthly. Cancel anytime in Settings.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func proFeature(_ icon: String, _ title: String, _ description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func subscribe() {
        // Will integrate with StoreKitManager
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
