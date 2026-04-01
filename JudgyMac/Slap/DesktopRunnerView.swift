import SwiftUI

// MARK: - Runner Phase

enum RunnerPhase: Equatable {
    case falling
    case running
    case stopped
    case exiting
    case done
}

// MARK: - Desktop Runner View

struct DesktopRunnerView: View {
    let pack: CharacterPack
    let screenSize: CGSize
    let onFinished: () -> Void

    @State private var phase: RunnerPhase = .falling
    @State private var x: CGFloat = 0
    @State private var y: CGFloat = 0
    @State private var velocityY: CGFloat = 0
    @State private var velocityX: CGFloat = 0  // Slight horizontal drift when falling
    @State private var rotation: Double = 0
    @State private var rotationSpeed: Double = 0
    @State private var direction: CGFloat = 1
    @State private var frame: Int = 0
    @State private var frameTick: Int = 0
    @State private var quote: String?
    @State private var quoteOpacity: Double = 0
    @State private var timer: Timer?
    @State private var runStartTime: Date?
    @State private var runDuration: TimeInterval = 0
    @State private var squash: CGFloat = 1.0
    @State private var cachedFrames: [Image] = []

    private let spriteSize: CGFloat = 120
    private let gravity: CGFloat = 600      // Slower fall — more dramatic
    private let runSpeed: CGFloat = 150
    private let fps: TimeInterval = 1.0 / 60.0
    private let frameEveryNTicks: Int = 10  // ~6fps sprite, smooth movement at 60fps

    /// All reaction lines from the pack (text + voice paired)
    private var allReactionLines: [CharacterPack.ReactionLine] {
        pack.reactions.flatMap(\.lines)
    }

    var body: some View {
        ZStack {
            trumpSprite
                .frame(width: spriteSize, height: spriteSize)
                .scaleEffect(x: direction * (phase == .falling ? 1 : squash),
                             y: phase == .falling ? 1 : (2 - squash))
                .rotationEffect(.degrees(rotation))
                .position(x: x, y: y)

            if let quote, quoteOpacity > 0 {
                speechBubble(text: quote)
                    .position(x: x, y: y - spriteSize * 0.8)
                    .opacity(quoteOpacity)
            }
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .onAppear {
            preloadFrames()
            startFalling()
        }
        .onDisappear { timer?.invalidate() }
    }

    // MARK: - Preload & Sprite

    private func preloadFrames() {
        guard cachedFrames.isEmpty else { return }
        // Load all available frames dynamically
        var i = 0
        while true {
            let name = "\(pack.folderPath)/menubar_frames/frame_\(String(format: "%02d", i))"
            guard let url = Bundle.main.resourceURL?.appendingPathComponent("\(name).png"),
                  let nsImage = NSImage(contentsOf: url) else { break }
            cachedFrames.append(Image(nsImage: nsImage))
            i += 1
        }
    }

    @ViewBuilder
    private var trumpSprite: some View {
        if frame < cachedFrames.count {
            cachedFrames[frame]
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
        } else {
            Text("🏃").font(.system(size: 60))
        }
    }

    // MARK: - Speech Bubble

    private func speechBubble(text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            )
            .fixedSize()
    }

    // MARK: - Falling Phase

    private func startFalling() {
        x = CGFloat.random(in: screenSize.width * 0.2 ... screenSize.width * 0.8)
        y = -spriteSize
        velocityY = 0
        velocityX = CGFloat.random(in: -30...30)  // Slight drift
        rotation = 0
        rotationSpeed = Double.random(in: 200...400) * (Bool.random() ? 1 : -1) // Spin direction
        direction = Bool.random() ? 1 : -1

        let groundY = CGFloat.random(in: screenSize.height * 0.5 ... screenSize.height * 0.85)
        runDuration = Double.random(in: 3...5)

        timer = Timer.scheduledTimer(withTimeInterval: fps, repeats: true) { _ in
            MainActor.assumeIsolated { [self] in
                switch phase {
                case .falling:
                    tickFalling(groundY: groundY)
                case .running:
                    tickRunning()
                case .stopped:
                    break
                case .exiting:
                    tickExiting()
                case .done:
                    timer?.invalidate()
                    timer = nil
                    onFinished()
                }
            }
        }
    }

    // MARK: - Tick Functions

    private func tickFalling(groundY: CGFloat) {
        velocityY += gravity * fps
        y += velocityY * fps
        x += velocityX * fps
        rotation += rotationSpeed * fps

        // Approaching ground — slow rotation
        let distToGround = groundY - y
        if distToGround < 100 {
            rotationSpeed *= 0.95
        }

        if y >= groundY {
            y = groundY
            rotation = 0
            phase = .running
            runStartTime = Date()
            frame = 0
            frameTick = 0

            // Landing squash
            squash = 1.3
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                squash = 1.0
            }
        }
    }

    private func tickRunning() {
        x += direction * runSpeed * fps

        // Sprite frame advance
        frameTick += 1
        let frameCount = max(cachedFrames.count, 1)
        if frameTick >= frameEveryNTicks {
            frameTick = 0
            frame = (frame + 1) % frameCount
        }


        // Bounce off edges
        if x <= spriteSize / 2 {
            direction = 1
        } else if x >= screenSize.width - spriteSize / 2 {
            direction = -1
        }

        // After run duration: stop and talk
        if let start = runStartTime,
           Date().timeIntervalSince(start) >= runDuration {
            stopAndTalk()
        }
    }

    private func tickExiting() {
        x += direction * runSpeed * 1.5 * fps
        frameTick += 1
        if frameTick >= frameEveryNTicks {
            frameTick = 0
            frame = (frame + 1) % max(cachedFrames.count, 1)
        }
        if x <= -spriteSize || x >= screenSize.width + spriteSize {
            phase = .done
        }
    }

    // MARK: - Stop and Talk

    private func stopAndTalk() {
        phase = .stopped
        squash = 1.0

        guard let line = allReactionLines.randomElement() else {
            phase = .exiting
            return
        }

        quote = line.text
        if let voicePath = line.voicePath {
            SoundPlayer.play(voicePath, volume: 0.9)
        }

        withAnimation(.easeIn(duration: 0.3)) {
            quoteOpacity = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                quoteOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                phase = .exiting
            }
        }
    }
}
