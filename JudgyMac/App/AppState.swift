import SwiftUI

@Observable
final class AppState {
    // MARK: - Mood & Roast

    var currentMood: Mood = .neutral
    var currentRoast: RoastEntry?
    var roastHistory: [RoastEntry] = []

    // MARK: - Stats

    var todayStats: UserStats = UserStats()

    // MARK: - Settings

    var selectedPersonality: String = "the-critic"
    var intensity: Int = 2 // 1-3
    var enabledTriggers: Set<TriggerType> = Set(TriggerType.allCases)
    var isOnboarded: Bool = false

    // MARK: - Purchase
    // App is paid upfront ($4.99 on App Store) — all features always unlocked
    var isFullVersion: Bool = true

    // MARK: - Methods

    func handleEvent(_ event: BehaviorEvent) {
        todayStats.recordEvent(event)
        currentMood = MoodEngine.mood(for: event, stats: todayStats)
    }

    func deliverRoast(_ entry: RoastEntry) {
        currentRoast = entry
        roastHistory.insert(entry, at: 0)
        if roastHistory.count > 100 {
            roastHistory = Array(roastHistory.prefix(100))
        }
        todayStats.roastCount += 1
    }
}
