import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

struct FriendsView: View {
    @Environment(AppModel.self) private var appModel
    @Query(sort: \TuckPin.timestamp, order: .reverse) private var pins: [TuckPin]
    @State private var pasteCode = ""
    @State private var errorText: String?
    @State private var statusText: String?
    @State private var copied = false
    @State private var showContactPicker = false
    @State private var showCodeFallback = false
    @State private var sharePayload: ShareInviteSheet?
    @State private var inviteNameHint: String?

    var body: some View {
        let gate = appModel.paywallGate(pins: pins)
        let friends = appModel.friendsService
        let week = LeagueRanking.weekInterval()
        let myKeys = LeagueRanking.placeKeys(from: pins, in: week)
        let entries = friends?.leagueEntries(myName: "You", myWeeklyPlaceKeys: myKeys) ?? [
            LeagueEntry(code: friends?.myCode ?? "me", displayName: "You", uniquePlaces: myKeys.count, isMe: true)
        ]
        let myRank = (entries.firstIndex(where: \.isMe) ?? 0) + 1

        NavigationStack {
            List {
                // MARK: Leaderboard — primary competition surface
                Section {
                    if gate.canUseFriendsLeague {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("This week’s places")
                                .font(.title2.weight(.heavy))
                            Text("Ranked by unique places — never most tucks. You vs accepted friends.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Your rank")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("#\(myRank)")
                                        .font(.system(size: 34, weight: .bold, design: .rounded))
                                        .foregroundStyle(LipMapTheme.accent)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Your places")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(myKeys.count)")
                                        .font(.system(size: 34, weight: .bold, design: .rounded))
                                        .foregroundStyle(LipMapTheme.ink)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))

                        ForEach(Array(entries.enumerated()), id: \.element.id) { offset, entry in
                            LeaderboardRow(rank: offset + 1, entry: entry)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Friends leaderboard")
                                .font(.title2.weight(.heavy))
                            Text("Unique places this week among accepted friends. Unlock Full Map to climb.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button("Unlock Full Map") {
                                appModel.showPaywall = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(LipMapTheme.accent)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Leaderboard")
                } footer: {
                    Text("Competition = unique pin locations this week. Lip pillows in new spots beat stacking the same parking lot.")
                }

                // MARK: Invite from Contacts (primary)
                Section {
                    Button {
                        showContactPicker = true
                    } label: {
                        Label("Invite from Contacts", systemImage: "person.crop.circle.badge.plus")
                            .font(.headline)
                    }
                    .disabled(friends?.myCode == nil)

                    if let code = friends?.myCode {
                        ShareLink(
                            item: InviteLink.shareMessage(myCode: code),
                            subject: Text("Lip Map invite"),
                            message: Text("Add me on Lip Map")
                        ) {
                            Label("Share invite link", systemImage: "square.and.arrow.up")
                        }
                    }

                    Button {
                        showCodeFallback.toggle()
                    } label: {
                        Label(
                            showCodeFallback ? "Hide code fallback" : "Use 6-digit code instead",
                            systemImage: "number"
                        )
                        .font(.subheadline)
                    }

                    if showCodeFallback {
                        if let code = friends?.myCode {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Your code")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(code)
                                        .font(.system(.title, design: .monospaced).weight(.bold))
                                        .tracking(4)
                                }
                                Spacer()
                                Button {
                                    #if canImport(UIKit)
                                    UIPasteboard.general.string = code
                                    #endif
                                    copied = true
                                } label: {
                                    Label(copied ? "Copied" : "Copy", systemImage: "doc.on.doc")
                                }
                                .buttonStyle(.bordered)
                            }

                            HStack {
                                TextField("Their 6-digit code", text: $pasteCode)
                                    .keyboardType(.numberPad)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                Button("Request") {
                                    sendRequest()
                                }
                                .disabled(pasteCode.filter(\.isNumber).count != 6)
                            }
                        }
                    }

                    if let errorText {
                        Text(errorText)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    if let statusText {
                        Text(statusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Add friends")
                } footer: {
                    Text("Pick a contact and send a Lip Map link — they don’t type a code. Code entry is fallback only. No search, no discover.")
                }

                if let incoming = friends?.incomingPending, !incoming.isEmpty {
                    Section {
                        ForEach(incoming, id: \.id) { request in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(request.displayName)
                                    Text(request.peerCode)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Accept") {
                                    try? friends?.acceptRequest(request)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(LipMapTheme.accent)
                                Button("Decline") {
                                    try? friends?.declineRequest(request)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    } header: {
                        Text("Added you")
                    } footer: {
                        Text("Accept to let them follow you and climb the places league with you.")
                    }
                }

                if let outgoing = friends?.outgoingPending, !outgoing.isEmpty {
                    Section {
                        ForEach(outgoing, id: \.id) { request in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(request.displayName)
                                    Text(request.peerCode)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("Waiting…")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { indexSet in
                            guard let friends else { return }
                            for index in indexSet {
                                try? friends.cancelOutgoingRequest(friends.outgoingPending[index])
                            }
                        }
                    } header: {
                        Text("Pending")
                    } footer: {
                        Text("They haven’t accepted yet. Swipe to cancel.")
                    }
                }

                Section {
                    if let list = friends?.friends, !list.isEmpty {
                        ForEach(list, id: \.id) { friend in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(friend.displayName)
                                    Text(friend.code)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(friend.uniquePlaceCount) places")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(LipMapTheme.accent)
                            }
                        }
                        .onDelete { indexSet in
                            guard let friends else { return }
                            for index in indexSet {
                                try? friends.removeFriend(friends.friends[index])
                            }
                        }
                    } else {
                        Text("Not following anyone yet. Invite from Contacts — they accept, then the leaderboard gets real.")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Following")
                } footer: {
                    Text("Swipe to unfollow. Leaderboard only counts accepted follows.")
                }
            }
            .navigationTitle("Friends")
            .refreshable {
                let keys = LeagueRanking.placeKeys(from: pins, in: week)
                await friends?.publishWeeklyPlaces(keys)
                await friends?.refreshFriendsLeague()
            }
            .onAppear {
                friends?.refreshRequests()
                Task {
                    await friends?.publishWeeklyPlaces(myKeys)
                }
                applyPendingInviteIfNeeded()
            }
            .onChange(of: appModel.pendingInviteCode) { _, _ in
                applyPendingInviteIfNeeded()
            }
            #if canImport(ContactsUI) && canImport(UIKit)
            .fullScreenCover(isPresented: $showContactPicker) {
                ContactInvitePicker(
                    onPick: { selection in
                        showContactPicker = false
                        inviteFromContact(selection)
                    },
                    onCancel: { showContactPicker = false }
                )
                .ignoresSafeArea()
            }
            #endif
            #if canImport(UIKit)
            .sheet(item: $sharePayload) { payload in
                ActivityShareView(items: payload.items)
            }
            #endif
        }
    }

    private func sendRequest() {
        errorText = nil
        statusText = nil
        do {
            _ = try appModel.friendsService?.sendFollowRequest(code: pasteCode)
            pasteCode = ""
            statusText = "Request sent — waiting for them to accept."
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func inviteFromContact(_ selection: ContactInviteSelection) {
        guard let code = appModel.friendsService?.myCode else { return }
        inviteNameHint = selection.name
        let message = InviteLink.shareMessage(myCode: code)
        #if canImport(UIKit)
        sharePayload = ShareInviteSheet(items: [message])
        #endif
        statusText = "Invite ready for \(selection.name). Send it — when they open the link, they request to follow you."
    }

    private func applyPendingInviteIfNeeded() {
        guard appModel.pendingInviteCode != nil else { return }
        errorText = nil
        do {
            if let request = try appModel.consumePendingInvite(displayName: inviteNameHint) {
                statusText = "Follow request sent to \(request.peerCode). Waiting for accept."
            }
        } catch {
            errorText = error.localizedDescription
            appModel.pendingInviteCode = nil
        }
    }
}

private struct LeaderboardRow: View {
    let rank: Int
    let entry: LeagueEntry

    var body: some View {
        HStack(spacing: 14) {
            Text("\(rank)")
                .font(.title2.monospacedDigit().weight(.bold))
                .foregroundStyle(rank <= 3 ? LipMapTheme.accent : LipMapTheme.ink)
                .frame(width: 36, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.isMe ? "You" : entry.displayName)
                    .font(.headline)
                Text("unique places this week")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(entry.uniquePlaces)")
                .font(.title.weight(.bold))
                .foregroundStyle(LipMapTheme.accent)
                .monospacedDigit()
        }
        .padding(.vertical, 6)
        .listRowBackground(
            entry.isMe
                ? LipMapTheme.accent.opacity(0.10)
                : Color.clear
        )
    }
}
