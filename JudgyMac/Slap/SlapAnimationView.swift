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
    let character: SlapCharacter
    let onClose: () -> Void

    @State private var slapMarks: [SlapMark] = []
    @State private var comicTexts: [ComicText] = []
    @State private var appeared = false
    @State private var impact = ImpactSnapshot()

    @State private var slapSign: Double = 0 // 0 = not chosen yet

    private let faceSize: CGFloat = 280

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
                        // Tilt — snap, brief stun, fast recover
                        KeyframeTrack(\.rotation) {
                            CubicKeyframe(dx * (10 + p * 5), duration: 0.04)
                            LinearKeyframe(dx * (8 + p * 4), duration: 0.12)
                            SpringKeyframe(0, duration: 0.25, spring: .init(response: 0.25, dampingRatio: 0.6))
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

                // Slap marks
                ForEach(slapMarks) { mark in
                    Text("👋")
                        .font(.system(size: 26 * mark.scale))
                        .rotationEffect(.degrees(mark.rotation))
                        .offset(x: mark.x, y: mark.y)
                        .opacity(mark.opacity)
                }

                // Comic impact text — "OW!", "ARGH!", etc.
                ForEach(comicTexts) { comic in
                    comicTextView(comic)
                }

                // Stars at level 3+
                if state.deformationLevel >= 3 {
                    starsView
                }

                // Hit counter — overlaid near bottom of face
                if state.hitCount > 0 {
                    Text("× \(state.hitCount)")
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundStyle(counterColor)
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                        .shadow(color: .black, radius: 0, x: -1, y: -1)
                        .contentTransition(.numericText())
                        .animation(.spring(duration: 0.15), value: state.hitCount)
                        .offset(y: faceSize * 0.45)
                }
            }
            .frame(width: 550, height: 520)
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
        ZStack {
            if comic.hasBurst {
                // Explosion burst background
                ComicBurstShape()
                    .fill(comic.color.opacity(0.9))
                    .overlay(
                        ComicBurstShape()
                            .stroke(.black, lineWidth: 3)
                    )
                    .frame(
                        width: CGFloat(comic.text.count) * 24 + 40,
                        height: 65
                    )
            }

            // Text with outline
            ZStack {
                Text(comic.text)
                    .font(.system(size: comic.hasBurst ? 28 : 36, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .offset(x: 2, y: 2)
                Text(comic.text)
                    .font(.system(size: comic.hasBurst ? 28 : 36, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .offset(x: -2, y: -2)
                Text(comic.text)
                    .font(.system(size: comic.hasBurst ? 28 : 36, weight: .black, design: .rounded))
                    .foregroundStyle(comic.hasBurst ? .white : comic.color)
            }
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
        let name = character.faceImage(level: level)

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
            // Progressive red tint — more hits = redder face
            .colorMultiply(damageColor)

            // Damage overlays (code-generated, no extra images needed)
            damageOverlays
        }
    }

    /// Progressive red tint
    private var damageColor: Color {
        let level = state.deformationLevel
        switch level {
        case 0: return .white                           // No tint
        case 1: return Color(red: 1, green: 0.95, blue: 0.95) // Slight pink
        case 2: return Color(red: 1, green: 0.85, blue: 0.85) // Pink
        case 3: return Color(red: 1, green: 0.75, blue: 0.75) // Red-ish
        default: return Color(red: 1, green: 0.65, blue: 0.65) // Very red
        }
    }

    /// Sweat, tears, bandaids — overlaid by code
    @ViewBuilder
    private var damageOverlays: some View {
        let level = state.deformationLevel
        if level >= 1 {
            // Sweat drop
            Text("💧")
                .font(.system(size: 20))
                .offset(x: faceSize * 0.3, y: -faceSize * 0.2)
        }
        if level >= 2 {
            // Tears
            Text("😢")
                .font(.system(size: 16))
                .offset(x: -faceSize * 0.25, y: faceSize * 0.05)
                .opacity(0.7)
        }
        if level >= 3 {
            // Bandaid
            Text("🩹")
                .font(.system(size: 24))
                .rotationEffect(.degrees(-20))
                .offset(x: faceSize * 0.2, y: faceSize * 0.1)
        }
        if level >= 4 {
            // Dizzy
            Text("💫")
                .font(.system(size: 20))
                .offset(x: 0, y: -faceSize * 0.35)
        }
    }

    /// Load image from character folder — cached
    private static let imageCache = NSCache<NSString, NSImage>()

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
        let jiggle: CGFloat = character.animationStyle == .jiggle
            ? CGFloat(0.06 + power * 0.03)
            : 0

        impact = ImpactSnapshot(
            dirX: slapSign,
            dirY: Double.random(in: -0.3...0.1),
            power: power,
            slapAngle: tiltAngle,
            jiggleIntensity: jiggle
        )

        // Slap mark
        let mark = SlapMark(
            x: CGFloat.random(in: -50...50),
            y: CGFloat.random(in: -50...50),
            rotation: Double.random(in: -50...50),
            scale: CGFloat.random(in: 0.6...1.0),
            opacity: min(0.35 + Double(level) * 0.1, 0.7)
        )
        slapMarks.append(mark)
        if slapMarks.count > 8 { slapMarks.removeFirst() }

        // Comic text
        addComicText(level: level)
    }

    // MARK: - Comic Text Spawn

    private func addComicText(level: Int) {
        // Pick ONE word — either impact sound or reaction (random)
        let word: String
        let useImpact = Bool.random()

        if useImpact {
            word = Self.impactWords.randomElement()!
        } else if let reaction = character.reaction(forHitCount: state.hitCount) {
            word = reaction.texts.randomElement() ?? "OW!"
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

        // Drift + fade
        withAnimation(.easeOut(duration: 0.25).delay(0.08)) {
            if let idx = comicTexts.firstIndex(where: { $0.id == comicId }) {
                comicTexts[idx].y -= 20
                comicTexts[idx].opacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            comicTexts.removeAll { $0.id == comicId }
        }
    }

    // MARK: - Stars

    private var starsView: some View {
        let emojis = ["⭐", "💫", "✨", "💥"]
        return ForEach(0..<3, id: \.self) { i in
            let baseAngle = Double(i) * 120 + Double(state.impactTrigger * 40)
            let radius: CGFloat = 90
            Text(emojis[i % emojis.count])
                .font(.system(size: 18))
                .offset(
                    x: cos(baseAngle * .pi / 180) * radius,
                    y: sin(baseAngle * .pi / 180) * radius
                )
                .animation(.spring(duration: 0.3), value: state.impactTrigger)
        }
    }

    // MARK: - Counter

    private var counterColor: Color {
        let tier = state.hitCount / 10
        switch tier {
        case 0: return .white
        case 1: return .yellow
        case 2: return .orange
        case 3: return .red
        case 4: return .pink
        case 5: return .purple
        case 6: return .cyan
        case 7: return .mint
        default: return Color(hue: Double(tier % 10) / 10.0, saturation: 1, brightness: 1)
        }
    }
}

// MARK: - Models

struct SlapMark: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let scale: CGFloat
    let opacity: Double
}

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
