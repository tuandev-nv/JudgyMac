import Foundation

// MARK: - Slap Character (loaded from config.json per folder)

struct SlapCharacter: Identifiable, Sendable {
    let id: String
    let displayName: String
    let category: Category
    let animationStyle: SlapAnimationStyle
    let slapSoundName: String
    let faces: FaceSet
    let reactions: [Reaction]
    let folderPath: String  // e.g. "SlapTargets/chibi-girl"

    enum Category: String, Codable, Sendable, CaseIterable {
        case face, butt, custom
    }

    struct FaceSet: Sendable {
        let normal: String      // Level 0 — idle
        let hit: String         // Flash on each slap
        let damaged1: String    // Level 1 resting (3+ hits)
        let damaged2: String    // Level 2 resting (7+ hits)
        let damaged3: String    // Level 3 resting (15+ hits)
        let ko: String          // Level 4+ (16+ hits)
    }

    struct Reaction: Sendable {
        let minHits: Int
        let texts: [String]
        let voices: [String]
    }

    /// Get the best reaction for current hit count.
    func reaction(forHitCount count: Int) -> Reaction? {
        reactions
            .filter { $0.minHits <= count }
            .max(by: { $0.minHits < $1.minHits })
    }

    /// Get face image for current level.
    func faceImage(level: Int) -> String {
        switch level {
        case 0: return faces.normal
        case 1: return faces.damaged1
        case 2: return faces.damaged2
        case 3: return faces.damaged3
        default: return faces.ko
        }
    }
}

// MARK: - Animation Style

enum SlapAnimationStyle: String, Codable, Sendable {
    case shake, bounce, jiggle, spin
}

// MARK: - JSON Schema (for decoding config.json)

private struct SlapCharacterJSON: Codable {
    let id: String
    let displayName: String
    let category: String
    let animationStyle: String
    let slapSound: String
    let faces: FacesJSON
    let reactions: [ReactionJSON]

    struct FacesJSON: Codable {
        let normal: String
        let hit: String
        let damaged1: String
        let damaged2: String
        let damaged3: String
        let ko: String
    }

    struct ReactionJSON: Codable {
        let minHits: Int
        let texts: [String]
        let voices: [String]
    }
}

// MARK: - Catalog (auto-discovers from SlapTargets/ folder)

enum SlapCharacterCatalog {
    nonisolated(unsafe) private(set) static var all: [SlapCharacter] = loadAll()

    static func character(for id: String) -> SlapCharacter? {
        all.first { $0.id == id }
    }

    static var defaultCharacter: SlapCharacter {
        all.first ?? fallbackCharacter
    }

    static func reload() {
        all = loadAll()
    }

    // MARK: - Loading

    private static func loadAll() -> [SlapCharacter] {
        guard let targetsURL = Bundle.main.resourceURL?
            .appendingPathComponent("SlapTargets") else { return [fallbackCharacter] }

        var characters: [SlapCharacter] = []

        guard let folders = try? FileManager.default
            .contentsOfDirectory(at: targetsURL, includingPropertiesForKeys: [.isDirectoryKey]) else {
            return [fallbackCharacter]
        }

        for folder in folders {
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDir),
                  isDir.boolValue else { continue }

            let configURL = folder.appendingPathComponent("config.json")
            guard let data = try? Data(contentsOf: configURL),
                  let json = try? JSONDecoder().decode(SlapCharacterJSON.self, from: data) else {
                continue
            }

            let folderName = folder.lastPathComponent
            let folderPath = "SlapTargets/\(folderName)"

            let character = SlapCharacter(
                id: json.id,
                displayName: json.displayName,
                category: SlapCharacter.Category(rawValue: json.category) ?? .face,
                animationStyle: SlapAnimationStyle(rawValue: json.animationStyle) ?? .shake,
                slapSoundName: "\(folderPath)/\(json.slapSound)",
                faces: SlapCharacter.FaceSet(
                    normal: "\(folderPath)/\(json.faces.normal)",
                    hit: "\(folderPath)/\(json.faces.hit)",
                    damaged1: "\(folderPath)/\(json.faces.damaged1)",
                    damaged2: "\(folderPath)/\(json.faces.damaged2)",
                    damaged3: "\(folderPath)/\(json.faces.damaged3)",
                    ko: "\(folderPath)/\(json.faces.ko)"
                ),
                reactions: json.reactions.map {
                    SlapCharacter.Reaction(
                        minHits: $0.minHits,
                        texts: $0.texts,
                        voices: $0.voices.map { "\(folderPath)/\($0)" }
                    )
                },
                folderPath: folderPath
            )
            characters.append(character)
        }

        return characters.isEmpty ? [fallbackCharacter] : characters
    }

    // MARK: - Fallback (uses Fluent Emoji if no character folders found)

    private static let fallbackCharacter = SlapCharacter(
        id: "default",
        displayName: "Judgmental Face",
        category: .face,
        animationStyle: .shake,
        slapSoundName: "slap_hit",
        faces: SlapCharacter.FaceSet(
            normal: "face_with_raised_eyebrow_3d",
            hit: "flushed_face_3d",
            damaged1: "unamused_face_3d",
            damaged2: "face_with_steam_from_nose_3d",
            damaged3: "face_screaming_in_fear_3d",
            ko: "exploding_head_3d"
        ),
        reactions: [
            .init(minHits: 1, texts: ["OW!", "HEY!"], voices: []),
            .init(minHits: 4, texts: ["STOP!", "ENOUGH!"], voices: []),
            .init(minHits: 8, texts: ["MERCY!", "PLEASE!"], voices: []),
            .init(minHits: 16, texts: ["💀", "K.O!"], voices: []),
        ],
        folderPath: ""
    )
}
