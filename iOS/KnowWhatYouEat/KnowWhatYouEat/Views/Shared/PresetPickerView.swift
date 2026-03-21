import SwiftUI

struct PresetPickerView: View {
    let photoCount: Int
    @Binding var selectedPresetID: String

    private var available: [LayoutPreset] {
        LayoutPreset.presets(for: photoCount)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(available) { preset in
                    PresetThumbnailView(
                        preset: preset,
                        isSelected: preset.id == selectedPresetID
                    )
                    .onTapGesture {
                        selectedPresetID = preset.id
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct PresetThumbnailView: View {
    let preset: LayoutPreset
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray6))
                    .frame(width: 72, height: 72)

                PresetDiagramView(preset: preset)
                    .frame(width: 68, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )

            Text(preset.name)
                .font(.caption2)
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
    }
}

/// A tiny wireframe diagram of the preset layout — no photos, just colored rectangles.
struct PresetDiagramView: View {
    let preset: LayoutPreset

    private let slotColors: [Color] = [
        Color(.systemBlue).opacity(0.35),
        Color(.systemGreen).opacity(0.35),
        Color(.systemOrange).opacity(0.35),
        Color(.systemPurple).opacity(0.35),
        Color(.systemRed).opacity(0.35),
        Color(.systemTeal).opacity(0.35),
        Color(.systemYellow).opacity(0.35),
        Color(.systemPink).opacity(0.35)
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(Array(preset.slots.enumerated()), id: \.offset) { index, slot in
                let rect = slot.cgRect(in: geo.size).insetBy(dx: 1, dy: 1)
                Rectangle()
                    .fill(slotColors[index % slotColors.count])
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }
        }
        .background(Color(.systemGray4))
    }
}
