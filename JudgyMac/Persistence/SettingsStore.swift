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
        static let lidCreakEnabled = "com.judgymac.lidCreakEnabled"
        static let licenseKey = "com.judgymac.licenseKey"
        static let isLicenseValid = "com.judgymac.licenseValid"
        static let knownTriggers = "com.judgymac.knownTriggers"

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
        defaults.set(state.lidCreakEnabled, forKey: Keys.lidCreakEnabled)
        if !state.licenseKey.isEmpty {
            defaults.set(LicenseManager.hashKey(state.licenseKey), forKey: Keys.licenseKey)
        }
        defaults.set(state.isLicenseValid, forKey: Keys.isLicenseValid)

        let triggers = state.enabledTriggers.map(\.rawValue)
        defaults.set(triggers, forKey: Keys.enabledTriggers)
        // Save all known trigger types so we can detect truly new ones on load
        defaults.set(TriggerType.allCases.map(\.rawValue), forKey: Keys.knownTriggers)

        // Stats
        defaults.set(Date().timeIntervalSince1970, forKey: Keys.statsDate)
        defaults.set(state.todayStats.lidOpenCount, forKey: Keys.statsLidOpens)
        defaults.set(state.todayStats.keystrokeCount, forKey: Keys.statsKeystrokes)
        defaults.set(state.todayStats.roastCount, forKey: Keys.statsRoastCount)
        defaults.set(state.todayStats.maxIdleMinutes, forKey: Keys.statsMaxIdle)
        defaults.set(state.todayStats.slapCount, forKey: "com.judgymac.stats.slapCount")
        defaults.set(state.todayStats.appSwitchCount, forKey: "com.judgymac.stats.appSwitchCount")
        defaults.set(state.todayStats.totalAppSwitchCount, forKey: "com.judgymac.stats.totalAppSwitchCount")
        defaults.set(state.todayStats.thermalCount, forKey: "com.judgymac.stats.thermalCount")
        defaults.set(state.todayStats.koCount, forKey: "com.judgymac.stats.koCount")
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
        if defaults.object(forKey: Keys.lidCreakEnabled) != nil {
            state.lidCreakEnabled = defaults.bool(forKey: Keys.lidCreakEnabled)
        }
        state.licenseKey = defaults.string(forKey: Keys.licenseKey) ?? "" // stored as hash
        state.isLicenseValid = defaults.bool(forKey: Keys.isLicenseValid)

        if let triggers = defaults.stringArray(forKey: Keys.enabledTriggers) {
            var loaded = Set(triggers.compactMap { TriggerType(rawValue: $0) })
            // Auto-enable only truly new trigger types (not known at last save)
            let knownAtSave = Set(defaults.stringArray(forKey: Keys.knownTriggers) ?? triggers)
            for trigger in TriggerType.allCases where !knownAtSave.contains(trigger.rawValue) {
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
            state.todayStats.totalAppSwitchCount = defaults.integer(forKey: "com.judgymac.stats.totalAppSwitchCount")
            state.todayStats.thermalCount = defaults.integer(forKey: "com.judgymac.stats.thermalCount")
            state.todayStats.koCount = defaults.integer(forKey: "com.judgymac.stats.koCount")
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

    // MARK: - Clear All Data

    static func clearAll() {
        // Nuclear: remove entire persistent domain + individual keys
        if let bundleId = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleId)
        }
        // Also remove individually (covers keys outside bundle domain)
        let allKeys = [
            Keys.selectedCharacterPack, Keys.enabledTriggers, Keys.isOnboarded,
            Keys.toastEnabled, Keys.voiceEnabled, Keys.licenseKey, Keys.isLicenseValid,
            Keys.statsDate, Keys.statsLidOpens, Keys.statsKeystrokes,
            Keys.statsRoastCount, Keys.statsMaxIdle, Keys.statsTriggerCounts,
            Keys.roastHistory,
            "com.judgymac.stats.slapCount", "com.judgymac.stats.appSwitchCount",
            "com.judgymac.stats.totalAppSwitchCount",
            "com.judgymac.stats.thermalCount", "com.judgymac.stats.koCount",
            "com.judgymac.stats.screenTime",
            "com.judgymac.hasLaunchedBefore",
            "com.judgymac.welcomeShownForVersion",
        ]
        for key in allKeys {
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()
        // Kill cfprefsd cache so changes take effect immediately
        _ = try? Process.run(URL(fileURLWithPath: "/usr/bin/killall"), arguments: ["cfprefsd"])
    }

    // MARK: - Migration

    private static func migrateLegacyKeys() {
        // Remove old keys so they don't interfere
        for key in [Keys.legacyPersonality, Keys.legacySlapCharacter, Keys.legacyIntensity] {
            defaults.removeObject(forKey: key)
        }
    }
}
