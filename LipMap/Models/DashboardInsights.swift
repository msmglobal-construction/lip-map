import Foundation

struct NamedCount: Identifiable, Equatable, Sendable {
    var id: String { name }
    let name: String
    let count: Int
}

struct BucketCount: Identifiable, Equatable, Sendable {
    var id: String { label }
    let label: String
    let count: Int
}

struct DashboardInsights: Equatable, Sendable {
    let lifetimeTucks: Int
    let weekTucks: Int
    let todayTucks: Int
    let uniquePlacesWeek: Int
    let statesVisited: Int
    let flavorsTried: Int
    let timeOfDay: [BucketCount]
    let dayOfWeek: [BucketCount]
    let topPlaces: [NamedCount]
    let topStates: [NamedCount]
    let flavorBreakdown: [NamedCount]
    let peakTimeLabel: String?
    let peakDayLabel: String?

    static func build(pins: [TuckPin], now: Date = .now, calendar: Calendar = .current) -> DashboardInsights {
        let week = LeagueRanking.weekInterval(containing: now, calendar: calendar)
        let dayStart = calendar.startOfDay(for: now)
        let weekPins = pins.filter { week.contains($0.timestamp) }
        let todayPins = pins.filter { $0.timestamp >= dayStart }

        let todBuckets = ["Morning", "Afternoon", "Evening", "Late night"]
        var todCounts = Dictionary(uniqueKeysWithValues: todBuckets.map { ($0, 0) })
        for pin in pins {
            todCounts[Self.timeOfDayLabel(for: pin.timestamp, calendar: calendar), default: 0] += 1
        }
        let timeOfDay = todBuckets.map { BucketCount(label: $0, count: todCounts[$0] ?? 0) }

        let weekdaySymbols = calendar.shortWeekdaySymbols // Sun-first usually
        var dowCounts = Dictionary(uniqueKeysWithValues: weekdaySymbols.map { ($0, 0) })
        for pin in pins {
            let idx = calendar.component(.weekday, from: pin.timestamp) - 1
            if weekdaySymbols.indices.contains(idx) {
                dowCounts[weekdaySymbols[idx], default: 0] += 1
            }
        }
        let dayOfWeek = weekdaySymbols.map { BucketCount(label: $0, count: dowCounts[$0] ?? 0) }

        var placeMap: [String: Int] = [:]
        for pin in pins {
            let label = pin.placeLabel
            guard label != "Unknown place" else { continue }
            placeMap[label, default: 0] += 1
        }
        let topPlaces = placeMap
            .map { NamedCount(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }

        var stateMap: [String: Int] = [:]
        for pin in pins {
            if let state = USState.resolve(code: pin.regionCode, name: pin.regionName) {
                stateMap[state.name, default: 0] += 1
            }
        }
        let topStates = stateMap
            .map { NamedCount(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }

        var flavorMap: [String: Int] = [:]
        for pin in pins {
            let name = pin.flavor?.rawValue ?? "Unlabeled"
            flavorMap[name, default: 0] += 1
        }
        let flavorBreakdown = flavorMap
            .map { NamedCount(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }

        let flavorsTried = Set(pins.compactMap(\.flavor)).count
        let peakTime = timeOfDay.max(by: { $0.count < $1.count })
        let peakDay = dayOfWeek.max(by: { $0.count < $1.count })

        return DashboardInsights(
            lifetimeTucks: pins.count,
            weekTucks: weekPins.count,
            todayTucks: todayPins.count,
            uniquePlacesWeek: LeagueRanking.placeKeys(from: pins, in: week).count,
            statesVisited: StateAtlas.visited(from: pins).count,
            flavorsTried: flavorsTried,
            timeOfDay: timeOfDay,
            dayOfWeek: dayOfWeek,
            topPlaces: Array(topPlaces),
            topStates: Array(topStates),
            flavorBreakdown: flavorBreakdown,
            peakTimeLabel: (peakTime?.count ?? 0) > 0 ? peakTime?.label : nil,
            peakDayLabel: (peakDay?.count ?? 0) > 0 ? peakDay?.label : nil
        )
    }

    private static func timeOfDayLabel(for date: Date, calendar: Calendar) -> String {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<22: return "Evening"
        default: return "Late night"
        }
    }
}
