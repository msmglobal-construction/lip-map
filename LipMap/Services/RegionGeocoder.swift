import Foundation
import CoreLocation

struct RegionLookup: Sendable {
    var regionCode: String?
    var regionName: String?
    var locality: String?
}

protocol RegionLookingUp: Sendable {
    func lookup(coordinate: CLLocationCoordinate2D) async -> RegionLookup
}

/// Reverse-geocodes pins to US state / locality. Best-effort; never blocks Tucked.
struct RegionGeocoder: RegionLookingUp {
    func lookup(coordinate: CLLocationCoordinate2D) async -> RegionLookup {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let place = placemarks.first else { return RegionLookup() }
            let resolved = USState.resolve(code: place.administrativeArea, name: place.administrativeArea)
            return RegionLookup(
                regionCode: resolved?.code ?? place.administrativeArea,
                regionName: resolved?.name ?? place.administrativeArea,
                locality: place.locality ?? place.subLocality
            )
        } catch {
            return RegionLookup()
        }
    }
}
