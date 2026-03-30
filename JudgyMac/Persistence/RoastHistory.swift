import Foundation

/// Persists last 100 roasts to disk using actor for thread safety.
actor RoastHistoryStore {
    private let fileURL: URL
    private var entries: [RoastEntryDTO] = []

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("JudgyMac", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        let url = appDir.appendingPathComponent("roast_history.json")
        self.fileURL = url

        // Load synchronously in init (actor-isolated OK since we own this)
        if let data = try? Data(contentsOf: url) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            self.entries = (try? decoder.decode([RoastEntryDTO].self, from: data)) ?? []
        }
    }

    func add(_ entry: RoastEntry) {
        let dto = RoastEntryDTO(from: entry)
        entries.insert(dto, at: 0)
        if entries.count > Constants.Roast.maxHistoryEntries {
            entries = Array(entries.prefix(Constants.Roast.maxHistoryEntries))
        }
        save()
    }

    func getAll() -> [RoastEntry] {
        entries.map { $0.toRoastEntry() }
    }

    func clear() {
        entries.removeAll()
        save()
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(entries) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        entries = (try? decoder.decode([RoastEntryDTO].self, from: data)) ?? []
    }
}

// MARK: - DTO

private struct RoastEntryDTO: Codable {
    let id: String
    let text: String
    let personality: String
    let triggerType: String
    let mood: String
    let timestamp: Date

    init(from entry: RoastEntry) {
        self.id = entry.id.uuidString
        self.text = entry.text
        self.personality = entry.personality
        self.triggerType = entry.triggerType.rawValue
        self.mood = entry.mood.rawValue
        self.timestamp = entry.timestamp
    }

    func toRoastEntry() -> RoastEntry {
        RoastEntry(
            text: text,
            personality: personality,
            triggerType: TriggerType(rawValue: triggerType) ?? .lidOpen,
            mood: Mood(rawValue: mood) ?? .neutral
        )
    }
}
