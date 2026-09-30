import Foundation

struct LeagueEntry: Identifiable, Equatable, Sendable {
    var id: String { code }
    var code: String
    var displayName: String
    var uniquePlaces: Int
    var isMe: Bool
}

enum LeagueRanking {
    /// Rank by unique pin locations this week — never total pouches.
    static func rank(
        myCode: String,
        myName: String,
        myWeeklyPlaceKeys: Set<String>,
        friends: [(code: String, name: String, placeKeys: Set<String>)]
    ) -> [LeagueEntry] {
        var entries: [LeagueEntry] = [
            LeagueEntry(
                code: myCode,
                displayName: myName,
                uniquePlaces: myWeeklyPlaceKeys.count,
                isMe: true
            )
        ]
        for friend in friends {
            entries.append(
                LeagueEntry(
                    code: friend.code,
                    displayName: friend.name,
                    uniquePlaces: friend.placeKeys.count,
                    isMe: false
                )
            )
        }
        return entries.sorted { lhs, rhs in
            if lhs.uniquePlaces != rhs.uniquePlaces {
                return lhs.uniquePlaces > rhs.uniquePlaces
            }
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }

    static func weekInterval(containing date: Date = .now, calendar: Calendar = .current) -> DateInterval {
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? date
        return DateInterval(start: weekStart, end: weekEnd)
    }

    static func placeKeys(from pins: [TuckPin], in interval: DateInterval) -> Set<String> {
        Set(pins.filter { interval.contains($0.timestamp) }.map(\.placeKey))
    }
}
