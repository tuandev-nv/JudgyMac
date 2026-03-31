import Foundation

struct RoastEntry: Identifiable, Sendable {
    let id: UUID
    let text: String
    let personality: String
    let triggerType: TriggerType
    let mood: Mood
    let timestamp: Date

    init(
        text: String,
        personality: String,
        triggerType: TriggerType,
        mood: Mood,
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.text = text
        self.personality = personality
        self.triggerType = triggerType
        self.mood = mood
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
