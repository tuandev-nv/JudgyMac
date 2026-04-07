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

    var selectedCharacterPack: String = "trump"
    var enabledTriggers: Set<TriggerType> = Set(TriggerType.allCases)
    var toastEnabled: Bool = true
    var voiceEnabled: Bool = true
    var lidCreakEnabled: Bool = true
    var slapSensitivity: Double = 0.05  // g-force threshold
    var slapCooldown: Double = 0.3     // seconds between slaps
    var isOnboarded: Bool = false

    // MARK: - System Stats
    var cpuUsage: Double = 0
    var ramUsage: Double = 0
    var gpuUsage: Double = 0
    var diskUsage: Double = 0

    // MARK: - License
    var licenseKey: String = ""
    var isLicenseValid: Bool = false

    // MARK: - Computed

    var currentPack: CharacterPack {
        CharacterPackCatalog.pack(for: selectedCharacterPack) ?? CharacterPackCatalog.defaultPack
    }

    // MARK: - Methods

    func handleEvent(_ event: BehaviorEvent) {
        todayStats.recordEvent(event)
        currentMood = MoodEngine.mood(for: event, stats: todayStats)
        SettingsStore.save(self)
    }

    func deliverRoast(_ entry: RoastEntry) {
        currentRoast = entry
        roastHistory.append(entry)
        if roastHistory.count > 100 {
            roastHistory.removeFirst()
        }
        todayStats.roastCount += 1
    }
}
