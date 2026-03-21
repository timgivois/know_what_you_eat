import Foundation
import CoreGraphics

/// A single photo slot defined in unit coordinates (0–1).
struct SlotFrame {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat

    func cgRect(in size: CGSize) -> CGRect {
        CGRect(x: x * size.width,
               y: y * size.height,
               width: width * size.width,
               height: height * size.height)
    }
}

/// Defines a collage template for exactly `photoCount` photos.
struct LayoutPreset: Identifiable, Hashable {
    let id: String
    let name: String
    let photoCount: Int       // exact count this preset supports
    let slots: [SlotFrame]    // one entry per photo, in slot order

    static func == (lhs: LayoutPreset, rhs: LayoutPreset) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - All presets

extension LayoutPreset {

    /// Returns presets that can accommodate exactly `count` photos,
    /// plus any preset whose photoCount >= count (so a 4-slot preset shows when you have 3 photos
    /// only if we want to allow empty slots — here we do exact matching only).
    static func presets(for count: Int) -> [LayoutPreset] {
        all.filter { $0.photoCount == count }
    }

    static let all: [LayoutPreset] = presets1 + presets2 + presets3 + presets4
        + presets5 + presets6 + presets7 + presets8

    // MARK: 1 photo

    static let presets1: [LayoutPreset] = [
        LayoutPreset(
            id: "1_full",
            name: "Full Frame",
            photoCount: 1,
            slots: [
                SlotFrame(x: 0, y: 0, width: 1, height: 1)
            ]
        )
    ]

    // MARK: 2 photos

    static let presets2: [LayoutPreset] = [
        LayoutPreset(
            id: "2_side",
            name: "Side by Side",
            photoCount: 2,
            slots: [
                SlotFrame(x: 0,    y: 0, width: 0.5, height: 1),
                SlotFrame(x: 0.5,  y: 0, width: 0.5, height: 1)
            ]
        ),
        LayoutPreset(
            id: "2_stacked",
            name: "Stacked",
            photoCount: 2,
            slots: [
                SlotFrame(x: 0, y: 0,   width: 1, height: 0.5),
                SlotFrame(x: 0, y: 0.5, width: 1, height: 0.5)
            ]
        )
    ]

    // MARK: 3 photos

    static let presets3: [LayoutPreset] = [
        LayoutPreset(
            id: "3_left_big",
            name: "Left Focus",
            photoCount: 3,
            slots: [
                SlotFrame(x: 0,    y: 0,   width: 0.6, height: 1),
                SlotFrame(x: 0.6,  y: 0,   width: 0.4, height: 0.5),
                SlotFrame(x: 0.6,  y: 0.5, width: 0.4, height: 0.5)
            ]
        ),
        LayoutPreset(
            id: "3_row",
            name: "Row",
            photoCount: 3,
            slots: [
                SlotFrame(x: 0,      y: 0, width: 1.0/3, height: 1),
                SlotFrame(x: 1.0/3,  y: 0, width: 1.0/3, height: 1),
                SlotFrame(x: 2.0/3,  y: 0, width: 1.0/3, height: 1)
            ]
        ),
        LayoutPreset(
            id: "3_top_big",
            name: "Top Focus",
            photoCount: 3,
            slots: [
                SlotFrame(x: 0,   y: 0,   width: 1,   height: 0.6),
                SlotFrame(x: 0,   y: 0.6, width: 0.5, height: 0.4),
                SlotFrame(x: 0.5, y: 0.6, width: 0.5, height: 0.4)
            ]
        )
    ]

    // MARK: 4 photos

    static let presets4: [LayoutPreset] = [
        LayoutPreset(
            id: "4_grid",
            name: "2×2 Grid",
            photoCount: 4,
            slots: [
                SlotFrame(x: 0,   y: 0,   width: 0.5, height: 0.5),
                SlotFrame(x: 0.5, y: 0,   width: 0.5, height: 0.5),
                SlotFrame(x: 0,   y: 0.5, width: 0.5, height: 0.5),
                SlotFrame(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
            ]
        ),
        LayoutPreset(
            id: "4_left_big",
            name: "Left Focus",
            photoCount: 4,
            slots: [
                SlotFrame(x: 0,   y: 0,      width: 0.6, height: 1),
                SlotFrame(x: 0.6, y: 0,      width: 0.4, height: 1.0/3),
                SlotFrame(x: 0.6, y: 1.0/3,  width: 0.4, height: 1.0/3),
                SlotFrame(x: 0.6, y: 2.0/3,  width: 0.4, height: 1.0/3)
            ]
        ),
        LayoutPreset(
            id: "4_strip",
            name: "Strip",
            photoCount: 4,
            slots: [
                SlotFrame(x: 0,    y: 0, width: 0.25, height: 1),
                SlotFrame(x: 0.25, y: 0, width: 0.25, height: 1),
                SlotFrame(x: 0.5,  y: 0, width: 0.25, height: 1),
                SlotFrame(x: 0.75, y: 0, width: 0.25, height: 1)
            ]
        )
    ]

    // MARK: 5 photos

    static let presets5: [LayoutPreset] = [
        LayoutPreset(
            id: "5_top_big",
            name: "Top Focus",
            photoCount: 5,
            slots: [
                SlotFrame(x: 0,   y: 0,   width: 1,   height: 0.6),
                SlotFrame(x: 0,   y: 0.6, width: 0.25, height: 0.4),
                SlotFrame(x: 0.25,y: 0.6, width: 0.25, height: 0.4),
                SlotFrame(x: 0.5, y: 0.6, width: 0.25, height: 0.4),
                SlotFrame(x: 0.75,y: 0.6, width: 0.25, height: 0.4)
            ]
        ),
        LayoutPreset(
            id: "5_2_3",
            name: "2+3 Rows",
            photoCount: 5,
            slots: [
                SlotFrame(x: 0,   y: 0,   width: 0.5, height: 0.5),
                SlotFrame(x: 0.5, y: 0,   width: 0.5, height: 0.5),
                SlotFrame(x: 0,   y: 0.5, width: 1.0/3, height: 0.5),
                SlotFrame(x: 1.0/3, y: 0.5, width: 1.0/3, height: 0.5),
                SlotFrame(x: 2.0/3, y: 0.5, width: 1.0/3, height: 0.5)
            ]
        )
    ]

    // MARK: 6 photos

    static let presets6: [LayoutPreset] = [
        LayoutPreset(
            id: "6_2x3",
            name: "2×3 Grid",
            photoCount: 6,
            slots: [
                SlotFrame(x: 0,   y: 0,      width: 0.5, height: 1.0/3),
                SlotFrame(x: 0.5, y: 0,      width: 0.5, height: 1.0/3),
                SlotFrame(x: 0,   y: 1.0/3,  width: 0.5, height: 1.0/3),
                SlotFrame(x: 0.5, y: 1.0/3,  width: 0.5, height: 1.0/3),
                SlotFrame(x: 0,   y: 2.0/3,  width: 0.5, height: 1.0/3),
                SlotFrame(x: 0.5, y: 2.0/3,  width: 0.5, height: 1.0/3)
            ]
        ),
        LayoutPreset(
            id: "6_3x2",
            name: "3×2 Grid",
            photoCount: 6,
            slots: [
                SlotFrame(x: 0,      y: 0,   width: 1.0/3, height: 0.5),
                SlotFrame(x: 1.0/3,  y: 0,   width: 1.0/3, height: 0.5),
                SlotFrame(x: 2.0/3,  y: 0,   width: 1.0/3, height: 0.5),
                SlotFrame(x: 0,      y: 0.5, width: 1.0/3, height: 0.5),
                SlotFrame(x: 1.0/3,  y: 0.5, width: 1.0/3, height: 0.5),
                SlotFrame(x: 2.0/3,  y: 0.5, width: 1.0/3, height: 0.5)
            ]
        ),
        LayoutPreset(
            id: "6_top_big",
            name: "Top Focus",
            photoCount: 6,
            slots: [
                SlotFrame(x: 0,    y: 0,    width: 1,    height: 0.55),
                SlotFrame(x: 0,    y: 0.55, width: 0.2,  height: 0.45),
                SlotFrame(x: 0.2,  y: 0.55, width: 0.2,  height: 0.45),
                SlotFrame(x: 0.4,  y: 0.55, width: 0.2,  height: 0.45),
                SlotFrame(x: 0.6,  y: 0.55, width: 0.2,  height: 0.45),
                SlotFrame(x: 0.8,  y: 0.55, width: 0.2,  height: 0.45)
            ]
        )
    ]

    // MARK: 7 photos

    static let presets7: [LayoutPreset] = [
        LayoutPreset(
            id: "7_3_4",
            name: "3+4 Rows",
            photoCount: 7,
            slots: [
                SlotFrame(x: 0,      y: 0,   width: 1.0/3, height: 0.5),
                SlotFrame(x: 1.0/3,  y: 0,   width: 1.0/3, height: 0.5),
                SlotFrame(x: 2.0/3,  y: 0,   width: 1.0/3, height: 0.5),
                SlotFrame(x: 0,      y: 0.5, width: 0.25,  height: 0.5),
                SlotFrame(x: 0.25,   y: 0.5, width: 0.25,  height: 0.5),
                SlotFrame(x: 0.5,    y: 0.5, width: 0.25,  height: 0.5),
                SlotFrame(x: 0.75,   y: 0.5, width: 0.25,  height: 0.5)
            ]
        ),
        LayoutPreset(
            id: "7_left_big",
            name: "Left Focus",
            photoCount: 7,
            slots: [
                SlotFrame(x: 0,   y: 0,      width: 0.6, height: 1),
                SlotFrame(x: 0.6, y: 0,      width: 0.4, height: 1.0/6),
                SlotFrame(x: 0.6, y: 1.0/6,  width: 0.4, height: 1.0/6),
                SlotFrame(x: 0.6, y: 2.0/6,  width: 0.4, height: 1.0/6),
                SlotFrame(x: 0.6, y: 3.0/6,  width: 0.4, height: 1.0/6),
                SlotFrame(x: 0.6, y: 4.0/6,  width: 0.4, height: 1.0/6),
                SlotFrame(x: 0.6, y: 5.0/6,  width: 0.4, height: 1.0/6)
            ]
        )
    ]

    // MARK: 8 photos

    static let presets8: [LayoutPreset] = [
        LayoutPreset(
            id: "8_4x2",
            name: "4×2 Grid",
            photoCount: 8,
            slots: [
                SlotFrame(x: 0,    y: 0,   width: 0.25, height: 0.5),
                SlotFrame(x: 0.25, y: 0,   width: 0.25, height: 0.5),
                SlotFrame(x: 0.5,  y: 0,   width: 0.25, height: 0.5),
                SlotFrame(x: 0.75, y: 0,   width: 0.25, height: 0.5),
                SlotFrame(x: 0,    y: 0.5, width: 0.25, height: 0.5),
                SlotFrame(x: 0.25, y: 0.5, width: 0.25, height: 0.5),
                SlotFrame(x: 0.5,  y: 0.5, width: 0.25, height: 0.5),
                SlotFrame(x: 0.75, y: 0.5, width: 0.25, height: 0.5)
            ]
        ),
        LayoutPreset(
            id: "8_2x4",
            name: "2×4 Grid",
            photoCount: 8,
            slots: [
                SlotFrame(x: 0,   y: 0,    width: 0.5, height: 0.25),
                SlotFrame(x: 0.5, y: 0,    width: 0.5, height: 0.25),
                SlotFrame(x: 0,   y: 0.25, width: 0.5, height: 0.25),
                SlotFrame(x: 0.5, y: 0.25, width: 0.5, height: 0.25),
                SlotFrame(x: 0,   y: 0.5,  width: 0.5, height: 0.25),
                SlotFrame(x: 0.5, y: 0.5,  width: 0.5, height: 0.25),
                SlotFrame(x: 0,   y: 0.75, width: 0.5, height: 0.25),
                SlotFrame(x: 0.5, y: 0.75, width: 0.5, height: 0.25)
            ]
        ),
        LayoutPreset(
            id: "8_magazine",
            name: "Magazine",
            photoCount: 8,
            slots: [
                SlotFrame(x: 0,    y: 0,    width: 1,    height: 0.5),   // hero
                SlotFrame(x: 0,    y: 0.5,  width: 1.0/7, height: 0.5),
                SlotFrame(x: 1.0/7,y: 0.5,  width: 1.0/7, height: 0.5),
                SlotFrame(x: 2.0/7,y: 0.5,  width: 1.0/7, height: 0.5),
                SlotFrame(x: 3.0/7,y: 0.5,  width: 1.0/7, height: 0.5),
                SlotFrame(x: 4.0/7,y: 0.5,  width: 1.0/7, height: 0.5),
                SlotFrame(x: 5.0/7,y: 0.5,  width: 1.0/7, height: 0.5),
                SlotFrame(x: 6.0/7,y: 0.5,  width: 1.0/7, height: 0.5)
            ]
        )
    ]
}
