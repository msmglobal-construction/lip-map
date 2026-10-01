import Foundation
import SwiftData
import Observation
import CoreLocation

#if canImport(UIKit)
import UIKit
#endif

@Observable
@MainActor
final class AppModel {
    let location: LocationProviding
    let entitlements: EntitlementServing
    let regionGeocoder: any RegionLookingUp
    var friendsService: FriendsService?
    var isTucking = false
    var tuckError: String?
    var showPaywall = false
    var pendingFlavorPinID: UUID?
    var didShowLocationSentence = false
    /// Deep-link / invite code waiting to become a follow request.
    var pendingInviteCode: String?
    var selectedTab: Int = 0

    private let defaults: UserDefaults

    init(
        location: LocationProviding? = nil,
        entitlements: EntitlementServing? = nil,
        regionGeocoder: (any RegionLookingUp)? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.location = location ?? LocationProvider()
        self.entitlements = entitlements ?? EntitlementStore()
        self.regionGeocoder = regionGeocoder ?? RegionGeocoder()
        self.defaults = defaults
        self.didShowLocationSentence = defaults.bool(forKey: Keys.locationSentenceShown)
    }

    func attachFriends(modelContext: ModelContext) {
        if friendsService == nil {
            friendsService = FriendsService(modelContext: modelContext, defaults: defaults)
        }
    }

    func paywallGate(pins: [TuckPin], now: Date = .now) -> PaywallGate {
        PaywallGate(
            tuckCount: pins.count,
            firstTuckDate: pins.map(\.timestamp).min(),
            isSubscribed: entitlements.isSubscribed,
            now: now
        )
    }

    func todayCount(pins: [TuckPin], now: Date = .now) -> Int {
        let start = Calendar.current.startOfDay(for: now)
        return pins.filter { $0.timestamp >= start }.count
    }

    func lastTuck(pins: [TuckPin]) -> TuckPin? {
        pins.max(by: { $0.timestamp < $1.timestamp })
    }

    func visiblePins(_ pins: [TuckPin], now: Date = .now) -> [TuckPin] {
        let gate = paywallGate(pins: pins, now: now)
        return pins.filter { gate.isPinVisible($0.timestamp) }
    }

    /// Primary action: haptic → location → save pin. Flavor sheet is optional and never blocks the tap.
    func tuck(modelContext: ModelContext, existingPins: [TuckPin]) async {
        guard !isTucking else { return }
        isTucking = true
        tuckError = nil
        defer { isTucking = false }

        let gate = paywallGate(pins: existingPins)
        if gate.isHardPaywallRequired {
            showPaywall = true
            return
        }

        if !didShowLocationSentence {
            didShowLocationSentence = true
            defaults.set(true, forKey: Keys.locationSentenceShown)
        }

        fireHaptic()
        location.requestWhenInUseIfNeeded()

        do {
            let coordinate = try await location.currentCoordinate()
            let pin = TuckPin(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                timestamp: .now
            )
            modelContext.insert(pin)
            try modelContext.save()
            pendingFlavorPinID = pin.id

            // POI + region geocode in background — must not slow first tap.
            Task {
                async let tagsTask = POITagger.suggestTags(for: coordinate)
                async let regionTask = regionGeocoder.lookup(coordinate: coordinate)
                let tags = await tagsTask
                let region = await regionTask
                if !tags.isEmpty {
                    pin.tags = Array(Set(pin.tags + tags))
                }
                if let code = region.regionCode { pin.regionCode = code }
                if let name = region.regionName { pin.regionName = name }
                if let locality = region.locality { pin.locality = locality }
                try? modelContext.save()
            }

            let all = existingPins + [pin]
            let week = LeagueRanking.weekInterval()
            let keys = LeagueRanking.placeKeys(from: all, in: week)
            await friendsService?.publishWeeklyPlaces(keys)

            let afterGate = paywallGate(pins: all)
            if afterGate.isHardPaywallRequired {
                showPaywall = true
            }
        } catch {
            tuckError = error.localizedDescription
        }
    }

    func applyFlavor(_ flavor: TuckFlavor?, to pin: TuckPin, modelContext: ModelContext) {
        pin.flavor = flavor
        try? modelContext.save()
        pendingFlavorPinID = nil
    }

    /// Delete an accidental / unwanted tuck. Updates map, counts, league, badges via SwiftData.
    func deletePin(_ pin: TuckPin, modelContext: ModelContext, remainingPins: [TuckPin]) async {
        if pendingFlavorPinID == pin.id {
            pendingFlavorPinID = nil
        }
        modelContext.delete(pin)
        try? modelContext.save()
        let week = LeagueRanking.weekInterval()
        let keys = LeagueRanking.placeKeys(from: remainingPins.filter { $0.id != pin.id }, in: week)
        await friendsService?.publishWeeklyPlaces(keys)
    }

    func handleIncomingURL(_ url: URL) {
        guard let code = InviteLink.parseCode(from: url) else { return }
        pendingInviteCode = code
        selectedTab = 3 // Friends
    }

    /// Apply a pending invite code as an outgoing follow request (after friends service is ready).
    @discardableResult
    func consumePendingInvite(displayName: String? = nil) throws -> FollowRequest? {
        guard let code = pendingInviteCode else { return nil }
        guard let friendsService else { return nil }
        pendingInviteCode = nil
        return try friendsService.sendFollowRequest(code: code, displayName: displayName)
    }

    private func fireHaptic() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }

    private enum Keys {
        static let locationSentenceShown = "lipmap.locationSentenceShown"
    }
}

enum InviteLink {
    static let scheme = "lipmap"

    static func makeURL(code: String) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "invite"
        components.queryItems = [URLQueryItem(name: "code", value: FriendsService.normalize(code))]
        return components.url ?? URL(string: "\(scheme)://invite?code=\(FriendsService.normalize(code))")!
    }

    static func shareMessage(myCode: String) -> String {
        let link = makeURL(code: myCode).absoluteString
        return "Add me on Lip Map — tap to send a follow request: \(link)\n(Code \(myCode) if the link doesn’t open.)"
    }

    static func parseCode(from url: URL) -> String? {
        guard url.scheme?.lowercased() == scheme else { return nil }
        if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let raw = items.first(where: { $0.name == "code" })?.value {
            let code = FriendsService.normalize(raw)
            return code.count == 6 ? code : nil
        }
        // lipmap://join/123456
        let parts = url.path.split(separator: "/").map(String.init)
        if let last = parts.last {
            let code = FriendsService.normalize(last)
            if code.count == 6 { return code }
        }
        if let host = url.host, host.count == 6, host.allSatisfy(\.isNumber) {
            return host
        }
        return nil
    }
}
