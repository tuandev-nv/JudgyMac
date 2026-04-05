import AVFoundation

/// Plays sequential snippets of a creak sound each time the lid angle changes by N degrees.
final class CreakAudioEngine {

    private(set) var isRunning = false

    private var soundURL: URL?
    private var soundDuration: TimeInterval = 0
    private var players: [AVAudioPlayer] = []
    private var lastTriggeredAngle = 0.0
    private var isFirstAngle = true
    private var lastAngle = 0.0
    private var lastAngleTime: TimeInterval = 0
    private var playheadPosition: TimeInterval = 0

    /// Degrees of lid change before playing a crack sound.
    private let degreesPerCrack = 2.0
    /// Duration of each crack snippet in seconds.
    private let snippetDuration = 0.2
    /// Max concurrent players.
    private let maxPlayers = 4

    init() {
        let url: URL? = Bundle.main.url(forResource: "CREAK_LOOP", withExtension: "wav")
            ?? Bundle.main.resourceURL?.appendingPathComponent("Sounds/CREAK_LOOP.wav")

        guard let u = url, FileManager.default.fileExists(atPath: u.path) else {
            #if DEBUG
            print("🔊 [Creak] CREAK_LOOP.wav not found in bundle")
            #endif
            return
        }
        soundURL = u

        if let player = try? AVAudioPlayer(contentsOf: u) {
            soundDuration = player.duration
        }
    }

    func start() {
        guard soundURL != nil, soundDuration > snippetDuration else { return }
        isRunning = true
        playheadPosition = 0
        #if DEBUG
        print("🔊 [Creak] Engine started (sequential, \(degreesPerCrack)° per crack)")
        #endif
    }

    func stop() {
        isRunning = false
        isFirstAngle = true
        stopAllSounds()
    }

    /// Feed current lid angle.
    func update(angle: Double) {
        guard isRunning else { return }

        let now = CACurrentMediaTime()

        if isFirstAngle {
            lastTriggeredAngle = angle
            lastAngle = angle
            lastAngleTime = now
            isFirstAngle = false
            return
        }

        let delta = abs(angle - lastTriggeredAngle)
        if delta >= degreesPerCrack {
            let dt = now - lastAngleTime
            let velocity = dt > 0 ? abs(angle - lastAngle) / dt : 0
            lastTriggeredAngle = angle
            playNextSnippet(velocity: velocity)
        }

        lastAngle = angle
        lastAngleTime = now
    }

    func stopAllSounds() {
        for player in players { player.stop() }
        players.removeAll()
    }

    private func playNextSnippet(velocity: Double) {
        guard let url = soundURL else { return }

        // Clean up finished
        players.removeAll { !$0.isPlaying }
        guard players.count < maxPlayers else { return }

        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }

        // Sequential playhead
        player.currentTime = playheadPosition

        // Advance playhead, loop back when reaching end
        playheadPosition += snippetDuration
        if playheadPosition + snippetDuration > soundDuration {
            playheadPosition = 0
        }

        // Volume based on velocity
        let vol = Float(min(1.0, max(0.4, velocity / 40.0)))
        player.volume = vol

        player.play()
        players.append(player)

        // Stop after snippet duration
        let dur = snippetDuration
        let playerRef = player
        Timer.scheduledTimer(withTimeInterval: dur, repeats: false) { _ in
            MainActor.assumeIsolated {
                playerRef.stop()
            }
        }
    }
}
