import SwiftUI
import SwiftData

@MainActor
@Observable
final class HistoryViewModel {
    var layouts: [DailyLayout] = []
    var errorMessage: String?

    private let store: LayoutStore

    init(store: LayoutStore) {
        self.store = store
    }

    func load() {
        do {
            layouts = try store.savedLayouts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
