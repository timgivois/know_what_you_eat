import XCTest
@testable import KnowWhatYouEat

final class LayoutPresetTests: XCTestCase {

    // MARK: - Preset count coverage

    func testPresetsExistForAllCounts() {
        for count in 1...8 {
            let presets = LayoutPreset.presets(for: count)
            XCTAssertFalse(presets.isEmpty, "No presets available for \(count) photo(s)")
        }
    }

    func testEachPresetSlotCountMatchesPhotoCount() {
        for preset in LayoutPreset.all {
            XCTAssertEqual(
                preset.slots.count, preset.photoCount,
                "Preset '\(preset.id)' has \(preset.slots.count) slots but photoCount=\(preset.photoCount)"
            )
        }
    }

    // MARK: - Slot geometry

    func testAllSlotsAreWithinUnitSquare() {
        for preset in LayoutPreset.all {
            for (i, slot) in preset.slots.enumerated() {
                XCTAssertGreaterThanOrEqual(slot.x, 0, "\(preset.id) slot[\(i)].x < 0")
                XCTAssertGreaterThanOrEqual(slot.y, 0, "\(preset.id) slot[\(i)].y < 0")
                XCTAssertLessThanOrEqual(slot.x + slot.width, 1.001, "\(preset.id) slot[\(i)] exceeds right edge")
                XCTAssertLessThanOrEqual(slot.y + slot.height, 1.001, "\(preset.id) slot[\(i)] exceeds bottom edge")
                XCTAssertGreaterThan(slot.width, 0, "\(preset.id) slot[\(i)].width is zero")
                XCTAssertGreaterThan(slot.height, 0, "\(preset.id) slot[\(i)].height is zero")
            }
        }
    }

    // MARK: - ID uniqueness

    func testAllPresetIDsAreUnique() {
        let ids = LayoutPreset.all.map { $0.id }
        let unique = Set(ids)
        XCTAssertEqual(ids.count, unique.count, "Duplicate preset IDs found")
    }

    // MARK: - Filter logic

    func testPresetsFilteredByCount() {
        let presetsFor3 = LayoutPreset.presets(for: 3)
        XCTAssertTrue(presetsFor3.allSatisfy { $0.photoCount == 3 })
    }

    func testPresetsFilteredExcludeWrongCounts() {
        let presetsFor2 = LayoutPreset.presets(for: 2)
        XCTAssertFalse(presetsFor2.contains(where: { $0.photoCount != 2 }))
    }

    // MARK: - SlotFrame geometry

    func testSlotFrameCGRect() {
        let slot = SlotFrame(x: 0.5, y: 0.25, width: 0.5, height: 0.75)
        let size = CGSize(width: 100, height: 200)
        let rect = slot.cgRect(in: size)
        XCTAssertEqual(rect.origin.x, 50)
        XCTAssertEqual(rect.origin.y, 50)
        XCTAssertEqual(rect.width, 50)
        XCTAssertEqual(rect.height, 150)
    }

    // MARK: - Date helpers

    func testTodayKeyIsStartOfDay() {
        let key = Date.todayKey
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: key)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testDayKeyForDateMatchesStartOfDay() {
        let now = Date()
        let key = Date.dayKey(for: now)
        let expected = Calendar.current.startOfDay(for: now)
        XCTAssertEqual(key, expected)
    }

    // MARK: - Preset total count sanity

    func testTotalPresetCount() {
        // 1+2+3+3+2+3+2+3 = 19 presets defined
        XCTAssertEqual(LayoutPreset.all.count, 19)
    }
}
