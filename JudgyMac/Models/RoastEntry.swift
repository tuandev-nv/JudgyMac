import Foundation

struct RoastEntry: Identifiable, Sendable {
    let id: UUID
    let text: String
    let personality: String
    let triggerType: TriggerType
    let mood: Mood
    let timestamp: Date
    let customEmoji: String? // Path to pack emoji (e.g. "CharacterPacks/trump/emojis/angry")

    init(
        text: String,
        personality: String,
        triggerType: TriggerType,
        mood: Mood,
        customEmoji: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.text = text
        self.personality = personality
        self.triggerType = triggerType
        self.mood = mood
        self.customEmoji = customEmoji
        self.timestamp = timestamp
    }

    var shareText: String {
        "\"\(text)\" — JudgyMac (\(personality)) | judgymac.com"
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
