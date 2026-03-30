import Foundation

/// Core engine: selects appropriate roast for a behavior event.
/// Loads templates, applies cooldown, injects variables, returns RoastEntry.
@MainActor
final class RoastEngine {
    private var packs: [String: PersonalityPack] = [:]
    private let cooldown = RoastCooldownTracker()
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        loadAllPacks()

    }

    // MARK: - Public

    func generateRoast(for event: BehaviorEvent) -> RoastEntry? {
        let personalityId = appState.selectedPersonality

        guard let pack = packs[personalityId] else { return nil }

        let allForTrigger = pack.templates(for: event.type)
        let afterIntensity = allForTrigger.filter { $0.intensity <= appState.intensity }
        let candidates = afterIntensity.filter { cooldown.canRoast(templateId: $0.id, triggerType: event.type, isFullVersion: appState.isFullVersion) }

        guard !candidates.isEmpty else { return nil }

        // Weighted random selection
        let selected = weightedRandom(from: candidates)
        guard let template = selected else { return nil }

        // Build context variables
        let context = buildContext(for: event)
        let text = template.rendered(with: context)

        // Record usage
        cooldown.recordRoast(templateId: template.id, triggerType: event.type)

        let mood = MoodEngine.mood(for: event, stats: appState.todayStats)
        return RoastEntry(
            text: text,
            personality: pack.displayName,
            triggerType: event.type,
            mood: mood
        )
    }

    // MARK: - Template Loading

    private func loadAllPacks() {
        for catalog in PersonalityPack.catalog {
            var pack = catalog
            if let data = loadJSON(personality: pack.id, language: pack.language) {
                pack.templates = data.templates
            }
            packs[pack.id] = pack
        }
    }

    private func loadJSON(personality: String, language: String) -> PersonalityPackData? {
        // Try folder reference path first (xcodegen folder type)
        let possiblePaths = [
            Bundle.main.resourceURL?.appendingPathComponent("Roasts/\(language)/\(personality).json"),
            Bundle.main.url(forResource: personality, withExtension: "json", subdirectory: "Roasts/\(language)"),
        ]

        for case let url? in possiblePaths {
            if let data = try? Data(contentsOf: url),
               let pack = try? JSONDecoder().decode(PersonalityPackData.self, from: data) {
                return pack
            }
        }

        return nil
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

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        ctx["time"] = formatter.string(from: Date())

        return ctx
    }
}
