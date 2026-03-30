import AVFoundation

/// Lightweight sound player with caching and layered playback.
/// Plays from `Resources/Sounds/` folder. Supports `.aiff`, `.mp3`, `.wav`.
@MainActor
enum SoundPlayer {
    private static var cache: [String: AVAudioPlayer] = [:]
    private static var activePlayers: [AVAudioPlayer] = []

    // MARK: - Play

    /// Play a sound by name (without extension). Searches for .aiff, .mp3, .wav.
    /// If the sound is already playing, a new overlapping instance is created.
    static func play(_ name: String, volume: Float = 1.0, rate: Float = 1.0) {
        guard let url = findSoundURL(name) else {
            #if DEBUG
            print("🔊 [SoundPlayer] Sound not found: \(name)")
            #endif
            return
        }

        // Create a new player for overlapping support
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.volume = volume
        player.enableRate = rate != 1.0
        if rate != 1.0 { player.rate = rate }
        player.prepareToPlay()
        player.play()

        // Keep strong reference, remove when done
        activePlayers.append(player)
        cleanupFinished()
    }

    /// Play slap impact + voice reaction with slight delay between them.
    static func playSlapCombo(slapSound: String, voiceSound: String?) {
        // Slap impact — immediate
        play(slapSound)

        // Voice reaction — slight delay for natural feel
        guard let voice = voiceSound else { return }
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            play(voice, volume: 0.9)
        }
    }

    // MARK: - Preload

    /// Preload sounds into cache for instant playback.
    static func preload(_ names: [String]) {
        for name in names {
            guard cache[name] == nil, let url = findSoundURL(name) else { continue }
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                cache[name] = player
            }
        }
    }

    // MARK: - Internal

    private static let supportedExtensions = ["aiff", "mp3", "wav", "m4a"]

    private static func findSoundURL(_ name: String) -> URL? {
        let resourceURL = Bundle.main.resourceURL

        // Try exact path first (e.g. "SlapTargets/chibi-girl/slap_normal")
        for ext in supportedExtensions {
            if let url = resourceURL?.appendingPathComponent("\(name).\(ext)"),
               FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        // Try Sounds/ folder
        for ext in supportedExtensions {
            if let url = resourceURL?.appendingPathComponent("Sounds/\(name).\(ext)"),
               FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        // Fallback: bundle root
        for ext in supportedExtensions {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
        }

        return nil
    }

    private static func cleanupFinished() {
        activePlayers.removeAll { !$0.isPlaying }
    }
}
