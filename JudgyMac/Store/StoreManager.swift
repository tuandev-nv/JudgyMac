import StoreKit
import SwiftUI

/// Simplified StoreKit 2 — single $4.99 one-time purchase.
@MainActor
@Observable
final class StoreManager {
    private(set) var fullVersionProduct: Product?
    private(set) var isFullVersionPurchased = false
    private(set) var isLoading = false

    private var updateListenerTask: Task<Void, Never>?

    init() {
        updateListenerTask = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await self?.updatePurchaseStatus()
                    await transaction.finish()
                }
            }
        }
        Task { await loadProduct() }
        Task { await updatePurchaseStatus() }
    }

    // MARK: - Load Product

    func loadProduct() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: ProductIdentifiers.all)
            fullVersionProduct = products.first
        } catch {
            fullVersionProduct = nil
        }
    }

    // MARK: - Purchase

    func purchaseFullVersion() async throws -> Bool {
        guard let product = fullVersionProduct else { return false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { return false }
            await updatePurchaseStatus()
            await transaction.finish()
            return true

        case .userCancelled, .pending:
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Status

    func updatePurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == ProductIdentifiers.fullVersion {
                isFullVersionPurchased = true
                return
            }
        }
        isFullVersionPurchased = false
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchaseStatus()
    }
}
