import Foundation

/// Prevents roast repetition and spam.
/// Rules:
/// 1. Same template: no repeat within 24h
/// 2. Same trigger type: minimum 5 min cooldown
/// 3. Daily cap: 5 (free) / 20 (pro) roasts
/// 4. Weight decay after use, reset daily
final class RoastCooldownTracker: Sendable {
    private let usedTemplates: LockedValue<[String: Date]> = LockedValue([:])
    private let triggerCooldowns: LockedValue<[TriggerType: Date]> = LockedValue([:])
    private let dailyCount: LockedValue<(count: Int, date: Date)> = LockedValue((0, Date()))
    private let weightDecay: LockedValue<[String: Double]> = LockedValue([:])

    func canRoast(templateId: String, triggerType: TriggerType, isFullVersion: Bool) -> Bool {
        let now = Date()
        cleanupIfNewDay(now: now)

        // Check daily cap
        let cap = isFullVersion ? Constants.Roast.fullRoastsPerDay : Constants.Roast.freeRoastsPerDay
        if dailyCount.value.count >= cap { return false }

        // Check trigger cooldown (5 min)
        if let lastTrigger = triggerCooldowns.value[triggerType] {
            if now.timeIntervalSince(lastTrigger) < Constants.Roast.cooldownSeconds {
                return false
            }
        }

        // Check template repeat (24h)
        if let lastUsed = usedTemplates.value[templateId] {
            let hours = now.timeIntervalSince(lastUsed) / 3600
            if hours < Double(Constants.Roast.templateRepeatCooldownHours) {
                return false
            }
        }

        return true
    }

    func recordRoast(templateId: String, triggerType: TriggerType) {
        let now = Date()
        usedTemplates.mutate { $0[templateId] = now }
        triggerCooldowns.mutate { $0[triggerType] = now }
        dailyCount.mutate { $0 = ($0.count + 1, $0.date) }
        weightDecay.mutate { $0[templateId, default: 1.0] *= 0.5 }
    }

    func decayedWeight(for templateId: String) -> Double {
        weightDecay.value[templateId] ?? 1.0
    }

    var todayRoastCount: Int {
        dailyCount.value.count
    }

    private func cleanupIfNewDay(now: Date) {
        if !Calendar.current.isDateInToday(dailyCount.value.date) {
            dailyCount.mutate { $0 = (0, now) }
            usedTemplates.mutate { $0.removeAll() }
            weightDecay.mutate { $0.removeAll() }
        }
    }
}

// MARK: - Thread-safe wrapper

final class LockedValue<T>: @unchecked Sendable {
    private var _value: T
    private let lock = NSLock()

    init(_ value: T) {
        self._value = value
    }

    var value: T {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    func mutate(_ transform: (inout T) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        transform(&_value)
    }
}
