import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var busy = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Full Map")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(LipMapTheme.ink)

                    Text("All-time pins. Badges. Friends. Weekly location league.")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 12) {
                        productButton(
                            title: "$9.99/year",
                            subtitle: "19¢ a week · 3-day free trial",
                            price: appModel.entitlements.yearlyProduct?.displayPrice ?? "$9.99",
                            highlighted: true
                        ) {
                            await purchaseYearly()
                        }

                        productButton(
                            title: "$0.99/week",
                            subtitle: "Cancel anytime",
                            price: appModel.entitlements.weeklyProduct?.displayPrice ?? "$0.99",
                            highlighted: false
                        ) {
                            await purchaseWeekly()
                        }
                    }

                    Button("Restore Purchases") {
                        Task {
                            busy = true
                            await appModel.entitlements.restore()
                            busy = false
                            if appModel.entitlements.isSubscribed { dismiss() }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    if let errorText {
                        Text(errorText)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Text("18+. Entertainment only. Location used only when you tap Tucked.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(24)
            }
            .background(
                LinearGradient(
                    colors: [LipMapTheme.mist, Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .disabled(busy)
            .task {
                await appModel.entitlements.refresh()
            }
        }
    }

    @ViewBuilder
    private func productButton(
        title: String,
        subtitle: String,
        price: String,
        highlighted: Bool,
        action: @escaping () async -> Void
    ) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(highlighted ? .white.opacity(0.85) : .secondary)
                }
                Spacer()
                Text(price)
                    .font(.title3.weight(.bold))
            }
            .padding(18)
            .foregroundStyle(highlighted ? .white : LipMapTheme.ink)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(highlighted ? LipMapTheme.accent : Color.black.opacity(0.06))
            )
            .overlay {
                if highlighted {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func purchaseYearly() async {
        busy = true
        defer { busy = false }
        errorText = nil
        if let product = appModel.entitlements.yearlyProduct {
            do {
                try await appModel.entitlements.purchase(product)
                if appModel.entitlements.isSubscribed { dismiss() }
            } catch {
                errorText = error.localizedDescription
            }
        } else {
            errorText = "Yearly product unavailable. Check StoreKit config (lipmap_yearly)."
        }
    }

    private func purchaseWeekly() async {
        busy = true
        defer { busy = false }
        errorText = nil
        if let product = appModel.entitlements.weeklyProduct {
            do {
                try await appModel.entitlements.purchase(product)
                if appModel.entitlements.isSubscribed { dismiss() }
            } catch {
                errorText = error.localizedDescription
            }
        } else {
            errorText = "Weekly product unavailable. Check StoreKit config (lipmap_weekly)."
        }
    }
}
