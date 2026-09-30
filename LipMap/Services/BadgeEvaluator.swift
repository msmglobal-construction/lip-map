import Foundation

enum BadgeEvaluator {
    static func unlocked(
        pins: [TuckPin],
        now: Date = .now
    ) -> Set<LipBadge> {
        var unlocked = Set<LipBadge>()
        let sorted = pins.sorted { $0.timestamp < $1.timestamp }
        guard let first = sorted.first else { return unlocked }

        unlocked.insert(.firstOne)

        for pin in sorted {
            let tags = Set(pin.tags.map { $0.lowercased() })
            let manuals = Set(pin.manualBadgeIDs)

            if tags.contains("coffee") || tags.contains("cafe") || tags.contains("zynachino") {
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

        _ = first
        _ = now
        return unlocked
    }
}
