import Foundation

enum MoodEngine {
    static func mood(for event: BehaviorEvent, stats: UserStats) -> Mood {
        switch event.type {
        case .lidOpen:
            let count = stats.lidOpenCount
            if count > 10 { return .horrified }
            if count > 5 { return .judging }
            return .neutral

        case .lidReopen:
            return .judging

        case .lateNight, .earlyMorning:
            return .horrified

        case .thermal:
            return .raging

        case .idle:
            let minutes = Int(event.metadata["idle_minutes"] ?? "0") ?? 0
            if minutes > 30 { return .sleeping }
            return .sleeping
        }
    }

    /// Generates a mood based on overall daily stats (for idle/passive display)
    static func ambientMood(from stats: UserStats) -> Mood {
        if stats.roastCount > 15 { return .raging }
        if stats.roastCount > 8 { return .judging }
        if stats.maxIdleMinutes > 30 { return .sleeping }
        if stats.lidOpenCount > 8 { return .judging }
        return .neutral
    }
}
