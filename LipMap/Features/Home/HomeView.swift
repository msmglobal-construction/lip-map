import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TuckPin.timestamp, order: .reverse) private var pins: [TuckPin]

    @State private var showDashboard = false
    @State private var showStates = false
    @State private var showHistory = false

    var body: some View {
        let today = appModel.todayCount(pins: pins)
        let lifetime = BadgeEvaluator.lifetimeTuckCount(pins: pins)
        let last = appModel.lastTuck(pins: pins)
        let pending = pins.first { $0.id == appModel.pendingFlavorPinID }
        let statesCount = StateAtlas.visited(from: pins).count

        ZStack {
            background

            ScrollView {
                VStack(spacing: 22) {
                    Text("Lip Map")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundStyle(LipMapTheme.ink)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, 12)

                    Text("Drop a pin when the lip pillow goes in.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)

                    Text("\(today)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(LipMapTheme.accent)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: today)

                    Text(today == 1 ? "lip pillow today" : "lip pillows today")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text("\(lifetime) lifetime · \(statesCount) states")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(LipMapTheme.ink.opacity(0.7))
                        .contentTransition(.numericText())
                        .animation(.snappy, value: lifetime)

                    if let last {
                        Text("Last tuck \(last.timestamp.formatted(date: .omitted, time: .shortened))")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    }

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

                    HStack(spacing: 10) {
                        homeChip("Your map stats", systemImage: "chart.bar.fill") { showDashboard = true }
                        homeChip("States", systemImage: "map.fill") { showStates = true }
                        homeChip("History", systemImage: "list.bullet") { showHistory = true }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
            }
        }
        .sheet(item: Binding(
            get: { pending.map { FlavorSheetPin(pin: $0) } },
            set: { if $0 == nil { appModel.pendingFlavorPinID = nil } }
        )) { wrapper in
            FlavorPickerSheet(pin: wrapper.pin)
                .environment(appModel)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showDashboard) {
            DashboardSheet(pins: pins)
        }
        .sheet(isPresented: $showStates) {
            StatesSheet(pins: pins)
        }
        .sheet(isPresented: $showHistory) {
            TuckHistorySheet(pins: pins)
                .environment(appModel)
        }
    }

    private func homeChip(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(LipMapTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
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

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("What flavor hit the lip pillow?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(TuckFlavor.allCases) { flavor in
                            Button(flavor.rawValue) {
                                appModel.applyFlavor(flavor, to: pin, modelContext: modelContext)
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(LipMapTheme.accent)
                            .font(.caption.weight(.semibold))
                        }
                    }
                }

                Button("Skip — keep pinning") {
                    appModel.pendingFlavorPinID = nil
                    dismiss()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Flavor (optional)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        appModel.pendingFlavorPinID = nil
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DashboardSheet: View {
    let pins: [TuckPin]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let insights = DashboardInsights.build(pins: pins)
        NavigationStack {
            List {
                Section {
                    statRow("Lifetime lip pillows", "\(insights.lifetimeTucks)")
                    statRow("This week", "\(insights.weekTucks)")
                    statRow("Unique places this week", "\(insights.uniquePlacesWeek)")
                    statRow("States visited", "\(insights.statesVisited)")
                    statRow("Flavors tried", "\(insights.flavorsTried)")
                } header: {
                    Text("The rundown")
                } footer: {
                    Text("Joke-map stats only — where and when the pillows land. Not a quit tracker.")
                }

                Section("When you tuck most") {
                    if let peak = insights.peakTimeLabel {
                        Text("Peak window: \(peak)")
                            .font(.subheadline.weight(.semibold))
                    }
                    ForEach(insights.timeOfDay) { bucket in
                        barRow(label: bucket.label, count: bucket.count, max: insights.timeOfDay.map(\.count).max() ?? 1)
                    }
                }

                Section("Day of week") {
                    if let peak = insights.peakDayLabel {
                        Text("Biggest day: \(peak)")
                            .font(.subheadline.weight(.semibold))
                    }
                    ForEach(insights.dayOfWeek) { bucket in
                        barRow(label: bucket.label, count: bucket.count, max: insights.dayOfWeek.map(\.count).max() ?? 1)
                    }
                }

                Section("Where the pillows land") {
                    if insights.topPlaces.isEmpty {
                        Text("Keep tucking — cities show up after reverse geocode.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(insights.topPlaces) { item in
                            HStack {
                                Text(item.name)
                                Spacer()
                                Text("\(item.count)")
                                    .foregroundStyle(LipMapTheme.accent)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }

                Section("State heat") {
                    if insights.topStates.isEmpty {
                        Text("No states logged yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(insights.topStates) { item in
                            HStack {
                                Text(item.name)
                                Spacer()
                                Text("\(item.count)")
                                    .foregroundStyle(LipMapTheme.accent)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }

                Section("Flavor breakdown") {
                    if insights.flavorBreakdown.isEmpty {
                        Text("Skip flavor forever if you want — optional.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(insights.flavorBreakdown) { item in
                            HStack {
                                Text(item.name)
                                Spacer()
                                Text("\(item.count)")
                                    .foregroundStyle(LipMapTheme.accent)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Your map stats")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func statRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(LipMapTheme.accent)
        }
    }

    private func barRow(label: String, count: Int, max: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                Spacer()
                Text("\(count)")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                let width = max <= 0 ? 0 : geo.size.width * CGFloat(count) / CGFloat(max)
                Capsule()
                    .fill(LipMapTheme.accent.opacity(0.85))
                    .frame(width: max(width, count > 0 ? 6 : 0), height: 8)
            }
            .frame(height: 8)
        }
        .padding(.vertical, 2)
    }
}

struct StatesSheet: View {
    let pins: [TuckPin]
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 70), spacing: 10)]

    var body: some View {
        let visited = StateAtlas.visitedCodes(from: pins)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(visited.count) / \(USState.all.count) states lip pillow’d")
                        .font(.headline)
                    Text("Your personal Zynbabwe tour — collect states, not pouch volume.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(USState.all) { state in
                            let on = visited.contains(state.code)
                            VStack(spacing: 4) {
                                Text(state.code)
                                    .font(.headline.monospaced())
                                Text(state.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .foregroundStyle(on ? .white : LipMapTheme.ink.opacity(0.55))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(on ? LipMapTheme.accent : Color.black.opacity(0.06))
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("States")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct TuckHistorySheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let pins: [TuckPin]

    var body: some View {
        NavigationStack {
            List {
                if pins.isEmpty {
                    Text("No tucks yet. Tap Tucked on Home.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(pins, id: \.id) { pin in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pin.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.headline)
                            Text(pin.placeLabel)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(pin.flavor?.rawValue ?? "No flavor")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task {
                                    await appModel.deletePin(pin, modelContext: modelContext, remainingPins: pins)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tuck history")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
