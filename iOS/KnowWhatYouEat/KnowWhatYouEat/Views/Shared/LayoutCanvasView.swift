import SwiftUI

/// The canonical collage canvas — used in the editor, history, and as the export source.
struct LayoutCanvasView: View {
    let photos: [PhotoItem]
    let preset: LayoutPreset
    var gap: CGFloat = 2
    var backgroundColor: Color = .black

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                backgroundColor

                ForEach(Array(preset.slots.enumerated()), id: \.offset) { index, slot in
                    let rect = slot.cgRect(in: geo.size)
                    let inset = rect.insetBy(dx: gap / 2, dy: gap / 2)

                    if index < photos.count, let img = photos[index].uiImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: inset.width, height: inset.height)
                            .clipped()
                            .position(x: inset.midX, y: inset.midY)
                    } else {
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color(.systemGray5))
                            .frame(width: inset.width, height: inset.height)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: min(inset.width, inset.height) * 0.25))
                            )
                            .position(x: inset.midX, y: inset.midY)
                    }
                }
            }
        }
    }
}
