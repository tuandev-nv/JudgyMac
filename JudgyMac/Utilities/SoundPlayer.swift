import AVFoundation

/// Lightweight sound player with caching and layered playback.
/// Plays from `Resources/Sounds/` folder. Supports `.aiff`, `.mp3`, `.wav`.
@MainActor
enum SoundPlayer {
    private static var urlCache: [String: URL?] = [:]
    private static var activePlayers: [AVAudioPlayer] = []
    private static var currentVoicePlayer: AVAudioPlayer?
    private static var voiceDebounceTask: Task<Void, Never>?
    private static let maxActivePlayers = 5
    /// Debounce interval — voice only plays after this pause between slaps.
    private static let voiceDebounceMs: UInt64 = 500
    static var isMuted = false

    // MARK: - Play

    /// Play a sound by name (without extension). Searches for .aiff, .mp3, .wav.
    /// If the sound is already playing, a new overlapping instance is created.
    static func play(_ name: String, volume: Float = 1.0, rate: Float = 1.0) {
        guard !isMuted else { return }
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

    /// Play slap impact + umph + voice reaction with delays between them.
    static func playSlapCombo(slapSound: String, umphSound: String? = nil, voiceSound: String?) {
        // Slap impact — immediate
        play(slapSound)

        // Umph reaction — short delay after impact
        if let umph = umphSound {
            Task {
                try? await Task.sleep(for: .milliseconds(80))
                play(umph, volume: 0.85)
            }
        }

        // Voice line — debounced. Only plays if no new slap within debounce window.
        guard !isMuted, let voice = voiceSound else { return }
        voiceDebounceTask?.cancel()
        voiceDebounceTask = Task {
            try? await Task.sleep(for: .milliseconds(voiceDebounceMs))
            guard !Task.isCancelled, !isMuted else { return }
            currentVoicePlayer?.stop()
            currentVoicePlayer = nil
            guard let url = resolveURL(voice),
                  let player = try? AVAudioPlayer(contentsOf: url) else { return }
            player.volume = 0.9
            player.prepareToPlay()
            player.play()
            currentVoicePlayer = player
            cleanupFinished()
            activePlayers.append(player)
        }
    }

    /// Play a voice sound and return its duration. Stops any current voice first.
    @discardableResult
    static func playVoiceReturningDuration(_ name: String, volume: Float = 1.0) -> TimeInterval {
        guard !isMuted else { return 0 }
        guard let url = resolveURL(name),
              let player = try? AVAudioPlayer(contentsOf: url) else { return 0 }
        currentVoicePlayer?.stop()
        player.volume = volume
        player.prepareToPlay()
        let duration = player.duration
        player.play()
        currentVoicePlayer = player
        cleanupFinished()
        activePlayers.append(player)
        return duration
    }

    // MARK: - Preload

    /// Preload sounds into cache — resolves URLs and decodes audio data.
    static func preload(_ names: [String]) {
        for name in names {
            guard let url = resolveURL(name),
                  let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.prepareToPlay()
            // prepareToPlay() decodes audio into buffer — first play will be instant
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

        // Try exact path first (e.g. "CharacterPacks/trump/slap_impact")
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
