import SwiftUI

struct PDFSettingsView: View {

    @EnvironmentObject var appState: PDFAppState
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingPaywall = false
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if subscriptionManager.isPro {
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

                        Button("Manage Subscription") {
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                UIApplication.shared.open(url)
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

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Build", value: buildNumber)

                    Link(destination: URL(string: "https://kreativekoala.llc/privacy")!) {
                        HStack {
                            Label("Privacy Policy", systemImage: "hand.raised")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://kreativekoala.llc/terms")!) {
                        HStack {
                            Label("Terms of Use (EULA)", systemImage: "doc.text")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        if let url = URL(string: "mailto:support@kreativekoala.llc?subject=All-in-One%20PDF%20Support") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Contact Support", systemImage: "envelope")
                    }
                    .foregroundColor(.primary)

                    Button {
                        Task {
                            do {
                                try await subscriptionManager.restorePurchases()
                                if subscriptionManager.isPro {
                                    restoreMessage = "Your purchases have been restored successfully!"
                                } else {
                                    restoreMessage = "No previous purchases found."
                                }
                                showRestoreAlert = true
                            } catch {
                                restoreMessage = "Failed to restore purchases."
                                showRestoreAlert = true
                            }
                        }
                    } label: {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPaywall) {
                RemotePaywallView()
            }
            .alert("Restore Purchases", isPresented: $showRestoreAlert) {
                Button("OK") { showRestoreAlert = false }
            } message: {
                Text(restoreMessage)
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

#Preview {
    PDFSettingsView()
        .environmentObject(PDFAppState())
}
