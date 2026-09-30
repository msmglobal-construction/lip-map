import Foundation
import SwiftData
import CoreLocation

enum TuckFlavor: String, Codable, CaseIterable, Identifiable {
    case coolMint = "Cool Mint"
    case wintergreen = "Wintergreen"
    case other = "Other"

    var id: String { rawValue }
}

@Model
final class TuckPin {
    var id: UUID
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var flavorRaw: String?
    /// Free-form tags used by badge rules (e.g. "coffee", "airport").
    var tagsCSV: String
    /// Manual badge ids the user assigned on this pin.
    var manualBadgeIDsCSV: String

    init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        timestamp: Date = .now,
        flavor: TuckFlavor? = nil,
        tags: [String] = [],
        manualBadgeIDs: [String] = []
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.flavorRaw = flavor?.rawValue
        self.tagsCSV = tags.joined(separator: ",")
        self.manualBadgeIDsCSV = manualBadgeIDs.joined(separator: ",")
    }

    var flavor: TuckFlavor? {
        get { flavorRaw.flatMap(TuckFlavor.init(rawValue:)) }
        set { flavorRaw = newValue?.rawValue }
    }

    var tags: [String] {
        get {
            tagsCSV
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        set { tagsCSV = newValue.joined(separator: ",") }
    }

    var manualBadgeIDs: [String] {
        get {
            manualBadgeIDsCSV
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        set { manualBadgeIDsCSV = newValue.joined(separator: ",") }
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Rounded place key for league uniqueness (~11m grid).
    var placeKey: String {
        let lat = (latitude * 10_000).rounded() / 10_000
        let lon = (longitude * 10_000).rounded() / 10_000
        return "\(lat),\(lon)"
    }
}
