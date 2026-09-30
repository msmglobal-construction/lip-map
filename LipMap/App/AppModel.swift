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
    var friendsService: FriendsService?
    var isTucking = false
    var tuckError: String?
    var showPaywall = false
    var pendingFlavorPinID: UUID?
    var didShowLocationSentence = false

    private let defaults: UserDefaults

    init(
        location: LocationProviding? = nil,
        entitlements: EntitlementServing? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.location = location ?? LocationProvider()
        self.entitlements = entitlements ?? EntitlementStore()
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

    /// Primary action: haptic → location → save pin.
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
            // First pin auto-earns First One via evaluator; no extra work.
            if existingPins.isEmpty {
                // no-op — BadgeEvaluator handles .firstOne
            }
            modelContext.insert(pin)
            try modelContext.save()
            pendingFlavorPinID = pin.id

            // POI tags in background — must not slow first tap.
            Task {
                let tags = await POITagger.suggestTags(for: coordinate)
                if !tags.isEmpty {
                    pin.tags = Array(Set(pin.tags + tags))
                    try? modelContext.save()
                }
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
