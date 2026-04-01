import Foundation

/// Core engine: selects appropriate roast for a behavior event.
/// Loads templates from CharacterPack, applies cooldown, injects variables, returns RoastEntry.
@MainActor
final class RoastEngine {
    private let cooldown = RoastCooldownTracker()
    private let appState: AppState
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Public

    func generateRoast(for event: BehaviorEvent) -> RoastEntry? {
        let pack = appState.currentPack

        let allForTrigger = pack.templates(for: event.type)
        let candidates = allForTrigger.filter {
            cooldown.canRoast(templateId: $0.id, triggerType: event.type, isFullVersion: appState.isLicenseValid)
        }

        guard !candidates.isEmpty else { return nil }

        // Weighted random selection
        guard let template = weightedRandom(from: candidates) else { return nil }

        // Build context variables
        let context = buildContext(for: event)
        let text = template.rendered(with: context)

        // Record usage
        cooldown.recordRoast(templateId: template.id, triggerType: event.type)

        // Play roast voice if available
        if let voicePath = template.voicePath {
            SoundPlayer.play(voicePath, volume: 0.8)
        }

        let mood = MoodEngine.mood(for: event, stats: appState.todayStats)
        return RoastEntry(
            text: text,
            personality: pack.displayName,
            triggerType: event.type,
            mood: mood,
            customEmoji: pack.randomEmoji()
        )
    }

    // MARK: - Weighted Random

    private func weightedRandom(from templates: [RoastTemplate]) -> RoastTemplate? {
        let weights = templates.map { $0.weight * cooldown.decayedWeight(for: $0.id) }
        let totalWeight = weights.reduce(0, +)
        guard totalWeight > 0 else { return templates.randomElement() }

        var random = Double.random(in: 0..<totalWeight)
        for (index, weight) in weights.enumerated() {
            random -= weight
            if random <= 0 {
                return templates[index]
            }
        }
        return templates.last
    }

    // MARK: - Context Variables

    private func buildContext(for event: BehaviorEvent) -> [String: String] {
        var ctx = event.metadata
        let stats = appState.todayStats

        ctx["count"] = "\(stats.lidOpenCount)"
        ctx["total_today"] = "\(stats.roastCount)"

        let hour = Calendar.current.component(.hour, from: Date())
        ctx["hour"] = "\(hour)"

        ctx["time"] = Self.timeFormatter.string(from: Date())

        return ctx
    }
}
