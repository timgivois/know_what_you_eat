import Foundation
import SwiftData
import UIKit

@Model
final class PhotoItem {
    var id: UUID
    var imageData: Data       // JPEG compressed
    var capturedAt: Date      // exact time the photo was taken/added
    var order: Int            // slot index in the layout

    var layout: DailyLayout?

    init(imageData: Data, capturedAt: Date = Date(), order: Int) {
        self.id = UUID()
        self.imageData = imageData
        self.capturedAt = capturedAt
        self.order = order
    }

    var uiImage: UIImage? {
        UIImage(data: imageData)
    }
}
