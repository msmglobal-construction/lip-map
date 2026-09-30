import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        @Bindable var appModel = appModel
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "circle.fill") }
            PinsMapView()
                .tabItem { Label("Map", systemImage: "map") }
            BadgesView()
                .tabItem { Label("Badges", systemImage: "rosette") }
            FriendsView()
                .tabItem { Label("Friends", systemImage: "person.2") }
        }
        .tint(LipMapTheme.accent)
        .onAppear {
            appModel.attachFriends(modelContext: modelContext)
        }
        .sheet(isPresented: $appModel.showPaywall) {
            PaywallView()
                .environment(appModel)
        }
    }
}

enum LipMapTheme {
    static let accent = Color(red: 0.12, green: 0.45, blue: 0.38)
    static let ink = Color(red: 0.10, green: 0.14, blue: 0.16)
    static let mist = Color(red: 0.93, green: 0.95, blue: 0.94)
    static let pin = Color(red: 0.86, green: 0.28, blue: 0.24)
}
