import Foundation

struct PersonalityPack: Identifiable, Sendable {
    let id: String
    let displayName: String
    let language: String
    let description: String
    let requiresFullVersion: Bool
    var templates: [String: [RoastTemplate]]

    func templates(for trigger: TriggerType) -> [RoastTemplate] {
        templates[trigger.rawValue] ?? []
    }

    static let catalog: [PersonalityPack] = [
        PersonalityPack(
            id: "the-critic",
            displayName: "The Critic",
            language: "en",
            description: "Witty, sarcastic observer of your digital life",
            requiresFullVersion: false,
            templates: [:]
        ),
        PersonalityPack(
            id: "vietnamese-mom",
            displayName: "Vietnamese Mom",
            language: "vi",
            description: "Con nha nguoi ta thi khong nhu con",
            requiresFullVersion: true,
            templates: [:]
        ),
        PersonalityPack(
            id: "toxic-boss",
            displayName: "Toxic Boss",
            language: "en",
            description: "Corporate passive-aggressive energy",
            requiresFullVersion: true,
            templates: [:]
        ),
        PersonalityPack(
            id: "drill-sergeant",
            displayName: "Drill Sergeant",
            language: "en",
            description: "Military tough love for your bad habits",
            requiresFullVersion: true,
            templates: [:]
        ),
        PersonalityPack(
            id: "shakespeare",
            displayName: "Shakespeare",
            language: "en",
            description: "Elizabethan insults for modern sins",
            requiresFullVersion: true,
            templates: [:]
        ),
        PersonalityPack(
            id: "therapist",
            displayName: "Therapist Who Gave Up",
            language: "en",
            description: "I'm not mad, just disappointed",
            requiresFullVersion: true,
            templates: [:]
        ),
    ]
}
