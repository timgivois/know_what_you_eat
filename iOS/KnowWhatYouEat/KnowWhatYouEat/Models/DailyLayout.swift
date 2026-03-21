import Foundation
import SwiftData

@Model
final class DailyLayout {
    @Attribute(.unique) var id: UUID
    var dayKey: Date          // midnight-normalized, used as the day identifier
    var presetID: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \PhotoItem.layout)
    var photos: [PhotoItem] = []

    init(dayKey: Date, presetID: String) {
        self.id = UUID()
        self.dayKey = dayKey
        self.presetID = presetID
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Photos sorted by their slot order
    var orderedPhotos: [PhotoItem] {
        photos.sorted { $0.order < $1.order }
    }
}
