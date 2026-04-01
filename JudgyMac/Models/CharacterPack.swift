import Foundation

// MARK: - Character Pack (unified: personality + slap + voice)

struct CharacterPack: Identifiable, Sendable {
    let id: String
    let displayName: String
    let language: String
    let description: String
    let iconImagePath: String
    let slapLimit: Int
    let slapVoiceCount: Int
    let folderPath: String

    // Slap
    let animationStyle: SlapAnimationStyle
    let slapSoundPath: String
    let faces: FaceSet
    let reactions: [Reaction]
    let rageReaction: RageReaction?

    // Roasts
    var roastTemplates: [String: [RoastTemplate]]

    struct FaceSet: Sendable {
        let normal: String      // Level 0
        let hit: String         // Flash on each slap
        let damaged1: String    // Level 1 (1-3 hits)
        let damaged2: String    // Level 2 (4-7)
        let damaged3: String    // Level 3 (8-12)
        let damaged4: String    // Level 4 (13-20)
        let damaged5: String    // Level 5 (21-30)
        let damaged6: String    // Level 6 (31-40)
        let damaged7: String    // Level 7 (41-49)
        let ko: String          // Level 8 (50+)
        let rage: String?
    }

    struct ReactionLine: Sendable {
        let text: String
        let voicePath: String?
    }

    struct Reaction: Sendable {
        let minHits: Int
        let lines: [ReactionLine]
    }

    struct RageReaction: Sendable {
        let text: String
        let voicePath: String?
    }

    // MARK: - Helpers

    func templates(for trigger: TriggerType) -> [RoastTemplate] {
        roastTemplates[trigger.rawValue] ?? []
    }

    func faceImage(level: Int) -> String {
        switch level {
        case 0: return faces.normal
        case 1: return faces.damaged1
        case 2: return faces.damaged2
        case 3: return faces.damaged3
        case 4: return faces.damaged4
        case 5: return faces.damaged5
        case 6: return faces.damaged6
        case 7: return faces.damaged7
        default: return faces.ko
        }
    }

    func reaction(forHitCount count: Int) -> Reaction? {
        reactions
            .filter { $0.minHits <= count }
            .max(by: { $0.minHits < $1.minHits })
    }

    /// Random emoji from pack's emojis/ folder. Returns nil if no custom emojis.
    func randomEmoji() -> String? {
        let cached = Self.emojiCache[id]
        let emojis: [String]

        if let cached {
            emojis = cached
        } else {
            guard let dir = Bundle.main.resourceURL?
                .appendingPathComponent(folderPath)
                .appendingPathComponent("emojis"),
                  let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                    .filter({ $0.pathExtension == "png" })
                    .map({ $0.deletingPathExtension().lastPathComponent })
            else {
                Self.emojiCache[id] = []
                return nil
            }
            emojis = files
            Self.emojiCache[id] = files
        }

        guard let name = emojis.randomElement() else { return nil }
        return "\(folderPath)/emojis/\(name)"
    }

    nonisolated(unsafe) private static var emojiCache: [String: [String]] = [:]

    /// Voice path for a roast template (if available)
    func roastVoicePath(templateId: String) -> String? {
        for templates in roastTemplates.values {
            if let t = templates.first(where: { $0.id == templateId }) {
                return t.voicePath
            }
        }
        return nil
    }
}

// MARK: - Animation Style

enum SlapAnimationStyle: String, Codable, Sendable {
    case shake, bounce, jiggle, spin
}

// MARK: - Roast Template

struct RoastTemplate: Codable, Identifiable, Sendable {
    let id: String
    let text: String
    let variables: [String]
    var weight: Double
    let voice: String?

    /// Full path to voice file within the pack folder (set after loading)
    var voicePath: String?

    func rendered(with context: [String: String]) -> String {
        var result = text
        for (key, value) in context {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return result
    }

    private enum CodingKeys: String, CodingKey {
        case id, text, variables, weight, voice
    }
}

// MARK: - JSON Schema (for decoding pack.json)

private struct PackJSON: Codable {
    let id: String
    let displayName: String
    let language: String
    let description: String
    let icon: String
    let slapLimit: Int?
    let slap: SlapJSON
    let roasts: [String: [RoastTemplate]]

    struct SlapJSON: Codable {
        let animationStyle: String
        let slapSound: String
        let faces: FacesJSON
        let reactions: [ReactionJSON]
        let slapVoiceCount: Int?
        let rageReaction: RageJSON?

        struct FacesJSON: Codable {
            let normal: String
            let hit: String
            let damaged1: String
            let damaged2: String
            let damaged3: String
            let damaged4: String
            let damaged5: String
            let damaged6: String
            let damaged7: String
            let ko: String
            let rage: String?
        }

        struct ReactionLineJSON: Codable {
            let text: String
            let voice: String?
        }

        struct ReactionJSON: Codable {
            let minHits: Int
            let texts: [ReactionLineJSON]
        }

        struct RageJSON: Codable {
            let text: String
            let voice: String?
        }
    }
}

// MARK: - Catalog (auto-discovers from CharacterPacks/ folder)

enum CharacterPackCatalog {
    nonisolated(unsafe) private(set) static var all: [CharacterPack] = loadAll()

    static func pack(for id: String) -> CharacterPack? {
        all.first { $0.id == id }
    }

    static var defaultPack: CharacterPack {
        all.first!
    }

    static func reload() {
        all = loadAll()
    }

    // MARK: - Loading

    private static func loadAll() -> [CharacterPack] {
        guard let packsURL = Bundle.main.resourceURL?
            .appendingPathComponent("CharacterPacks") else { return [] }

        var packs: [CharacterPack] = []

        guard let folders = try? FileManager.default
            .contentsOfDirectory(at: packsURL, includingPropertiesForKeys: [.isDirectoryKey]) else {
            return []
        }

        for folder in folders {
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDir),
                  isDir.boolValue else { continue }

            let configURL = folder.appendingPathComponent("pack.json")
            guard let data = try? Data(contentsOf: configURL),
                  let json = try? JSONDecoder().decode(PackJSON.self, from: data) else {
                continue
            }

            let folderName = folder.lastPathComponent
            let folderPath = "CharacterPacks/\(folderName)"

            let faces = json.slap.faces
            var roasts = json.roasts

            // Set voice paths relative to pack folder
            for (trigger, templates) in roasts {
                roasts[trigger] = templates.map { t in
                    var template = t
                    if let voice = t.voice {
                        template.voicePath = "\(folderPath)/roasts/\(voice)"
                    }
                    return template
                }
            }

            let pack = CharacterPack(
                id: json.id,
                displayName: json.displayName,
                language: json.language,
                description: json.description,
                iconImagePath: "\(folderPath)/\(json.icon)",
                slapLimit: json.slapLimit ?? 50,
                slapVoiceCount: json.slap.slapVoiceCount ?? 0,
                folderPath: folderPath,
                animationStyle: SlapAnimationStyle(rawValue: json.slap.animationStyle) ?? .shake,
                slapSoundPath: "\(folderPath)/\(json.slap.slapSound)",
                faces: CharacterPack.FaceSet(
                    normal: "\(folderPath)/\(faces.normal)",
                    hit: "\(folderPath)/\(faces.hit)",
                    damaged1: "\(folderPath)/\(faces.damaged1)",
                    damaged2: "\(folderPath)/\(faces.damaged2)",
                    damaged3: "\(folderPath)/\(faces.damaged3)",
                    damaged4: "\(folderPath)/\(faces.damaged4)",
                    damaged5: "\(folderPath)/\(faces.damaged5)",
                    damaged6: "\(folderPath)/\(faces.damaged6)",
                    damaged7: "\(folderPath)/\(faces.damaged7)",
                    ko: "\(folderPath)/\(faces.ko)",
                    rage: faces.rage.map { "\(folderPath)/\($0)" }
                ),
                reactions: json.slap.reactions.map { r in
                    CharacterPack.Reaction(
                        minHits: r.minHits,
                        lines: r.texts.map { line in
                            CharacterPack.ReactionLine(
                                text: line.text,
                                voicePath: line.voice.map { "\(folderPath)/slap_voices/\($0)" }
                            )
                        }
                    )
                },
                rageReaction: json.slap.rageReaction.map {
                    CharacterPack.RageReaction(
                        text: $0.text,
                        voicePath: $0.voice.map { "\(folderPath)/slap_voices/\($0)" }
                    )
                },
                roastTemplates: roasts
            )
            packs.append(pack)
        }

        return packs
    }
}
