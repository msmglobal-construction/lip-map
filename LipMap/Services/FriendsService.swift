import Foundation
import SwiftData
import Observation

#if canImport(CloudKit)
import CloudKit
#endif

/// Friends via 6-digit codes + follow requests. CloudKit when configured; otherwise local mailbox.
@Observable
@MainActor
final class FriendsService {
    /// Flip to true on Mac after enabling the iCloud container in Xcode / ASC.
    static let isCloudKitConfigured = false

    private let modelContext: ModelContext
    private let defaults: UserDefaults

    private(set) var myCode: String
    /// Accepted follows only — pins and league.
    private(set) var friends: [FriendLink] = []
    private(set) var incomingPending: [FollowRequest] = []
    private(set) var outgoingPending: [FollowRequest] = []

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
        ingestMailbox()
    }

    func reload() {
        let friendDescriptor = FetchDescriptor<FriendLink>(sortBy: [SortDescriptor(\.addedAt, order: .forward)])
        friends = (try? modelContext.fetch(friendDescriptor)) ?? []

        let requestDescriptor = FetchDescriptor<FollowRequest>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let all = (try? modelContext.fetch(requestDescriptor)) ?? []
        incomingPending = all.filter { $0.direction == .incoming && $0.status == .pending }
        outgoingPending = all.filter { $0.direction == .outgoing && $0.status == .pending }
    }

    /// Type their 6-digit code → send a follow request (not an instant follow).
    @discardableResult
    func sendFollowRequest(code raw: String, displayName: String? = nil) throws -> FollowRequest {
        let code = Self.normalize(raw)
        guard code.count == 6, code.allSatisfy(\.isNumber) else {
            throw FriendsError.invalidCode
        }
        guard code != myCode else { throw FriendsError.cannotAddSelf }
        if friends.contains(where: { $0.code == code }) {
            throw FriendsError.alreadyFollowing
        }
        if outgoingPending.contains(where: { $0.peerCode == code }) {
            throw FriendsError.requestAlreadyPending
        }

        let name = displayName ?? "Friend \(code)"
        let request = FollowRequest(
            peerCode: code,
            displayName: name,
            direction: .outgoing,
            status: .pending
        )
        modelContext.insert(request)
        try modelContext.save()
        postOutgoingToMailbox(toCode: code)
        reload()
        return request
    }

    func acceptRequest(_ request: FollowRequest) throws {
        guard request.direction == .incoming, request.status == .pending else { return }
        request.status = .accepted
        postAcceptanceToMailbox(requesterCode: request.peerCode)
        try modelContext.save()
        reload()
    }

    /// Decline (or ignore) an incoming request — no follow is created.
    func declineRequest(_ request: FollowRequest) throws {
        guard request.direction == .incoming, request.status == .pending else { return }
        request.status = .declined
        removeIncomingFromMailbox(fromCode: request.peerCode)
        postDeclineToMailbox(requesterCode: request.peerCode)
        try modelContext.save()
        reload()
    }

    /// Cancel an outgoing request you sent (optional cleanup).
    func cancelOutgoingRequest(_ request: FollowRequest) throws {
        guard request.direction == .outgoing, request.status == .pending else { return }
        removeOutgoingFromMailbox(toCode: request.peerCode)
        modelContext.delete(request)
        try modelContext.save()
        reload()
    }

    func removeFriend(_ friend: FriendLink) throws {
        modelContext.delete(friend)
        try modelContext.save()
        reload()
    }

    /// Pull mailbox updates: new incoming requests, acceptances, declines.
    func refreshRequests() {
        ingestMailbox()
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
        refreshRequests()
        for friend in friends {
            await syncFriend(friend)
        }
        reload()
    }

    func leagueEntries(myName: String, myWeeklyPlaceKeys: Set<String>) -> [LeagueEntry] {
        // League uses accepted follows only.
        LeagueRanking.rank(
            myCode: myCode,
            myName: myName,
            myWeeklyPlaceKeys: myWeeklyPlaceKeys,
            friends: friends.map { ($0.code, $0.displayName, Set($0.weeklyPlaceKeys)) }
        )
    }

    // MARK: - Mailbox (local / demo until CloudKit)

    private func postOutgoingToMailbox(toCode: String) {
        var inbox = mailboxIncoming(for: toCode)
        if !inbox.contains(where: { $0["from"] == myCode }) {
            inbox.append(["from": myCode, "name": "Friend \(myCode)"])
            setMailboxIncoming(inbox, for: toCode)
        }
    }

    private func removeOutgoingFromMailbox(toCode: String) {
        var inbox = mailboxIncoming(for: toCode)
        inbox.removeAll { $0["from"] == myCode }
        setMailboxIncoming(inbox, for: toCode)
    }

    private func removeIncomingFromMailbox(fromCode: String) {
        var inbox = mailboxIncoming(for: myCode)
        inbox.removeAll { $0["from"] == fromCode }
        setMailboxIncoming(inbox, for: myCode)
    }

    private func postAcceptanceToMailbox(requesterCode: String) {
        var accepted = mailboxAccepted(for: requesterCode)
        if !accepted.contains(myCode) {
            accepted.append(myCode)
            setMailboxAccepted(accepted, for: requesterCode)
        }
        removeIncomingFromMailbox(fromCode: requesterCode)
    }

    private func postDeclineToMailbox(requesterCode: String) {
        var declined = mailboxDeclined(for: requesterCode)
        if !declined.contains(myCode) {
            declined.append(myCode)
            setMailboxDeclined(declined, for: requesterCode)
        }
    }

    private func ingestMailbox() {
        // Incoming requests addressed to me.
        for entry in mailboxIncoming(for: myCode) {
            guard let from = entry["from"], from.count == 6, from != myCode else { continue }
            if friends.contains(where: { $0.code == from }) { continue }
            let existing = fetchRequest(peerCode: from, direction: .incoming)
            if existing == nil {
                let name = entry["name"] ?? "Friend \(from)"
                modelContext.insert(
                    FollowRequest(peerCode: from, displayName: name, direction: .incoming, status: .pending)
                )
            }
        }

        // Acceptances of my outgoing requests → create FriendLink, mark accepted.
        let acceptedForMe = mailboxAccepted(for: myCode)
        for code in acceptedForMe {
            if let outgoing = fetchRequest(peerCode: code, direction: .outgoing),
               outgoing.status == .pending {
                outgoing.status = .accepted
            }
            if !friends.contains(where: { $0.code == code }) {
                let name = fetchRequest(peerCode: code, direction: .outgoing)?.displayName ?? "Friend \(code)"
                let link = FriendLink(code: code, displayName: name)
                modelContext.insert(link)
                Task { await syncFriend(link) }
            }
            // Clear from pending inbox on their side already handled; drop our accepted token after apply.
        }
        if !acceptedForMe.isEmpty {
            setMailboxAccepted([], for: myCode)
        }

        // Declines of my outgoing requests.
        let declinedForMe = mailboxDeclined(for: myCode)
        for code in declinedForMe {
            if let outgoing = fetchRequest(peerCode: code, direction: .outgoing),
               outgoing.status == .pending {
                outgoing.status = .declined
            }
        }
        if !declinedForMe.isEmpty {
            setMailboxDeclined([], for: myCode)
        }

        try? modelContext.save()
    }

    private func fetchRequest(peerCode: String, direction: FollowRequestDirection) -> FollowRequest? {
        let descriptor = FetchDescriptor<FollowRequest>()
        let all = (try? modelContext.fetch(descriptor)) ?? []
        return all.first { $0.peerCode == peerCode && $0.direction == direction }
    }

    private func mailboxIncoming(for code: String) -> [[String: String]] {
        defaults.array(forKey: Keys.incomingPrefix + code) as? [[String: String]] ?? []
    }

    private func setMailboxIncoming(_ value: [[String: String]], for code: String) {
        defaults.set(value, forKey: Keys.incomingPrefix + code)
    }

    private func mailboxAccepted(for code: String) -> [String] {
        defaults.stringArray(forKey: Keys.acceptedPrefix + code) ?? []
    }

    private func setMailboxAccepted(_ value: [String], for code: String) {
        defaults.set(value, forKey: Keys.acceptedPrefix + code)
    }

    private func mailboxDeclined(for code: String) -> [String] {
        defaults.stringArray(forKey: Keys.declinedPrefix + code) ?? []
    }

    private func setMailboxDeclined(_ value: [String], for code: String) {
        defaults.set(value, forKey: Keys.declinedPrefix + code)
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
        static let incomingPrefix = "lipmap.friends.incoming."
        static let acceptedPrefix = "lipmap.friends.accepted."
        static let declinedPrefix = "lipmap.friends.declined."
    }
}

enum FriendsError: Error, LocalizedError {
    case invalidCode
    case cannotAddSelf
    case alreadyFollowing
    case requestAlreadyPending

    var errorDescription: String? {
        switch self {
        case .invalidCode: return "Enter a 6-digit code."
        case .cannotAddSelf: return "That’s your code."
        case .alreadyFollowing: return "Already following."
        case .requestAlreadyPending: return "Request already pending."
        }
    }
}
