import SwiftUI

// MARK: - Animation Values

struct SlapImpactValues {
    var offsetX: CGFloat = 0
    var offsetY: CGFloat = 0
    var scaleX: CGFloat = 1.0
    var scaleY: CGFloat = 1.0
    var rotation: Double = 0
    var flash: Double = 0
    // Jiggle — for butt/jelly characters
    var jiggleScaleX: CGFloat = 1.0
    var jiggleScaleY: CGFloat = 1.0
}

// MARK: - Impact Snapshot (for KeyframeAnimator)

struct ImpactSnapshot {
    var dirX: Double = 1
    var dirY: Double = 0
    var power: Double = 1
    var slapAngle: Double = 0
    var jiggleIntensity: CGFloat = 0  // 0 = no jiggle (face), 0.1+ = jelly wobble (butt)
}

// MARK: - Comic Text (floating impact word)

struct ComicText: Identifiable {
    let id = UUID()
    let text: String
    var x: CGFloat
    var y: CGFloat
    let rotation: Double
    let finalScale: CGFloat
    let color: Color
    let hasBurst: Bool
    var scale: CGFloat = 2.5
    var opacity: Double = 1.0
}

// MARK: - Main View

struct SlapAnimationView: View {
    @Bindable var state: SlapState
    let pack: CharacterPack
    let onClose: () -> Void

    @State private var comicTexts: [ComicText] = []
    @State private var appeared = false
    @State private var counterBounce = true
    @State private var impact = ImpactSnapshot()

    @State private var slapSign: Double = 0 // 0 = not chosen yet

    private let faceSize: CGFloat = 500

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // THE FACE
                faceView
                    .frame(width: faceSize, height: faceSize)
                    .scaleEffect(x: persistentDeformX, y: persistentDeformY)
                    // Per-hit keyframe
                    .keyframeAnimator(
                        initialValue: SlapImpactValues(),
                        trigger: state.impactTrigger
                    ) { content, value in
                        content
                            .offset(x: value.offsetX, y: value.offsetY)
                            .scaleEffect(x: value.scaleX * value.jiggleScaleX,
                                         y: value.scaleY * value.jiggleScaleY)
                            .rotationEffect(.degrees(value.rotation), anchor: .bottom)
                            .brightness(value.flash * 0.3)
                    } keyframes: { _ in
                        let p = impact.power
                        let dx = impact.dirX

                        // Slide sideways — FAST
                        KeyframeTrack(\.offsetX) {
                            CubicKeyframe(dx * (15 + p * 10), duration: 0.04)
                            LinearKeyframe(dx * (12 + p * 8), duration: 0.1)
                            SpringKeyframe(0, duration: 0.3, spring: .init(response: 0.25, dampingRatio: 0.6))
                        }
                        KeyframeTrack(\.offsetY) {
                            CubicKeyframe(-3 * p, duration: 0.04)
                            SpringKeyframe(0, duration: 0.25, spring: .init(response: 0.25, dampingRatio: 0.6))
                        }
                        KeyframeTrack(\.scaleX) {
                            CubicKeyframe(1.04 + p * 0.015, duration: 0.04)
                            SpringKeyframe(1.0, duration: 0.2, spring: .init(response: 0.2, dampingRatio: 0.5))
                        }
                        KeyframeTrack(\.scaleY) {
                            CubicKeyframe(0.96 - p * 0.01, duration: 0.04)
                            SpringKeyframe(1.0, duration: 0.2, spring: .init(response: 0.2, dampingRatio: 0.5))
                        }
                        // Tilt — subtle, quick recover
                        KeyframeTrack(\.rotation) {
                            CubicKeyframe(dx * (4 + p * 2), duration: 0.04)
                            LinearKeyframe(dx * (3 + p * 1.5), duration: 0.12)
                            SpringKeyframe(0, duration: 0.25, spring: .init(response: 0.25, dampingRatio: 0.7))
                        }
                        KeyframeTrack(\.flash) {
                            CubicKeyframe(0.6, duration: 0.02)
                            CubicKeyframe(0, duration: 0.15)
                        }
                        // Jiggle — wobble X (squash-stretch alternating)
                        KeyframeTrack(\.jiggleScaleX) {
                            let j = impact.jiggleIntensity
                            CubicKeyframe(1.0 + j, duration: 0.05)
                            CubicKeyframe(1.0 - j * 0.7, duration: 0.08)
                            CubicKeyframe(1.0 + j * 0.5, duration: 0.08)
                            CubicKeyframe(1.0 - j * 0.3, duration: 0.08)
                            SpringKeyframe(1.0, duration: 0.2, spring: .init(response: 0.2, dampingRatio: 0.5))
                        }
                        // Jiggle — wobble Y (inverse of X = jelly effect)
                        KeyframeTrack(\.jiggleScaleY) {
                            let j = impact.jiggleIntensity
                            CubicKeyframe(1.0 - j * 0.8, duration: 0.05)
                            CubicKeyframe(1.0 + j * 0.6, duration: 0.08)
                            CubicKeyframe(1.0 - j * 0.4, duration: 0.08)
                            CubicKeyframe(1.0 + j * 0.2, duration: 0.08)
                            SpringKeyframe(1.0, duration: 0.2, spring: .init(response: 0.2, dampingRatio: 0.5))
                        }
                    }

                // Comic impact text — "OW!", "ARGH!", etc.
                ForEach(comicTexts) { comic in
                    comicTextView(comic)
                }

                // Hit counter
                if state.hitCount > 0 {
                    Text("× \(state.hitCount)")
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundStyle(counterColor)
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                        .shadow(color: .black, radius: 0, x: -1, y: -1)
                        .contentTransition(.numericText())
                        .scaleEffect(counterBounce ? 1 : 2.0)
                        .animation(.spring(duration: 0.2, bounce: 0.4), value: counterBounce)
                        .animation(.spring(duration: 0.15), value: state.hitCount)
                        .offset(y: faceSize * 0.45)
                }
            }
            .frame(width: 700, height: 650)
        }
        .scaleEffect(appeared ? 1 : 0.1)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: appeared)
        .onChange(of: state.impactTrigger) { _, _ in
            onImpact()
        }
        .onAppear { appeared = true }
    }

    // MARK: - Comic Impact Text

    /// Fallback reaction words (pain/voice)
    private static let fallbackWords: [[String]] = [
        ["OW!", "OOF!", "HEY!", "Ê!", "UI!"],
        ["ARGH!", "OUCH!", "STOP!", "ĐAU!", "AHH!"],
        ["MERCY!", "NO MORE!", "TRỜI!", "HELP!", "AAAA!"],
        ["☠️", "💀", "R.I.P", "K.O!", "GG!"],
    ]

    /// Comic impact sounds (shown alongside reaction text)
    private static let impactWords: [String] = [
        "BAM!", "POW!", "WHAM!", "SLAP!", "CRACK!",
        "SMACK!", "WHACK!", "BOP!", "THWACK!", "BONK!",
        "💥BAM!", "💢SNAP!", "⚡ZAP!", "🔥BURN!",
    ]

    private static let comicColors: [Color] = [
        .yellow, .orange, .red, .cyan, .green, .pink, .purple, .mint,
    ]

    @ViewBuilder
    private func comicTextView(_ comic: ComicText) -> some View {
        let fontSize: CGFloat = comic.hasBurst ? 28 : 36
        let burstW = min(CGFloat(comic.text.count) * 24 + 40, 600)
        let burstH: CGFloat = comic.text.count > 25 ? 90 : 65

        return ZStack {
            if comic.hasBurst {
                ComicBurstShape()
                    .fill(comic.color.opacity(0.9))
                    .overlay(
                        ComicBurstShape()
                            .stroke(.black, lineWidth: 3)
                    )
                    .frame(width: burstW, height: burstH)
            }

            ZStack {
                Text(comic.text)
                    .font(.system(size: fontSize, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .offset(x: 2, y: 2)
                Text(comic.text)
                    .font(.system(size: fontSize, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .offset(x: -2, y: -2)
                Text(comic.text)
                    .font(.system(size: fontSize, weight: .black, design: .rounded))
                    .foregroundStyle(comic.hasBurst ? .white : comic.color)
            }
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .frame(maxWidth: burstW - 20)
        }
        .scaleEffect(comic.scale)
        .rotationEffect(.degrees(comic.rotation))
        .offset(x: comic.x, y: comic.y)
        .opacity(comic.opacity)
    }

    // MARK: - Face

    @ViewBuilder
    private var faceView: some View {
        let level = state.deformationLevel
        let name = pack.faceImage(level: level)

        ZStack {
            // Base image
            Group {
                if let img = loadImage(name) {
                    img.resizable().aspectRatio(contentMode: .fit)
                } else if let img = FluentEmoji.swiftUIImage(named: name) {
                    img.resizable().aspectRatio(contentMode: .fit)
                } else {
                    Text("🤨").font(.system(size: 80))
                }
            }
        }
    }

    /// Load image from character folder — cached
    private static let imageCache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 30
        return cache
    }()

    private func loadImage(_ name: String) -> Image? {
        let key = name as NSString
        if let cached = Self.imageCache.object(forKey: key) {
            return Image(nsImage: cached)
        }
        guard let url = Bundle.main.resourceURL?
            .appendingPathComponent("\(name).png"),
              let nsImage = NSImage(contentsOf: url) else { return nil }
        Self.imageCache.setObject(nsImage, forKey: key)
        return Image(nsImage: nsImage)
    }

    // MARK: - Persistent Deformation

    private var persistentDeformX: CGFloat {
        1.0 + CGFloat(state.deformationLevel) * 0.04
    }

    private var persistentDeformY: CGFloat {
        1.0 - CGFloat(state.deformationLevel) * 0.04
    }

    // MARK: - Impact

    private func onImpact() {
        let level = state.deformationLevel
        let power = Double(min(level + 1, 5))
        let hitCount = state.hitCount

        // First hit: pick random direction, keep it forever
        if slapSign == 0 {
            slapSign = Bool.random() ? 1.0 : -1.0
        }

        // Subtle persistent tilt — just enough to show direction, not the main animation
        let tiltAngle = slapSign * min(2 + 1.5 * sqrt(Double(hitCount)), 15)

        // Jiggle intensity: butt = lots of wobble, face = none
        let jiggle: CGFloat = pack.animationStyle == .jiggle
            ? CGFloat(0.06 + power * 0.03)
            : 0

        impact = ImpactSnapshot(
            dirX: slapSign,
            dirY: Double.random(in: -0.3...0.1),
            power: power,
            slapAngle: tiltAngle,
            jiggleIntensity: jiggle
        )

        // Counter slam-in bounce
        counterBounce = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            counterBounce = true
        }

        // Comic text
        addComicText(level: level)
    }

    // MARK: - Comic Text Spawn

    private func addComicText(level: Int) {
        // If reaction text set (with voice) → always use it to stay synced
        // Otherwise random impact word
        let word: String
        if let reactionText = state.currentReactionText {
            word = reactionText
        } else if Bool.random() {
            word = Self.impactWords.randomElement()!
        } else {
            let idx = min(level, Self.fallbackWords.count - 1)
            word = Self.fallbackWords[idx].randomElement()!
        }

        // Random: with burst border (70%) or plain text (30%)
        let withBurst = Double.random(in: 0...1) < 0.7

        spawnComic(
            text: word,
            x: CGFloat.random(in: -80...80),
            y: CGFloat.random(in: -120 ... -30),
            rotation: Double.random(in: -20...20),
            scale: CGFloat.random(in: 0.8...1.2),
            color: Self.comicColors.randomElement()!,
            hasBurst: withBurst
        )
    }

    private func spawnComic(text: String, x: CGFloat, y: CGFloat, rotation: Double, scale: CGFloat, color: Color, hasBurst: Bool = true) {
        // Cap comic texts to prevent memory buildup during rapid slaps
        if comicTexts.count > 6 {
            comicTexts.removeFirst(comicTexts.count - 6)
        }

        let comic = ComicText(
            text: text,
            x: x,
            y: y,
            rotation: rotation,
            finalScale: scale,
            color: color,
            hasBurst: hasBurst,
            scale: 2.5
        )
        comicTexts.append(comic)
        let comicId = comic.id

        // SLAM IN
        withAnimation(.spring(response: 0.08, dampingFraction: 0.5)) {
            if let idx = comicTexts.firstIndex(where: { $0.id == comicId }) {
                comicTexts[idx].scale = comicTexts[idx].finalScale
            }
        }

        // Hold, then drift + fade
        let hold = Constants.Slap.comicHoldSeconds
        let fade = Constants.Slap.comicFadeSeconds
        let lifetime = Constants.Slap.comicLifetimeSeconds

        withAnimation(.easeOut(duration: fade).delay(hold)) {
            if let idx = comicTexts.firstIndex(where: { $0.id == comicId }) {
                comicTexts[idx].y -= 30
                comicTexts[idx].opacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + lifetime) {
            comicTexts.removeAll { $0.id == comicId }
        }
    }

    // MARK: - Counter

    private var counterColor: Color {
        switch state.hitCount {
        case 1...3:   return .yellow
        case 4...7:   return .orange
        case 8...15:  return .red
        case 16...25: return .pink
        case 26...35: return .purple
        case 36...45: return .cyan
        default:      return Color(hue: Double(state.hitCount % 50) / 50.0, saturation: 1, brightness: 1)
        }
    }
}

// MARK: - Models

// MARK: - Comic Burst Shape (spiky explosion border)

struct ComicBurstShape: Shape {
    var spikes: Int = 12
    var innerRatio: CGFloat = 0.7

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadiusX = rect.width / 2
        let outerRadiusY = rect.height / 2
        let innerRadiusX = outerRadiusX * innerRatio
        let innerRadiusY = outerRadiusY * innerRatio
        let angleStep = .pi / Double(spikes)

        var path = Path()
        for i in 0..<(spikes * 2) {
            let angle = Double(i) * angleStep - .pi / 2
            let isOuter = i.isMultiple(of: 2)
            let rx = isOuter ? outerRadiusX : innerRadiusX
            let ry = isOuter ? outerRadiusY : innerRadiusY
            let point = CGPoint(
                x: center.x + cos(angle) * rx,
                y: center.y + sin(angle) * ry
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}
