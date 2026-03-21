import SwiftUI
import SwiftData
import PhotosUI

@MainActor
@Observable
final class EditorViewModel {
    var layout: DailyLayout?
    var selectedPresetID: String = LayoutPreset.presets1[0].id
    var pickerItems: [PhotosPickerItem] = []
    var isLoading = false
    var errorMessage: String?
    var showShareSheet = false
    var shareImage: UIImage?

    private let store: LayoutStore

    init(store: LayoutStore) {
        self.store = store
    }

    // MARK: - Load

    func loadOrCreateTodayLayout() {
        do {
            if let existing = try store.todayLayout() {
                layout = existing
                selectedPresetID = existing.presetID
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Photo management

    func loadPhotos(from items: [PhotosPickerItem]) async {
        isLoading = true
        defer { isLoading = false }

        var loaded: [DailyLayout] = []

        // Ensure we have a layout
        if layout == nil {
            do {
                layout = try store.upsertTodayLayout(presetID: selectedPresetID)
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }

        guard let currentLayout = layout else { return }

        let currentCount = currentLayout.photos.count
        for (offset, item) in items.enumerated() {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data),
                  let jpeg = uiImage.jpegData(compressionQuality: 0.82) else { continue }

            let photo = PhotoItem(imageData: jpeg, order: currentCount + offset)
            do {
                try store.addPhoto(photo, to: currentLayout)
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        // Auto-switch preset if current one no longer matches count
        let count = currentLayout.photos.count
        if !LayoutPreset.presets(for: count).contains(where: { $0.id == selectedPresetID }),
           let first = LayoutPreset.presets(for: count).first {
            selectedPresetID = first.id
            try? store.updatePreset(layout: currentLayout, presetID: first.id)
        }
    }

    func removePhoto(_ photo: PhotoItem) {
        guard let currentLayout = layout else { return }
        do {
            try store.removePhoto(photo, from: currentLayout)
            // Re-sync preset
            let count = currentLayout.photos.count
            if count > 0,
               !LayoutPreset.presets(for: count).contains(where: { $0.id == selectedPresetID }),
               let first = LayoutPreset.presets(for: count).first {
                selectedPresetID = first.id
                try? store.updatePreset(layout: currentLayout, presetID: first.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Preset update

    func applyPreset(_ id: String) {
        selectedPresetID = id
        guard let currentLayout = layout else { return }
        try? store.updatePreset(layout: currentLayout, presetID: id)
    }

    // MARK: - Export / Share

    func prepareShare() async {
        guard let currentLayout = layout else { return }
        isLoading = true
        defer { isLoading = false }
        shareImage = await LayoutExportService.render(layout: currentLayout)
        if shareImage != nil {
            showShareSheet = true
        }
    }

    // MARK: - Computed

    var currentPreset: LayoutPreset? {
        LayoutPreset.all.first(where: { $0.id == selectedPresetID })
    }

    var photoCount: Int {
        layout?.photos.count ?? 0
    }

    var canAddMore: Bool {
        photoCount < 8
    }

    var availablePresets: [LayoutPreset] {
        photoCount > 0 ? LayoutPreset.presets(for: photoCount) : []
    }
}
