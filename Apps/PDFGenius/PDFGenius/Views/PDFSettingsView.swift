import SwiftUI

struct PDFSettingsView: View {
    
    @EnvironmentObject var appState: PDFAppState
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationStack {
            List {
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
                                    .foregroundColor(.purple)
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text("Upgrade to Pro")
                                        .font(.headline)
                                    Text("Unlock all PDF tools")
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
                
                Section("General") {
                    NavigationLink(destination: Text("Default View Settings")) {
                        Label("Default View", systemImage: "doc.viewfinder")
                    }
                    NavigationLink(destination: Text("Export Settings")) {
                        Label("Export Quality", systemImage: "square.and.arrow.up")
                    }
                }
                
                Section("AI Features") {
                    NavigationLink(destination: Text("API Settings")) {
                        Label("OpenAI API Key", systemImage: "key")
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                    NavigationLink(destination: Text("Privacy")) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    NavigationLink(destination: Text("Terms")) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                    Button(action: {}) {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPaywall) {
                PDFGeniusPaywallView()
            }
        }
    }
}

struct PDFGeniusPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(.purple)
                        Text("PDFGenius Pro")
                            .font(.title.bold())
                        Text("Edit PDFs like a pro")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        proFeature("signature", "Add Signatures", "Sign documents digitally")
                        proFeature("doc.on.doc", "Merge & Split", "Combine or separate PDFs")
                        proFeature("sparkles", "AI Analysis", "Understand contracts instantly")
                        proFeature("lock.fill", "Password Protect", "Secure sensitive documents")
                        proFeature("doc.text.viewfinder", "Advanced OCR", "Extract text from any PDF")
                    }
                    .padding(.horizontal, 24)
                    
                    VStack(spacing: 8) {
                        Text("$5.99/month")
                            .font(.title2.bold())
                        Text("Cancel anytime")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    Button(action: {}) {
                        Text("Subscribe Now")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func proFeature(_ icon: String, _ title: String, _ desc: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(desc).font(.subheadline).foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    PDFSettingsView()
        .environmentObject(PDFAppState())
}
