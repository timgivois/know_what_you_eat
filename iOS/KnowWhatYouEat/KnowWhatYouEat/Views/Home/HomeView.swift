import SwiftUI

/// Root tab view.
struct HomeView: View {
    var body: some View {
        TabView {
            EditorView()
                .tabItem {
                    Label("Today", systemImage: "fork.knife")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
        }
    }
}
