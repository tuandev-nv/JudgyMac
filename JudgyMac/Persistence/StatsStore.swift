import Foundation

/// Persists daily stats to UserDefaults. Resets automatically on new day.
actor StatsStore {
    private let defaults = UserDefaults.standard
    private let statsKey = "com.judgymac.dailyStats"
    private let dateKey = "com.judgymac.statsDate"

    func save(_ stats: UserStats) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(StatsDTO(from: stats)) {
            defaults.set(data, forKey: statsKey)
            defaults.set(Date().timeIntervalSince1970, forKey: dateKey)
        }
    }

    func load() -> UserStats {
        // Check if it's a new day
        let savedTimestamp = defaults.double(forKey: dateKey)
        let savedDate = Date(timeIntervalSince1970: savedTimestamp)

        guard Calendar.current.isDateInToday(savedDate),
              let data = defaults.data(forKey: statsKey),
              let dto = try? JSONDecoder().decode(StatsDTO.self, from: data) else {
            return UserStats()
        }

        return dto.toUserStats()
    }
}

// MARK: - DTO for Codable serialization

private struct StatsDTO: Codable {
    let lidOpenCount: Int
    let keystrokeCount: Int
    let roastCount: Int
    let maxIdleMinutes: Int
    let date: Date

    init(from stats: UserStats) {
        self.lidOpenCount = stats.lidOpenCount
        self.keystrokeCount = stats.keystrokeCount
        self.roastCount = stats.roastCount
        self.maxIdleMinutes = stats.maxIdleMinutes
        self.date = stats.date
    }

    func toUserStats() -> UserStats {
        var stats = UserStats()
        stats.lidOpenCount = lidOpenCount
        stats.keystrokeCount = keystrokeCount
        stats.roastCount = roastCount
        stats.maxIdleMinutes = maxIdleMinutes
        stats.date = date
        return stats
    }
}
