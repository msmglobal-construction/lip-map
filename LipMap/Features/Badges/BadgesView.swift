import SwiftUI
import SwiftData

struct BadgesView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TuckPin.timestamp, order: .reverse) private var pins: [TuckPin]
    @State private var manualPinID: UUID?

    var body: some View {
        let unlocked = BadgeEvaluator.unlocked(pins: pins)
        let subscribed = appModel.entitlements.isSubscribed
        let manualPin = pins.first { $0.id == manualPinID }

        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 14)], spacing: 14) {
                    ForEach(LipBadge.allCases) { badge in
                        let isUnlocked = unlocked.contains(badge)
                        BadgeCell(
                            badge: badge,
                            isUnlocked: isUnlocked,
                            showLockedArt: !subscribed || !isUnlocked
                        )
                        .onLongPressGesture {
                            if badge.isManual, let latest = pins.first {
                                manualPinID = latest.id
                            }
                        }
                    }
                }
                .padding()

                Text("Long-press a manual badge to tag your latest pin.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 24)
            }
            .background(
                LinearGradient(
                    colors: [LipMapTheme.mist, Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Badges")
            .sheet(isPresented: Binding(
                get: { manualPinID != nil },
                set: { if !$0 { manualPinID = nil } }
            )) {
                if let manualPin {
                    ManualBadgeSheet(pin: manualPin)
                }
            }
        }
    }
}

private struct BadgeCell: View {
    let badge: LipBadge
    let isUnlocked: Bool
    /// Free tier: badges visible but locked art even if earned.
    let showLockedArt: Bool

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isUnlocked && !showLockedArt ? LipMapTheme.accent.opacity(0.18) : Color.black.opacity(0.06))
                    .frame(height: 88)
                Image(systemName: badge.systemImage)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(isUnlocked && !showLockedArt ? LipMapTheme.accent : .secondary)
                    .opacity(showLockedArt ? 0.35 : 1)
                if showLockedArt {
                    Image(systemName: "lock.fill")
                        .font(.caption.weight(.bold))
                        .padding(6)
                        .background(.ultraThinMaterial, in: Circle())
                        .offset(x: 36, y: -28)
                }
            }
            Text(badge.title)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(LipMapTheme.ink)
            Text(badge.blurb)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct ManualBadgeSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let pin: TuckPin

    private let manuals = LipBadge.allCases.filter(\.isManual)

    var body: some View {
        NavigationStack {
            List {
                Section("Tag latest pin") {
                    ForEach(manuals) { badge in
                        Button {
                            var ids = pin.manualBadgeIDs
                            if !ids.contains(badge.rawValue) {
                                ids.append(badge.rawValue)
                                pin.manualBadgeIDs = ids
                                try? modelContext.save()
                            }
                            dismiss()
                        } label: {
                            Label(badge.title, systemImage: badge.systemImage)
                        }
                    }
                }
            }
            .navigationTitle("Manual badges")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
