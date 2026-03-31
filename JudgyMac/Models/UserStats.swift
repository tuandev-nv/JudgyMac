import Foundation

struct UserStats: Sendable {
    var lidOpenCount: Int = 0
    var keystrokeCount: Int = 0
    var roastCount: Int = 0
    var maxIdleMinutes: Int = 0
    var slapCount: Int = 0
    var appSwitchCount: Int = 0
    var thermalCount: Int = 0
    var screenTimeMinutes: Int = 0
    var triggerCounts: [TriggerType: Int] = [:]
    var date: Date = Calendar.current.startOfDay(for: Date())

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    mutating func recordEvent(_ event: BehaviorEvent) {
        resetIfNewDay()

        triggerCounts[event.type, default: 0] += 1

        switch event.type {
        case .lidOpen, .lidReopen:
            lidOpenCount += 1
        case .idle:
            if let minutes = Int(event.metadata["idle_minutes"] ?? "") {
                maxIdleMinutes = max(maxIdleMinutes, minutes)
            }
        case .slap:
            slapCount += 1
        case .appSwitch:
            appSwitchCount += 1
        case .screenTime:
            if let minutes = Int(event.metadata["minutes"] ?? "") {
                screenTimeMinutes = max(screenTimeMinutes, minutes)
            }
        case .thermal:
            thermalCount += 1
        default:
            break
        }
    }

    /// Generates a "vibe" label based on today's stats
    var todayVibe: String {
        if roastCount == 0 { return "Unjudged... for now" }
        if lidOpenCount > 10 { return "Serial Lid Opener" }
        if maxIdleMinutes > 30 { return "Professional Procrastinator" }
        if keystrokeCount > 3000 { return "Keyboard Warrior" }
        if roastCount > 10 { return "Fully Roasted" }
        return "Mildly Judged"
    }

    /// Judgment bar progress (0.0 - 1.0)
    var judgmentLevel: Double {
        let score = Double(roastCount) / 20.0
        return min(score, 1.0)
    }

    private mutating func resetIfNewDay() {
        guard !isToday else { return }
        self = UserStats()
    }
}
