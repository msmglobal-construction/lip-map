import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TuckPin.timestamp, order: .reverse) private var pins: [TuckPin]

    var body: some View {
        let today = appModel.todayCount(pins: pins)
        let last = appModel.lastTuck(pins: pins)
        let pending = pins.first { $0.id == appModel.pendingFlavorPinID }

        ZStack {
            background

            VStack(spacing: 28) {
                Spacer(minLength: 24)

                Text("Lip Map")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(LipMapTheme.ink)
                    .accessibilityAddTraits(.isHeader)

                Text("\(today)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(LipMapTheme.accent)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: today)

                Text(today == 1 ? "tuck today" : "tucks today")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                if let last {
                    Text("Last tuck \(last.timestamp.formatted(date: .omitted, time: .shortened))")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Button {
                    Task { await appModel.tuck(modelContext: modelContext, existingPins: pins) }
                } label: {
                    Text(appModel.isTucking ? "Pinning…" : "Tucked")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(LipMapTheme.pin)
                                .shadow(color: LipMapTheme.pin.opacity(0.35), radius: 18, y: 10)
                        )
                }
                .buttonStyle(.plain)
                .disabled(appModel.isTucking)
                .padding(.horizontal, 28)
                .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.8), trigger: today)

                if !appModel.didShowLocationSentence {
                    Text("Lip Map drops a pin when you tap Tucked.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                if let error = appModel.tuckError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer(minLength: 40)
            }
        }
        .sheet(item: Binding(
            get: { pending.map { FlavorSheetPin(pin: $0) } },
            set: { if $0 == nil { appModel.pendingFlavorPinID = nil } }
        )) { wrapper in
            FlavorPickerSheet(pin: wrapper.pin)
                .environment(appModel)
                .presentationDetents([.height(260)])
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                LipMapTheme.mist,
                Color(red: 0.86, green: 0.92, blue: 0.90),
                Color(red: 0.95, green: 0.93, blue: 0.88)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

private struct FlavorSheetPin: Identifiable {
    var id: UUID { pin.id }
    let pin: TuckPin
}

private struct FlavorPickerSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let pin: TuckPin

    var body: some View {
        VStack(spacing: 16) {
            Text("Flavor? (optional)")
                .font(.headline)
            HStack(spacing: 10) {
                ForEach(TuckFlavor.allCases) { flavor in
                    Button(flavor.rawValue) {
                        appModel.applyFlavor(flavor, to: pin, modelContext: modelContext)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(LipMapTheme.accent)
                }
            }
            Button("Skip") {
                appModel.pendingFlavorPinID = nil
                dismiss()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding()
    }
}
