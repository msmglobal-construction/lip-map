import Foundation

enum BadgeEvaluator {
    /// Lifetime tuck count = successful Tucked taps (one pin per success).
    static func lifetimeTuckCount(pins: [TuckPin]) -> Int {
        pins.count
    }

    static func unlocked(
        pins: [TuckPin],
        now: Date = .now
    ) -> Set<LipBadge> {
        var unlocked = Set<LipBadge>()
        let sorted = pins.sorted { $0.timestamp < $1.timestamp }
        let lifetime = lifetimeTuckCount(pins: pins)

        // Count-only milestones — no place / POI / map requirement.
        for badge in LipBadge.allCases where badge.isLifetimeMilestone {
            if let threshold = badge.lifetimeTuckThreshold, lifetime >= threshold {
                unlocked.insert(badge)
            }
        }

        // Flavor milestones.
        let flavors = Set(sorted.compactMap(\.flavor))
        if flavors.contains(.coolMint) {
            unlocked.insert(.firstCoolMint)
        }
        if flavors.count >= 5 {
            unlocked.insert(.flavorTourist)
        }
        if flavors.count >= 10 {
            unlocked.insert(.fullFlight)
        }
        let mintCount = sorted.filter { $0.flavor?.isMintFamily == true }.count
        if mintCount >= 5 {
            unlocked.insert(.mintMachine)
        }

        // State travel.
        if StateAtlas.visited(from: sorted).count >= 5 {
            unlocked.insert(.zynbabwe)
        }

        guard !sorted.isEmpty else { return unlocked }

        for pin in sorted {
            let tags = Set(pin.tags.map { $0.lowercased() })
            let manuals = Set(pin.manualBadgeIDs)

            if tags.contains("coffee") || tags.contains("cafe") || tags.contains("zynachino")
                || pin.flavor == .coffee || pin.flavor == .espresso {
                unlocked.insert(.zynachino)
            }
            if tags.contains("church") || tags.contains("chapel") {
                unlocked.insert(.churchParkingLot)
            }
            if tags.contains("airport") || tags.contains("gate") {
                unlocked.insert(.gateB12)
            }
            if tags.contains("boat") || tags.contains("marina") || tags.contains("water") {
                unlocked.insert(.boat)
            }
            if tags.contains("interstate") || tags.contains("highway") {
                unlocked.insert(.interstate)
            }
            if tags.contains("upperdeck") || tags.contains("upper deck") || tags.contains("stadium") {
                unlocked.insert(.upperDeck)
            }

            if manuals.contains(LipBadge.herParentsHouse.rawValue) {
                unlocked.insert(.herParentsHouse)
            }
            if manuals.contains(LipBadge.workBathroom.rawValue) {
                unlocked.insert(.workBathroom)
            }
            if manuals.contains(LipBadge.deerStand.rawValue) {
                unlocked.insert(.deerStand)
            }

            let hour = Calendar.current.component(.hour, from: pin.timestamp)
            if hour == 2 {
                unlocked.insert(.twoOhSevenAM)
            }
        }

        // Two pins within 3 minutes.
        if sorted.count >= 2 {
            for i in 1..<sorted.count {
                let delta = sorted[i].timestamp.timeIntervalSince(sorted[i - 1].timestamp)
                if delta >= 0 && delta <= 180 {
                    unlocked.insert(.twoInOneRedLight)
                    break
                }
            }
        }

        _ = now
        return unlocked
    }
}
