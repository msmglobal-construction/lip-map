import Foundation
import CoreLocation
import MapKit

/// Best-effort place tags after a tuck. Never blocks the primary Tucked path.
enum POITagger {
    static func suggestTags(for coordinate: CLLocationCoordinate2D) async -> [String] {
        #if canImport(MapKit)
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        var tags: [String] = []
        if let placemarks = try? await geocoder.reverseGeocodeLocation(location),
           let place = placemarks.first {
            let blob = [
                place.name,
                place.areasOfInterest?.joined(separator: " "),
                place.thoroughfare,
                place.subThoroughfare,
                place.locality
            ]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()

            if blob.contains("coffee") || blob.contains("cafe") || blob.contains("starbucks") {
                tags.append("coffee")
            }
            if blob.contains("church") || blob.contains("chapel") || blob.contains("cathedral") {
                tags.append("church")
            }
            if blob.contains("airport") || blob.contains("terminal") || place.areasOfInterest?.contains(where: { $0.lowercased().contains("airport") }) == true {
                tags.append("airport")
            }
            if blob.contains("marina") || blob.contains("harbor") || blob.contains("harbour") || blob.contains("boat") {
                tags.append("boat")
            }
            if blob.contains("i-") || blob.contains("interstate") || blob.contains("highway") || blob.contains("freeway") {
                tags.append("interstate")
            }
            if blob.contains("stadium") || blob.contains("upper deck") {
                tags.append("stadium")
            }
        }

        // Lightweight local search around the pin.
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "coffee airport church marina"
        request.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
        )
        if let response = try? await MKLocalSearch(request: request).start() {
            for item in response.mapItems.prefix(8) {
                let name = (item.name ?? "").lowercased()
                let category = item.pointOfInterestCategory
                if category == .cafe || name.contains("coffee") || name.contains("cafe") {
                    tags.append("coffee")
                }
                if category == .airport || name.contains("airport") {
                    tags.append("airport")
                }
                if name.contains("church") || name.contains("chapel") {
                    tags.append("church")
                }
                if category == .marina || name.contains("marina") || name.contains("boat") {
                    tags.append("boat")
                }
            }
        }
        return Array(Set(tags))
        #else
        return []
        #endif
    }
}
