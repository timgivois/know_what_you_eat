import SwiftUI

/// Root view — shows the editor for today, switches to history after saving.
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showHistory = false

    var body: some View {
        Group {
            if showHistory {
                HistoryView(onNewLayout: {
                    showHistory = false
                })
            } else {
                EditorView(onSaved: {
                    showHistory = true
                })
            }
        }
        .onAppear {
            // If today's layout is already saved, go straight to history
            let store = LayoutStore(context: modelContext)
            if let today = try? store.todayLayout(), today.isSaved {
                showHistory = true
            }
        }
    }
}
