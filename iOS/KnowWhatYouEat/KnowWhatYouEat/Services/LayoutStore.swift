import Foundation
import SwiftData

@MainActor
final class LayoutStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Fetch

    func todayLayout() throws -> DailyLayout? {
        let key = Date.todayKey
        return try layout(for: key)
    }

    func layout(for dayKey: Date) throws -> DailyLayout? {
        let descriptor = FetchDescriptor<DailyLayout>(
            predicate: #Predicate { $0.dayKey == dayKey }
        )
        return try context.fetch(descriptor).first
    }

    func allLayouts() throws -> [DailyLayout] {
        let descriptor = FetchDescriptor<DailyLayout>(
            sortBy: [SortDescriptor(\.dayKey, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - Create / Update

    /// Returns existing today layout or creates a new one with the given preset.
    @discardableResult
    func upsertTodayLayout(presetID: String) throws -> DailyLayout {
        let key = Date.todayKey
        if let existing = try layout(for: key) {
            existing.presetID = presetID
            existing.updatedAt = Date()
            return existing
        }
        let layout = DailyLayout(dayKey: key, presetID: presetID)
        context.insert(layout)
        return layout
    }

    func addPhoto(_ item: PhotoItem, to layout: DailyLayout) throws {
        item.layout = layout
        layout.photos.append(item)
        layout.updatedAt = Date()
        try context.save()
    }

    func removePhoto(_ item: PhotoItem, from layout: DailyLayout) throws {
        context.delete(item)
        layout.updatedAt = Date()
        // Re-number remaining slots
        let sorted = layout.photos.filter { $0.id != item.id }.sorted { $0.order < $1.order }
        for (index, photo) in sorted.enumerated() {
            photo.order = index
        }
        try context.save()
    }

    func updatePreset(layout: DailyLayout, presetID: String) throws {
        layout.presetID = presetID
        layout.updatedAt = Date()
        try context.save()
    }

    func commitLayout(_ layout: DailyLayout) throws {
        layout.isSaved = true
        layout.updatedAt = Date()
        try context.save()
    }

    func savedLayouts() throws -> [DailyLayout] {
        let descriptor = FetchDescriptor<DailyLayout>(
            predicate: #Predicate { $0.isSaved == true },
            sortBy: [SortDescriptor(\.dayKey, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func save() throws {
        try context.save()
    }
}

// MARK: - Date helpers

extension Date {
    /// Midnight (start of day) in the current calendar — used as unique day key.
    static var todayKey: Date {
        Calendar.current.startOfDay(for: Date())
    }

    static func dayKey(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
}
