import Foundation

enum Constants {
    static let appName = "JudgyMac"
    static let websiteURL = URL(string: "https://judgymac.xyz")!
    static let bundleIdentifier = "com.judgymac.app"

    enum Roast {
        static let freeRoastsPerDay = 3
        static let fullRoastsPerDay = 50
        static let cooldownSeconds: TimeInterval = 120  // 2 min (was 5 min)
        static let templateRepeatCooldownHours = 24
        static let maxHistoryEntries = 100
    }

    enum Slap {
        static let pressureThreshold: Double = 0.8
        static let windowSize: CGFloat = 1000

        // Base tempo — all slap timing scales from this (seconds)
        // Increase this single value to slow everything down proportionally
        static let baseTempo: TimeInterval = 0.65

        /// Min interval between slaps
        static let debounceSeconds: TimeInterval = 0.3

        /// Idle time before slap window dismisses
        static let dismissIdleSeconds: TimeInterval = baseTempo * 3   // ~2s

        /// Comic text hold time before fading
        static let comicHoldSeconds: TimeInterval = baseTempo * 2

        /// Comic text total lifetime (hold + fade)
        static let comicLifetimeSeconds: TimeInterval = baseTempo * 3

        /// Comic text fade duration
        static let comicFadeSeconds: TimeInterval = baseTempo * 0.8
    }

    enum Detection {
        static let idlePollIntervalSeconds: TimeInterval = 60
        static let idleThresholdMinutes = 10
        static let aggressiveTypingWPMThreshold = 100
        static let deleteRatioThreshold = 0.4
        static let lidReopenThresholdSeconds = 30
        static let lateNightStartHour = 0
        static let lateNightEndHour = 5
        static let earlyMorningStartHour = 5
        static let earlyMorningEndHour = 7
    }
}
