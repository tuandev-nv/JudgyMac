import Foundation

/// Generates the daily summary data from stats and roast history.
struct DailySummary: Sendable {
    let date: Date
    let stats: UserStats
    let topRoast: RoastEntry?
    let verdict: String
    let highlights: [String]

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

enum DailySummaryGenerator {
    static func generate(stats: UserStats, history: [RoastEntry]) -> DailySummary {
        let today = history.filter {
            Calendar.current.isDateInToday($0.timestamp)
        }

        let topRoast = today.first // Most recent
        let verdict = generateVerdict(stats: stats)
        let highlights = generateHighlights(stats: stats)

        return DailySummary(
            date: Date(),
            stats: stats,
            topRoast: topRoast,
            verdict: verdict,
            highlights: highlights
        )
    }

    private static func generateVerdict(stats: UserStats) -> String {
        if stats.roastCount >= 15 { return "Absolutely unhinged" }
        if stats.roastCount >= 10 { return "Impressively unproductive" }
        if stats.lidOpenCount >= 12 { return "Can't commit to anything" }
        if stats.maxIdleMinutes >= 45 { return "Possibly deceased" }
        if stats.keystrokeCount >= 5000 { return "Keyboard warrior" }
        if stats.roastCount >= 5 { return "Mildly questionable" }
        if stats.roastCount == 0 { return "Suspiciously well-behaved" }
        return "Average chaos"
    }

    private static func generateHighlights(stats: UserStats) -> [String] {
        var highlights: [String] = []

        if stats.lidOpenCount > 0 {
            highlights.append("Opened your laptop \(stats.lidOpenCount) times")
        }
        if stats.keystrokeCount > 0 {
            highlights.append("Typed \(formatNumber(stats.keystrokeCount)) angry keystrokes")
        }
        if stats.maxIdleMinutes > 0 {
            highlights.append("Were idle for \(stats.maxIdleMinutes) minutes straight")
        }
        if stats.roastCount > 0 {
            highlights.append("Got roasted \(stats.roastCount) times")
        }

        return highlights
    }

    private static func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
