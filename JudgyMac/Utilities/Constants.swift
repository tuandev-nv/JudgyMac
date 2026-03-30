import Foundation

enum Constants {
    static let appName = "JudgyMac"
    static let websiteURL = URL(string: "https://judgymac.com")!
    static let bundleIdentifier = "com.judgymac.app"

    enum Roast {
        static let freeRoastsPerDay = 3
        static let fullRoastsPerDay = 50
        static let cooldownSeconds: TimeInterval = 5 // TODO: change to 300 before release
        static let templateRepeatCooldownHours = 24
        static let maxHistoryEntries = 100
    }

    enum Detection {
        static let idlePollIntervalSeconds: TimeInterval = 60
        static let idleThresholdMinutes = 15
        static let aggressiveTypingWPMThreshold = 100
        static let deleteRatioThreshold = 0.4
        static let lidReopenThresholdSeconds = 30
        static let lateNightStartHour = 0
        static let lateNightEndHour = 5
        static let earlyMorningStartHour = 5
        static let earlyMorningEndHour = 6
    }
}
