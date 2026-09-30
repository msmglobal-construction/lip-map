import SwiftUI
import SwiftData

@main
struct LipMapApp: App {
    @State private var appModel = AppModel()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TuckPin.self,
            FriendProfile.self,
            FriendLink.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData container failed: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(appModel)
                .task {
                    await appModel.entitlements.refresh()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
