import SwiftUI

/// The canonical collage canvas — used in the editor, history, and as the export source.
struct LayoutCanvasView: View {
    let photos: [PhotoItem]
    let preset: LayoutPreset
    var dayKey: Date? = nil
    var gap: CGFloat = 2
    var backgroundColor: Color = .black
    var showTimeOverlay: Bool = true

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    /// Fraction of the canvas reserved for the date banner at the top
    private let dateBannerFraction: CGFloat = 0.08

    var body: some View {
        GeometryReader { geo in
            let showBanner = dayKey != nil
            let bannerHeight = showBanner ? geo.size.height * dateBannerFraction : 0
            let canvasSize = CGSize(width: geo.size.width, height: geo.size.height - bannerHeight)

            ZStack(alignment: .topLeading) {
                backgroundColor

                // Date banner
                if let dayKey {
                    Text(Self.dateFormatter.string(from: dayKey))
                        .font(.system(size: bannerHeight * 0.55, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: geo.size.width, height: bannerHeight)
                        .position(x: geo.size.width / 2, y: bannerHeight / 2)
                }

                // Photo slots
                ForEach(Array(preset.slots.enumerated()), id: \.offset) { index, slot in
                    let rect = slot.cgRect(in: canvasSize)
                    let shifted = CGRect(x: rect.origin.x, y: rect.origin.y + bannerHeight,
                                         width: rect.width, height: rect.height)
                    let inset = shifted.insetBy(dx: gap / 2, dy: gap / 2)

                    if index < photos.count, let img = photos[index].uiImage {
                        ZStack(alignment: .bottom) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: inset.width, height: inset.height)
                                .clipped()

                            if showTimeOverlay {
                                timeLabel(for: photos[index].capturedAt, slotSize: inset.size)
                            }
                        }
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

    private func timeLabel(for date: Date, slotSize: CGSize) -> some View {
        let fontSize = max(8, min(slotSize.width, slotSize.height) * 0.12)
        return Text(Self.timeFormatter.string(from: date))
            .font(.system(size: fontSize, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 3))
            .padding(.bottom, 3)
    }
}
