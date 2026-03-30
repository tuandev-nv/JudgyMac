import Foundation

struct RoastTemplate: Codable, Identifiable, Sendable {
    let id: String
    let text: String
    let variables: [String]
    let intensity: Int
    var weight: Double

    func rendered(with context: [String: String]) -> String {
        var result = text
        for (key, value) in context {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return result
    }
}

struct PersonalityPackData: Codable, Sendable {
    let personality: String
    let language: String
    let templates: [String: [RoastTemplate]]
}
