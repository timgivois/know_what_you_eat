import SwiftUI
import SwiftData
import PhotosUI
import Photos

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
    var showCamera = false

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

            // Extract creation date from photo metadata
            let capturedAt = Self.extractCreationDate(from: data) ?? Date()

            let photo = PhotoItem(imageData: jpeg, capturedAt: capturedAt, order: currentCount + offset)
            do {
                try store.addPhoto(photo, to: currentLayout)
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        autoSwitchPresetIfNeeded(for: currentLayout)
    }

    /// Add a photo captured from the camera (always "now").
    func addCameraPhoto(_ image: UIImage) {
        guard let jpeg = image.jpegData(compressionQuality: 0.82) else { return }

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

        let photo = PhotoItem(imageData: jpeg, capturedAt: Date(), order: currentLayout.photos.count)
        do {
            try store.addPhoto(photo, to: currentLayout)
        } catch {
            errorMessage = error.localizedDescription
        }

        autoSwitchPresetIfNeeded(for: currentLayout)
    }

    /// Try to read EXIF creation date from image data.
    private static func extractCreationDate(from data: Data) -> Date? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
              let dateString = exif[kCGImagePropertyExifDateTimeOriginal] as? String else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dateString)
    }

    private func autoSwitchPresetIfNeeded(for currentLayout: DailyLayout) {
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
