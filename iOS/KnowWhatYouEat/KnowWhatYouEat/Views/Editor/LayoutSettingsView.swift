import SwiftUI

/// Full-screen settings sheet for choosing a layout preset.
struct LayoutSettingsView: View {
    @Bindable var vm: EditorViewModel
    @Environment(\.dismiss) private var dismiss

    private var allPresets: [LayoutPreset] {
        LayoutPreset.all
    }

    /// Group presets by photo count for organized display.
    private var groupedPresets: [(count: Int, presets: [LayoutPreset])] {
        let grouped = Dictionary(grouping: allPresets) { $0.photoCount }
        return grouped.keys.sorted().map { (count: $0, presets: grouped[$0]!) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Current layout preview
                    if vm.photoCount > 0, let preset = vm.currentPreset {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Layout")
                                .font(.headline)

                            LayoutCanvasView(
                                photos: vm.layout?.orderedPhotos ?? [],
                                preset: preset,
                                dayKey: vm.layout?.dayKey
                            )
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 4)
                        }
                        .padding(.horizontal)
                    }

                    // Compatible presets (matching current photo count)
                    if vm.photoCount > 0 {
                        let compatible = LayoutPreset.presets(for: vm.photoCount)
                        if !compatible.isEmpty {
                            presetSection(
                                title: "For \(vm.photoCount) photo\(vm.photoCount == 1 ? "" : "s")",
                                presets: compatible,
                                highlight: true
                            )
                        }
                    }

                    // All presets by group
                    ForEach(groupedPresets, id: \.count) { group in
                        // Skip the group we already showed above
                        if group.count != vm.photoCount {
                            presetSection(
                                title: "\(group.count) photo\(group.count == 1 ? "" : "s")",
                                presets: group.presets,
                                highlight: false
                            )
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Layout Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func presetSection(title: String, presets: [LayoutPreset], highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(presets) { preset in
                        presetCard(preset: preset, highlight: highlight)
                            .onTapGesture {
                                vm.applyPreset(preset.id)
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func presetCard(preset: LayoutPreset, highlight: Bool) -> some View {
        let isSelected = preset.id == vm.selectedPresetID
        let isCompatible = preset.photoCount == vm.photoCount

        return VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
                    .frame(width: 100, height: 100)

                PresetDiagramView(preset: preset)
                    .frame(width: 92, height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
            )
            .opacity(isCompatible || highlight ? 1 : 0.5)

            Text(preset.name)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
    }
}
