import Foundation

/// Simple entitlement check — free tier vs full version ($4.99).
@MainActor
final class EntitlementManager {
    private let store: StoreManager

    init(store: StoreManager) {
        self.store = store
    }

    var isFullVersion: Bool {
        store.isFullVersionPurchased
    }

    /// Free: 3 roasts/day, 1 personality, 3 triggers
    /// Full: unlimited roasts, all personalities, all triggers, daily summary, share
    var maxRoastsPerDay: Int {
        isFullVersion ? 50 : 3
    }

    var canAccessAllPersonalities: Bool {
        isFullVersion
    }

    var canAccessAllTriggers: Bool {
        isFullVersion
    }

    var canShareSummary: Bool {
        isFullVersion
    }

    static let freeTriggers: Set<TriggerType> = [.lidOpen, .idle, .thermal]
}
