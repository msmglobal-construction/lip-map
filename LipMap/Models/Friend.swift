import Foundation
import SwiftData

@Model
final class FriendProfile {
    var id: UUID
    /// Stable 6-digit share code for this device.
    var myCode: String
    var displayName: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        myCode: String,
        displayName: String = "Me",
        createdAt: Date = .now
    ) {
        self.id = id
        self.myCode = myCode
        self.displayName = displayName
        self.createdAt = createdAt
    }
}

@Model
final class FriendLink {
    var id: UUID
    var code: String
    var displayName: String
    var addedAt: Date
    /// Weekly unique place keys synced or stubbed for league.
    var weeklyPlaceKeysCSV: String
    var lastSyncedAt: Date?

    init(
        id: UUID = UUID(),
        code: String,
        displayName: String,
        addedAt: Date = .now,
        weeklyPlaceKeys: [String] = [],
        lastSyncedAt: Date? = nil
    ) {
        self.id = id
        self.code = code
        self.displayName = displayName
        self.addedAt = addedAt
        self.weeklyPlaceKeysCSV = weeklyPlaceKeys.joined(separator: "|")
        self.lastSyncedAt = lastSyncedAt
    }

    var weeklyPlaceKeys: [String] {
        get {
            weeklyPlaceKeysCSV
                .split(separator: "|")
                .map(String.init)
                .filter { !$0.isEmpty }
        }
        set { weeklyPlaceKeysCSV = newValue.joined(separator: "|") }
    }

    var uniquePlaceCount: Int { Set(weeklyPlaceKeys).count }
}
