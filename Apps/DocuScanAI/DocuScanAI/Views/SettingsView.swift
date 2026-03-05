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
                                    Text("Unlock AI features, cloud sync & more")
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
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
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
                PaywallView()
            }
        }
    }

    private func restorePurchases() {
        Task {
            try? await SubscriptionManager.shared.restorePurchases()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
