import Foundation

enum Mood: String, CaseIterable, Sendable {
    case neutral
    case judging
    case horrified
    case sleeping
    case raging
    case impressed

    var emoji: String {
        switch self {
        case .neutral:   return "😐"
        case .judging:   return "🤨"
        case .horrified: return "😱"
        case .sleeping:  return "😴"
        case .raging:    return "🤬"
        case .impressed: return "😮"
        }
    }

    var iconName: String {
        "face_\(rawValue)"
    }

    var displayName: String {
        switch self {
        case .neutral:   return "Neutral"
        case .judging:   return "Judging"
        case .horrified: return "Horrified"
        case .sleeping:  return "Sleeping"
        case .raging:    return "Raging"
        case .impressed: return "Impressed"
        }
    }
}
