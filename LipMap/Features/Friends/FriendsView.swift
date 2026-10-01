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

    var body: some View {
        let gate = appModel.paywallGate(pins: pins)
        let friends = appModel.friendsService
        let week = LeagueRanking.weekInterval()
        let myKeys = LeagueRanking.placeKeys(from: pins, in: week)

        NavigationStack {
            List {
                Section {
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
                    }
                } footer: {
                    Text("Share your 6-digit code. When someone types it, they send a follow request — you accept before they follow you or see your pins.")
                }

                Section("Send request") {
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
                } footer: {
                    Text("Typing their code sends a follow request. No search, no discover, no directory.")
                }

                if let incoming = friends?.incomingPending, !incoming.isEmpty {
                    Section("Added you") {
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
                    } footer: {
                        Text("Accept to let them follow you and see your pins. Decline or ignore leaves them out.")
                    }
                }

                if let outgoing = friends?.outgoingPending, !outgoing.isEmpty {
                    Section("Pending") {
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
                    } footer: {
                        Text("They haven’t accepted yet. Swipe to cancel.")
                    }
                }

                Section("Following") {
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
                        Text("Not following anyone yet. Send a request above — they have to accept.")
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Swipe to unfollow. League ranks unique places this week among accepted follows — not pouch count.")
                }

                Section {
                    if gate.canUseFriendsLeague {
                        let entries = friends?.leagueEntries(myName: "You", myWeeklyPlaceKeys: myKeys) ?? []
                        if entries.isEmpty {
                            Text("League populates as friends sync.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(Array(entries.enumerated()), id: \.element.id) { offset, entry in
                                HStack {
                                    Text("\(offset + 1)")
                                        .font(.headline.monospacedDigit())
                                        .frame(width: 28)
                                    VStack(alignment: .leading) {
                                        Text(entry.isMe ? "\(entry.displayName) (you)" : entry.displayName)
                                        Text("Unique places this week")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("\(entry.uniquePlaces)")
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(LipMapTheme.accent)
                                }
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weekly location league")
                                .font(.headline)
                            Text("Ranked by unique places — not total tucks. Unlock Full Map to play.")
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
                    Text("Weekly league")
                } footer: {
                    Text("Unique pin locations this week win. Never most tucks. Accepted follows only.")
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
            }
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
}
