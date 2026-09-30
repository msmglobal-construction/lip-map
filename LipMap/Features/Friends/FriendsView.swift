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
                    Text("Share this 6-digit code so friends can find your pins.")
                }

                Section("Add friend") {
                    HStack {
                        TextField("Paste friend code", text: $pasteCode)
                            .keyboardType(.numberPad)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button("Add") {
                            addFriend()
                        }
                        .disabled(pasteCode.filter(\.isNumber).count != 6)
                    }
                    if let errorText {
                        Text(errorText)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Friends") {
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
                        Text("No friends yet. Paste a code above.")
                            .foregroundStyle(.secondary)
                    }
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
                    Text("Unique pin locations this week win. Never most tucks.")
                }
            }
            .navigationTitle("Friends")
            .refreshable {
                let keys = LeagueRanking.placeKeys(from: pins, in: week)
                await friends?.publishWeeklyPlaces(keys)
                await friends?.refreshFriendsLeague()
            }
            .onAppear {
                Task {
                    await friends?.publishWeeklyPlaces(myKeys)
                }
            }
        }
    }

    private func addFriend() {
        errorText = nil
        do {
            _ = try appModel.friendsService?.addFriend(code: pasteCode)
            pasteCode = ""
        } catch {
            errorText = error.localizedDescription
        }
    }
}
