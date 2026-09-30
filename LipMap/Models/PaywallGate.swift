import Foundation

struct PaywallGate: Equatable, Sendable {
    static let tuckLimit = 20
    static let dayLimit = 7

    var tuckCount: Int
    var firstTuckDate: Date?
    var isSubscribed: Bool
    var now: Date

    var daysSinceFirstTuck: Int? {
        guard let firstTuckDate else { return nil }
        let start = Calendar.current.startOfDay(for: firstTuckDate)
        let end = Calendar.current.startOfDay(for: now)
        return Calendar.current.dateComponents([.day], from: start, to: end).day
    }

    /// Hard paywall when 20 tucks OR 7 days since first tuck (whichever first).
    var isHardPaywallRequired: Bool {
        if isSubscribed { return false }
        if tuckCount >= Self.tuckLimit { return true }
        if let days = daysSinceFirstTuck, days >= Self.dayLimit { return true }
        return false
    }

    var canSeeAllTimePins: Bool { isSubscribed }
    var canUnlockBadgeArt: Bool { isSubscribed }
    var canUseFriendsLeague: Bool { isSubscribed }

    /// Free tier: pins from the last 7 days only.
    func isPinVisible(_ timestamp: Date) -> Bool {
        if isSubscribed { return true }
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        return timestamp >= cutoff
    }
}
