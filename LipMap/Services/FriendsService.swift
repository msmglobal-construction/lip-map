import Foundation
import SwiftData
import Observation

#if canImport(CloudKit)
import CloudKit
#endif

/// Friends via 6-digit codes. CloudKit when configured; otherwise local links + published place keys.
@Observable
@MainActor
final class FriendsService {
    /// Flip to true on Mac after enabling the iCloud container in Xcode / ASC.
    static let isCloudKitConfigured = false

    private let modelContext: ModelContext
    private let defaults: UserDefaults

    private(set) var myCode: String
    private(set) var friends: [FriendLink] = []

    init(modelContext: ModelContext, defaults: UserDefaults = .standard) {
        self.modelContext = modelContext
        self.defaults = defaults
        if let existing = defaults.string(forKey: Keys.myCode), existing.count == 6 {
            myCode = existing
        } else {
            myCode = Self.makeCode()
            defaults.set(myCode, forKey: Keys.myCode)
        }
        ensureProfile()
        reload()
    }

    func reload() {
        let descriptor = FetchDescriptor<FriendLink>(sortBy: [SortDescriptor(\.addedAt, order: .forward)])
        friends = (try? modelContext.fetch(descriptor)) ?? []
    }

    @discardableResult
    func addFriend(code raw: String, displayName: String? = nil) throws -> FriendLink {
        let code = Self.normalize(raw)
        guard code.count == 6, code.allSatisfy(\.isNumber) else {
            throw FriendsError.invalidCode
        }
        guard code != myCode else { throw FriendsError.cannotAddSelf }
        if friends.contains(where: { $0.code == code }) {
            throw FriendsError.alreadyAdded
        }
        let link = FriendLink(
            code: code,
            displayName: displayName ?? "Friend \(code)"
        )
        modelContext.insert(link)
        try modelContext.save()
        reload()
        Task { await syncFriend(link) }
        return link
    }

    func removeFriend(_ friend: FriendLink) throws {
        modelContext.delete(friend)
        try modelContext.save()
        reload()
    }

    /// Publish this week's unique place keys under our code (CloudKit or local cache).
    func publishWeeklyPlaces(_ placeKeys: Set<String>) async {
        defaults.set(Array(placeKeys), forKey: Keys.myWeeklyPlaces)
        #if canImport(CloudKit)
        guard Self.isCloudKitConfigured else { return }
        await publishToCloudKit(placeKeys: placeKeys)
        #endif
    }

    func refreshFriendsLeague() async {
        for friend in friends {
            await syncFriend(friend)
        }
        reload()
    }

    func leagueEntries(myName: String, myWeeklyPlaceKeys: Set<String>) -> [LeagueEntry] {
        LeagueRanking.rank(
            myCode: myCode,
            myName: myName,
            myWeeklyPlaceKeys: myWeeklyPlaceKeys,
            friends: friends.map { ($0.code, $0.displayName, Set($0.weeklyPlaceKeys)) }
        )
    }

    // MARK: - Private

    private func ensureProfile() {
        let descriptor = FetchDescriptor<FriendProfile>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        if existing.isEmpty {
            modelContext.insert(FriendProfile(myCode: myCode))
            try? modelContext.save()
        }
    }

    private func syncFriend(_ friend: FriendLink) async {
        #if canImport(CloudKit)
        if Self.isCloudKitConfigured {
            if let keys = await fetchCloudKitPlaces(code: friend.code) {
                friend.weeklyPlaceKeys = Array(keys)
                friend.lastSyncedAt = .now
                try? modelContext.save()
                return
            }
        }
        #endif
        // Local/demo: if friend code matches a stored peer blob (same device testing), adopt it.
        if let cached = defaults.stringArray(forKey: Keys.peerPrefix + friend.code) {
            friend.weeklyPlaceKeys = cached
            friend.lastSyncedAt = .now
            try? modelContext.save()
        }
    }

    #if canImport(CloudKit)
    private func publishToCloudKit(placeKeys: Set<String>) async {
        let container = CKContainer(identifier: "iCloud.com.lipmap.app")
        let db = container.publicCloudDatabase
        let recordID = CKRecord.ID(recordName: "lipmap.code.\(myCode)")
        let record = CKRecord(recordType: "LipMapFriendWeek", recordID: recordID)
        record["code"] = myCode as NSString
        record["placeKeys"] = Array(placeKeys) as NSArray
        record["updatedAt"] = Date() as NSDate
        do {
            _ = try await db.save(record)
        } catch {
            // Overwrite path
            do {
                let existing = try await db.record(for: recordID)
                existing["placeKeys"] = Array(placeKeys) as NSArray
                existing["updatedAt"] = Date() as NSDate
                _ = try await db.save(existing)
            } catch {
                // CloudKit not provisioned yet — fine on first Mac setup.
            }
        }
    }

    private func fetchCloudKitPlaces(code: String) async -> Set<String>? {
        let container = CKContainer(identifier: "iCloud.com.lipmap.app")
        let db = container.publicCloudDatabase
        let recordID = CKRecord.ID(recordName: "lipmap.code.\(code)")
        do {
            let record = try await db.record(for: recordID)
            let keys = record["placeKeys"] as? [String] ?? []
            return Set(keys)
        } catch {
            return nil
        }
    }
    #endif

    static func makeCode() -> String {
        String(format: "%06d", Int.random(in: 0...999_999))
    }

    static func normalize(_ raw: String) -> String {
        raw.filter(\.isNumber)
    }

    private enum Keys {
        static let myCode = "lipmap.friends.myCode"
        static let myWeeklyPlaces = "lipmap.friends.myWeeklyPlaces"
        static let peerPrefix = "lipmap.friends.peer."
    }
}

enum FriendsError: Error, LocalizedError {
    case invalidCode
    case cannotAddSelf
    case alreadyAdded

    var errorDescription: String? {
        switch self {
        case .invalidCode: return "Enter a 6-digit code."
        case .cannotAddSelf: return "That’s your code."
        case .alreadyAdded: return "Already following."
        }
    }
}
