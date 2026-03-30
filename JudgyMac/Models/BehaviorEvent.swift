import Foundation

enum TriggerType: String, CaseIterable, Codable, Sendable {
    case lidOpen = "lid_open"
    case lidReopen = "lid_reopen"
    case lateNight = "late_night"
    case earlyMorning = "early_morning"
    case thermal = "thermal"
    case idle = "idle"

    var displayName: String {
        switch self {
        case .lidOpen:       return "Lid Open"
        case .lidReopen:     return "Quick Re-open"
        case .lateNight:     return "Late Night"
        case .earlyMorning:  return "Early Morning"
        case .thermal:       return "Overheating"
        case .idle:          return "Too Idle"
        }
    }

    var icon: String {
        switch self {
        case .lidOpen:       return "laptopcomputer"
        case .lidReopen:     return "arrow.2.squarepath"
        case .lateNight:     return "moon.fill"
        case .earlyMorning:  return "sunrise.fill"
        case .thermal:       return "flame.fill"
        case .idle:          return "zzz"
        }
    }
}

struct BehaviorEvent: Sendable {
    let type: TriggerType
    let timestamp: Date
    let metadata: [String: String]

    init(type: TriggerType, metadata: [String: String] = [:]) {
        self.type = type
        self.timestamp = Date()
        self.metadata = metadata
    }

    // MARK: - Convenience Constructors

    static func lidOpen(count: Int) -> BehaviorEvent {
        BehaviorEvent(type: .lidOpen, metadata: ["count": "\(count)"])
    }

    static func lidReopen(secondsSinceClose: Int) -> BehaviorEvent {
        BehaviorEvent(type: .lidReopen, metadata: ["seconds_since_close": "\(secondsSinceClose)"])
    }

    static func lateNight(hour: Int) -> BehaviorEvent {
        BehaviorEvent(type: .lateNight, metadata: ["hour": "\(hour)"])
    }

    static func earlyMorning(hour: Int) -> BehaviorEvent {
        BehaviorEvent(type: .earlyMorning, metadata: ["hour": "\(hour)"])
    }

    static func thermal(state: String) -> BehaviorEvent {
        BehaviorEvent(type: .thermal, metadata: ["thermal": state])
    }

    static func idle(minutes: Int) -> BehaviorEvent {
        BehaviorEvent(type: .idle, metadata: ["idle_minutes": "\(minutes)"])
    }
}
