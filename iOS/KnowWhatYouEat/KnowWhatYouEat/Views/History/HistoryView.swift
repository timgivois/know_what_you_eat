import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm: HistoryViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    HistoryContentView(vm: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("History")
            .onAppear {
                if vm == nil {
                    let store = LayoutStore(context: modelContext)
                    let newVM = HistoryViewModel(store: store)
                    vm = newVM
                }
                vm?.load()
            }
        }
    }
}

private struct HistoryContentView: View {
    let vm: HistoryViewModel

    var body: some View {
        if vm.layouts.isEmpty {
            ContentUnavailableView(
                "No layouts yet",
                systemImage: "photo.on.rectangle.angled",
                description: Text("Add photos on the Today tab to create your first layout.")
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(vm.layouts) { layout in
                        NavigationLink {
                            LayoutDetailView(layout: layout)
                        } label: {
                            HistoryCardView(layout: layout)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
    }
}

private struct HistoryCardView: View {
    let layout: DailyLayout

    private var preset: LayoutPreset? {
        LayoutPreset.all.first(where: { $0.id == layout.presetID })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Group {
                if let preset {
                    LayoutCanvasView(
                        photos: layout.orderedPhotos,
                        preset: preset,
                        dayKey: layout.dayKey
                    )
                } else {
                    Color(.systemGray5)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(layout.dayKey, style: .date)
                .font(.caption.weight(.medium))

            Text("\(layout.photos.count) photo\(layout.photos.count == 1 ? "" : "s")")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
