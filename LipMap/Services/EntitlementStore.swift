import Foundation
import StoreKit
import Observation

@MainActor
protocol EntitlementServing: AnyObject {
    var isSubscribed: Bool { get }
    var yearlyProduct: Product? { get }
    var weeklyProduct: Product? { get }
    func refresh() async
    func purchase(_ product: Product) async throws
    func restore() async
}

/// StoreKit 2 — lipmap_yearly + lipmap_weekly.
@Observable
@MainActor
final class EntitlementStore: EntitlementServing {
    static let yearlyProductID = "lipmap_yearly"
    static let weeklyProductID = "lipmap_weekly"
    static let allProductIDs: Set<String> = [yearlyProductID, weeklyProductID]

    private(set) var isSubscribed = false
    private(set) var yearlyProduct: Product?
    private(set) var weeklyProduct: Product?
    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await _ in Transaction.updates {
                await self?.refresh()
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func refresh() async {
        await loadProducts()
        isSubscribed = await hasActiveEntitlement()
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try Self.checkVerified(verification)
            await transaction.finish()
            await refresh()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refresh()
    }

    private func loadProducts() async {
        do {
            let products = try await Product.products(for: Self.allProductIDs)
            yearlyProduct = products.first { $0.id == Self.yearlyProductID }
            weeklyProduct = products.first { $0.id == Self.weeklyProductID }
        } catch {
            // StoreKit unavailable offline / Linux stub environments.
        }
    }

    private func hasActiveEntitlement() async -> Bool {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? Self.checkVerified(result) else { continue }
            if Self.allProductIDs.contains(transaction.productID) {
                return true
            }
        }
        return false
    }

    static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}

@Observable
@MainActor
final class StubEntitlementStore: EntitlementServing {
    var isSubscribed: Bool
    var yearlyProduct: Product? = nil
    var weeklyProduct: Product? = nil

    init(isSubscribed: Bool = false) {
        self.isSubscribed = isSubscribed
    }

    func refresh() async {}
    func purchase(_ product: Product) async throws { isSubscribed = true }
    func restore() async {}
}
