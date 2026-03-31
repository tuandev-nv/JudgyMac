import Foundation

enum TriggerType: String, CaseIterable, Codable, Sendable {
    case lidOpen = "lid_open"
    case lidReopen = "lid_reopen"
    case lateNight = "late_night"
    case earlyMorning = "early_morning"
    case thermal = "thermal"
    case idle = "idle"
    case screenTime = "screen_time"
    case appSwitch = "app_switch"
    case slap = "slap"

    var displayName: String {
        switch self {
        case .lidOpen:       return "Lid Open"
        case .lidReopen:     return "Quick Re-open"
        case .lateNight:     return "Late Night"
        case .earlyMorning:  return "Early Morning"
        case .thermal:       return "Overheating"
        case .idle:          return "Too Idle"
        case .screenTime:    return "Screen Time"
        case .appSwitch:     return "App Switching"
        case .slap:          return "Slap"
        }
    }

    var triggerDescription: String {
        switch self {
        case .lidOpen:       return "Roast when you open your laptop"
        case .lidReopen:     return "Roast when you close and reopen within 30 seconds"
        case .lateNight:     return "Roast when using Mac between midnight and 5 AM"
        case .earlyMorning:  return "Roast when using Mac between 5 AM and 7 AM"
        case .thermal:       return "Roast when your Mac overheats"
        case .idle:          return "Roast after 10 minutes of inactivity"
        case .screenTime:    return "Remind to take a break every 45 minutes"
        case .appSwitch:     return "Roast when switching apps too frequently"
        case .slap:          return "⌘ + ⇧ + Click to slap the character"
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
        case .screenTime:    return "eye.fill"
        case .appSwitch:     return "arrow.left.arrow.right"
        case .slap:          return "hand.raised.fill"
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

    static func screenTime(minutes: Int) -> BehaviorEvent {
        BehaviorEvent(type: .screenTime, metadata: ["minutes": "\(minutes)"])
    }

    static func appSwitch(count: Int, app: String) -> BehaviorEvent {
        BehaviorEvent(type: .appSwitch, metadata: ["count": "\(count)", "app": app])
    }

    static func slap(pressure: Double) -> BehaviorEvent {
        BehaviorEvent(type: .slap, metadata: ["pressure": String(format: "%.2f", pressure)])
    }
}
