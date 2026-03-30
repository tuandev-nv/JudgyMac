import AppKit
import SwiftUI

/// Maps moods to Fluent Emoji 3D assets.
enum FluentEmoji {
    // Image caches — avoid disk reads on every animation frame
    // NSCache is thread-safe internally, safe to share across isolation domains
    private nonisolated(unsafe) static let menuBarCache = NSCache<NSString, NSImage>()
    private nonisolated(unsafe) static let image3DCache = NSCache<NSString, NSImage>()

    /// 4 faces per mood — cycled for animation
    static let faces: [Mood: [String]] = [
        .neutral: [
            "face_with_raised_eyebrow_3d",
            "unamused_face_3d",
            "expressionless_face_3d",
            "neutral_face_3d",
        ],
        .judging: [
            "face_with_monocle_3d",
            "smirking_face_3d",
            "face_with_rolling_eyes_3d",
            "thinking_face_3d",
        ],
        .raging: [
            "face_with_symbols_on_mouth_3d",
            "pouting_face_3d",
            "exploding_head_3d",
            "face_with_steam_from_nose_3d",
        ],
        .sleeping: [
            "sleeping_face_3d",
            "yawning_face_3d",
            "sleepy_face_3d",
            "pensive_face_3d",
        ],
        .horrified: [
            "face_screaming_in_fear_3d",
            "flushed_face_3d",
            "astonished_face_3d",
            "anxious_face_with_sweat_3d",
        ],
        .impressed: [
            "star-struck_3d",
            "hushed_face_3d",
            "face_with_open_mouth_3d",
            "partying_face_3d",
        ],
    ]

    /// Get the primary face for a mood (first in list)
    static func primary(for mood: Mood) -> String {
        faces[mood]?.first ?? "neutral_face_3d"
    }

    /// Get face at animation frame index
    static func face(for mood: Mood, frame: Int) -> String {
        let moodFaces = faces[mood] ?? faces[.neutral]!
        return moodFaces[frame % moodFaces.count]
    }

    /// Load 3D image (256x256, for toast/popover). Cached after first load.
    static func image3D(named name: String) -> NSImage? {
        let key = name as NSString
        if let cached = image3DCache.object(forKey: key) { return cached }

        let url = Bundle.main.resourceURL?
            .appendingPathComponent("Emoji/3D/\(name).png")
        guard let url, let image = NSImage(contentsOf: url) else { return nil }
        image3DCache.setObject(image, forKey: key)
        return image
    }

    /// Load menu bar image (18x18, for status item). Cached after first load.
    static func menuBarImage(named name: String) -> NSImage? {
        let key = name as NSString
        if let cached = menuBarCache.object(forKey: key) { return cached }

        let url = Bundle.main.resourceURL?
            .appendingPathComponent("Emoji/MenuBar/\(name).png")
        guard let url, let image = NSImage(contentsOf: url) else { return nil }
        image.size = NSSize(width: 18, height: 18)
        menuBarCache.setObject(image, forKey: key)
        return image
    }

    /// SwiftUI Image from 3D asset
    static func swiftUIImage(named name: String) -> Image? {
        guard let nsImage = image3D(named: name) else { return nil }
        return Image(nsImage: nsImage)
    }
}
