import SwiftUI
import SwiftData

@main
struct KnowWhatYouEatApp: App {

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([DailyLayout.self, PhotoItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Migration failed — wipe the store and start fresh.
            // Safe for a local-only, single-device app with no sync.
            try? FileManager.default.removeItem(at: config.url)
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}
