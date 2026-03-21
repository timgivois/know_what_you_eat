import SwiftUI

@MainActor
struct LayoutExportService {

    /// Renders a layout canvas to a flat UIImage at `scale` times screen resolution.
    static func render(
        layout: DailyLayout,
        size: CGSize = CGSize(width: 1080, height: 1080),
        scale: CGFloat = 1
    ) async -> UIImage? {
        guard let preset = LayoutPreset.all.first(where: { $0.id == layout.presetID }) else {
            return nil
        }

        let view = LayoutCanvasView(
            photos: layout.orderedPhotos,
            preset: preset,
            gap: 4
        )
        .frame(width: size.width, height: size.height)

        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        return renderer.uiImage
    }
}
