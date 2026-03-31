import AVFoundation

/// Lightweight sound player with caching and layered playback.
/// Plays from `Resources/Sounds/` folder. Supports `.aiff`, `.mp3`, `.wav`.
@MainActor
enum SoundPlayer {
    private static var urlCache: [String: URL?] = [:]
    private static var activePlayers: [AVAudioPlayer] = []
    private static let maxActivePlayers = 10

    // MARK: - Play

    /// Play a sound by name (without extension). Searches for .aiff, .mp3, .wav.
    /// If the sound is already playing, a new overlapping instance is created.
    static func play(_ name: String, volume: Float = 1.0, rate: Float = 1.0) {
        guard let url = resolveURL(name) else {
            #if DEBUG
            print("🔊 [SoundPlayer] Sound not found: \(name)")
            #endif
            return
        }

        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.volume = volume
        player.enableRate = rate != 1.0
        if rate != 1.0 { player.rate = rate }
        player.prepareToPlay()
        player.play()

        // Cap active players to prevent memory spike during rapid slapping
        cleanupFinished()
        if activePlayers.count >= maxActivePlayers {
            activePlayers.first?.stop()
            activePlayers.removeFirst()
        }
        activePlayers.append(player)
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

    /// Preload sound URL resolution into cache for instant playback.
    static func preload(_ names: [String]) {
        for name in names {
            _ = resolveURL(name)
        }
    }

    // MARK: - Internal

    private static let supportedExtensions = ["aiff", "mp3", "wav", "m4a"]

    /// Cached URL resolution — filesystem lookup only once per sound name
    private static func resolveURL(_ name: String) -> URL? {
        if let cached = urlCache[name] {
            return cached
        }
        let url = findSoundURL(name)
        urlCache[name] = url
        return url
    }

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
