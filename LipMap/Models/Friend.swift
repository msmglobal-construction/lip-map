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

/// Accepted follow only — pins / league sync after the peer accepts your request.
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

enum FollowRequestDirection: String, Codable, Sendable {
    case outgoing
    case incoming
}

enum FollowRequestStatus: String, Codable, Sendable {
    case pending
    case accepted
    case declined
}

/// Pending (or resolved) follow request. Accepted follows live on `FriendLink`.
@Model
final class FollowRequest {
    var id: UUID
    var peerCode: String
    var displayName: String
    var directionRaw: String
    var statusRaw: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        peerCode: String,
        displayName: String,
        direction: FollowRequestDirection,
        status: FollowRequestStatus = .pending,
        createdAt: Date = .now
    ) {
        self.id = id
        self.peerCode = peerCode
        self.displayName = displayName
        self.directionRaw = direction.rawValue
        self.statusRaw = status.rawValue
        self.createdAt = createdAt
    }

    var direction: FollowRequestDirection {
        get { FollowRequestDirection(rawValue: directionRaw) ?? .outgoing }
        set { directionRaw = newValue.rawValue }
    }

    var status: FollowRequestStatus {
        get { FollowRequestStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }
}
