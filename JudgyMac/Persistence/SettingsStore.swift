import Foundation

/// Persists all user preferences to UserDefaults.
enum SettingsStore {
    private nonisolated(unsafe) static let defaults = UserDefaults.standard

    enum Keys {
        static let selectedCharacterPack = "com.judgymac.characterPack"
        static let enabledTriggers = "com.judgymac.enabledTriggers"
        static let isOnboarded = "com.judgymac.onboarded"
        static let toastEnabled = "com.judgymac.toastEnabled"
        static let voiceEnabled = "com.judgymac.voiceEnabled"
        static let isFullVersion = "com.judgymac.fullVersion"

        // Stats
        static let statsDate = "com.judgymac.stats.date"
        static let statsLidOpens = "com.judgymac.stats.lidOpens"
        static let statsKeystrokes = "com.judgymac.stats.keystrokes"
        static let statsRoastCount = "com.judgymac.stats.roastCount"
        static let statsMaxIdle = "com.judgymac.stats.maxIdle"

        static let statsTriggerCounts = "com.judgymac.stats.triggerCounts"

        // History
        static let roastHistory = "com.judgymac.roastHistory"

        // Legacy keys (for migration)
        static let legacyPersonality = "com.judgymac.personality"
        static let legacySlapCharacter = "com.judgymac.slapCharacter"
        static let legacyIntensity = "com.judgymac.intensity"
    }

    // MARK: - Save AppState

    static func save(_ state: AppState) {
        defaults.set(state.selectedCharacterPack, forKey: Keys.selectedCharacterPack)
        defaults.set(state.isOnboarded, forKey: Keys.isOnboarded)
        defaults.set(state.toastEnabled, forKey: Keys.toastEnabled)
        defaults.set(state.voiceEnabled, forKey: Keys.voiceEnabled)
        defaults.set(state.isFullVersion, forKey: Keys.isFullVersion)

        let triggers = state.enabledTriggers.map(\.rawValue)
        defaults.set(triggers, forKey: Keys.enabledTriggers)

        // Stats
        defaults.set(Date().timeIntervalSince1970, forKey: Keys.statsDate)
        defaults.set(state.todayStats.lidOpenCount, forKey: Keys.statsLidOpens)
        defaults.set(state.todayStats.keystrokeCount, forKey: Keys.statsKeystrokes)
        defaults.set(state.todayStats.roastCount, forKey: Keys.statsRoastCount)
        defaults.set(state.todayStats.maxIdleMinutes, forKey: Keys.statsMaxIdle)
        defaults.set(state.todayStats.slapCount, forKey: "com.judgymac.stats.slapCount")
        defaults.set(state.todayStats.appSwitchCount, forKey: "com.judgymac.stats.appSwitchCount")
        defaults.set(state.todayStats.thermalCount, forKey: "com.judgymac.stats.thermalCount")
        defaults.set(state.todayStats.screenTimeMinutes, forKey: "com.judgymac.stats.screenTime")
        let triggerCountsDict = Dictionary(uniqueKeysWithValues:
            state.todayStats.triggerCounts.map { ($0.key.rawValue, $0.value) }
        )
        defaults.set(triggerCountsDict, forKey: Keys.statsTriggerCounts)

        // History — keep all
        let historyData = state.roastHistory.map { entry in
            [
                "text": entry.text,
                "personality": entry.personality,
                "trigger": entry.triggerType.rawValue,
                "mood": entry.mood.rawValue,
                "timestamp": entry.timestamp.timeIntervalSince1970,
            ] as [String: Any]
        }
        defaults.set(historyData, forKey: Keys.roastHistory)
    }

    // MARK: - Load into AppState

    static func load(into state: AppState) {
        // Migration: clear legacy keys
        migrateLegacyKeys()

        if let pack = defaults.string(forKey: Keys.selectedCharacterPack),
           CharacterPackCatalog.pack(for: pack) != nil {
            state.selectedCharacterPack = pack
        }

        state.isOnboarded = defaults.bool(forKey: Keys.isOnboarded)
        if defaults.object(forKey: Keys.toastEnabled) != nil {
            state.toastEnabled = defaults.bool(forKey: Keys.toastEnabled)
        }
        if defaults.object(forKey: Keys.voiceEnabled) != nil {
            state.voiceEnabled = defaults.bool(forKey: Keys.voiceEnabled)
        }

        // isFullVersion defaults to true — only override if explicitly saved as false
        if defaults.object(forKey: Keys.isFullVersion) != nil {
            state.isFullVersion = defaults.bool(forKey: Keys.isFullVersion)
        }

        if let triggers = defaults.stringArray(forKey: Keys.enabledTriggers) {
            var loaded = Set(triggers.compactMap { TriggerType(rawValue: $0) })
            // Auto-enable new trigger types that didn't exist when settings were saved
            let allKnown = Set(TriggerType.allCases)
            let savedRawValues = Set(triggers)
            for trigger in allKnown where !savedRawValues.contains(trigger.rawValue) {
                loaded.insert(trigger)
            }
            state.enabledTriggers = loaded
        }

        // Stats — only load if same day
        let savedTimestamp = defaults.double(forKey: Keys.statsDate)
        let savedDate = Date(timeIntervalSince1970: savedTimestamp)
        if Calendar.current.isDateInToday(savedDate) {
            state.todayStats.lidOpenCount = defaults.integer(forKey: Keys.statsLidOpens)
            state.todayStats.keystrokeCount = defaults.integer(forKey: Keys.statsKeystrokes)
            state.todayStats.roastCount = defaults.integer(forKey: Keys.statsRoastCount)
            state.todayStats.maxIdleMinutes = defaults.integer(forKey: Keys.statsMaxIdle)
            state.todayStats.slapCount = defaults.integer(forKey: "com.judgymac.stats.slapCount")
            state.todayStats.appSwitchCount = defaults.integer(forKey: "com.judgymac.stats.appSwitchCount")
            state.todayStats.thermalCount = defaults.integer(forKey: "com.judgymac.stats.thermalCount")
            state.todayStats.screenTimeMinutes = defaults.integer(forKey: "com.judgymac.stats.screenTime")
            if let saved = defaults.dictionary(forKey: Keys.statsTriggerCounts) as? [String: Int] {
                for (key, value) in saved {
                    if let trigger = TriggerType(rawValue: key) {
                        state.todayStats.triggerCounts[trigger] = value
                    }
                }
            }
        }

        // History
        if let historyData = defaults.array(forKey: Keys.roastHistory) as? [[String: Any]] {
            state.roastHistory = historyData.compactMap { dict in
                guard let text = dict["text"] as? String,
                      let personality = dict["personality"] as? String,
                      let triggerRaw = dict["trigger"] as? String,
                      let moodRaw = dict["mood"] as? String,
                      let trigger = TriggerType(rawValue: triggerRaw),
                      let mood = Mood(rawValue: moodRaw) else { return nil }
                let ts = (dict["timestamp"] as? Double).map { Date(timeIntervalSince1970: $0) } ?? Date()
                return RoastEntry(text: text, personality: personality, triggerType: trigger, mood: mood, timestamp: ts)
            }
        }
    }

    // MARK: - Migration

    private static func migrateLegacyKeys() {
        // Remove old keys so they don't interfere
        for key in [Keys.legacyPersonality, Keys.legacySlapCharacter, Keys.legacyIntensity] {
            defaults.removeObject(forKey: key)
        }
    }
}
