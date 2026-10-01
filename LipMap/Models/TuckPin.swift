import Foundation
import SwiftData
import CoreLocation

/// Common US pouch flavor names (brand-agnostic labels).
enum TuckFlavor: String, Codable, CaseIterable, Identifiable, Sendable {
    case coolMint = "Cool Mint"
    case spearmint = "Spearmint"
    case peppermint = "Peppermint"
    case menthol = "Menthol"
    case wintergreen = "Wintergreen"
    case peppermintIce = "Peppermint Ice"
    case citrus = "Citrus"
    case lemon = "Lemon"
    case lime = "Lime"
    case orange = "Orange"
    case coffee = "Coffee"
    case espresso = "Espresso"
    case chill = "Chill"
    case smooth = "Smooth"
    case blackCherry = "Black Cherry"
    case appleMint = "Apple Mint"
    case vanilla = "Vanilla"
    case dragonFruit = "Dragon Fruit"
    case other = "Other"

    var id: String { rawValue }

    var isMintFamily: Bool {
        switch self {
        case .coolMint, .spearmint, .peppermint, .menthol, .wintergreen, .peppermintIce, .appleMint:
            return true
        default:
            return false
        }
    }
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
    /// US state / region code from reverse geocode (e.g. "TX").
    var regionCode: String?
    /// Full administrative area name (e.g. "Texas").
    var regionName: String?
    /// City / locality when available.
    var locality: String?

    init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        timestamp: Date = .now,
        flavor: TuckFlavor? = nil,
        tags: [String] = [],
        manualBadgeIDs: [String] = [],
        regionCode: String? = nil,
        regionName: String? = nil,
        locality: String? = nil
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.flavorRaw = flavor?.rawValue
        self.tagsCSV = tags.joined(separator: ",")
        self.manualBadgeIDsCSV = manualBadgeIDs.joined(separator: ",")
        self.regionCode = regionCode
        self.regionName = regionName
        self.locality = locality
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

    var placeLabel: String {
        if let locality, !locality.isEmpty, let regionCode, !regionCode.isEmpty {
            return "\(locality), \(regionCode)"
        }
        if let regionName, !regionName.isEmpty { return regionName }
        if let locality, !locality.isEmpty { return locality }
        return "Unknown place"
    }
}
