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
    /// Holds the StoreKit updates task so `deinit` can cancel without touching main-actor state.
    private let updatesBox = TransactionUpdatesBox()

    init() {
        updatesBox.start { [weak self] in
            await self?.refresh()
        }
    }

    deinit {
        updatesBox.cancel()
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

/// Thread-safe holder so `@MainActor` types can cancel a StoreKit listener from `deinit`.
private final class TransactionUpdatesBox: @unchecked Sendable {
    private let lock = NSLock()
    private var task: Task<Void, Never>?

    func start(onUpdate: @escaping @Sendable () async -> Void) {
        let task = Task {
            for await _ in Transaction.updates {
                await onUpdate()
            }
        }
        lock.lock()
        self.task = task
        lock.unlock()
    }

    func cancel() {
        lock.lock()
        task?.cancel()
        task = nil
        lock.unlock()
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
