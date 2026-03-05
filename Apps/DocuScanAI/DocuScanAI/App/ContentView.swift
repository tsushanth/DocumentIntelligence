import SwiftUI

struct ContentView: View {
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Documents", systemImage: "doc.fill")
                }
                .tag(0)
            
            ScannerView()
                .tabItem {
                    Label("Scan", systemImage: "camera.fill")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .tint(.blue)
        .modifier(TabBarOnlyModifier())
    }
}

private struct TabBarOnlyModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.tabViewStyle(.tabBarOnly)
        } else {
            content
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
