@preconcurrency import AppKit
import SwiftUI

/// Dark glass floating toast with bubble-pop animation + rainbow glow border.
@MainActor
final class ToastWindow {
    private var window: NSPanel?
    private var dismissTask: Task<Void, Never>?
    private var isHovered = false
    private var glowBorderLayer: CALayer?

    /// Extra space: glow rendering + entrance animation headroom
    private let glowInset: CGFloat = 60
    private let toastWidth: CGFloat = 420
    private let cornerRadius: CGFloat = 22

    static let shared = ToastWindow()
    private init() {}

    private func clearSubviewBackgrounds(_ view: NSView) {
        view.wantsLayer = true
        view.layer?.backgroundColor = .clear
        view.layer?.isOpaque = false
        for sub in view.subviews { clearSubviewBackgrounds(sub) }
    }

    func show(roast: RoastEntry) {
        dismiss()

        let revealState = ContentRevealState()
        let toastView = ToastView(
            roast: roast,
            revealState: revealState,
            onClose: { [weak self] in self?.dismiss() },
            onHover: { [weak self] hovering in self?.isHovered = hovering }
        )

        let hostingView = NSHostingView(rootView: toastView)
        hostingView.wantsLayer = true

        let fittingSize = hostingView.fittingSize
        let toastHeight = fittingSize.height

        let topInset: CGFloat = 6  // Minimal top gap
        let panelWidth = toastWidth + glowInset * 2
        let panelHeight = toastHeight + topInset + glowInset

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = false

        let container = NSView(frame: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight))
        container.wantsLayer = true
        container.layer?.backgroundColor = .clear
        panel.contentView = container

        let toastFrame = NSRect(x: glowInset, y: glowInset, width: toastWidth, height: toastHeight)

        // Hosting view
        hostingView.frame = toastFrame
        hostingView.layer?.backgroundColor = NSColor(white: 0.06, alpha: 1).cgColor
        hostingView.layer?.isOpaque = false

        let mask = CAShapeLayer()
        mask.path = CGPath(
            roundedRect: CGRect(x: 0, y: 0, width: toastWidth, height: toastHeight),
            cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil
        )
        hostingView.layer?.mask = mask

        // Walk all subviews and force clear backgrounds to prevent gray flash
        Task { @MainActor in
            clearSubviewBackgrounds(hostingView)
        }

        container.addSubview(hostingView)

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - panelWidth / 2
            // Toast hugs top — just below menu bar
            let y = screenFrame.maxY - panelHeight
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        window = panel
        panel.alphaValue = 0
        panel.orderFrontRegardless()

        runEntrance(panel: panel, revealState: revealState,
                    toastRect: hostingView.frame)
        startDismissCountdown()
    }

    // MARK: - Entrance Styles

    private enum EntranceStyle: CaseIterable {
        case center, fromLeft, fromRight, fromTop
    }

    private func runEntrance(panel: NSPanel, revealState: ContentRevealState,
                             toastRect: CGRect) {
        guard let container = panel.contentView, let layer = container.layer else { return }
        layer.masksToBounds = false

        let bounds = container.bounds
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.position = CGPoint(x: bounds.midX, y: bounds.midY)

        let style = EntranceStyle.allCases.randomElement() ?? .center
        panel.alphaValue = 1

        switch style {
        case .center:    animateCenter(layer: layer)
        case .fromLeft:  animateSlide(layer: layer, bounds: bounds, fromRight: false)
        case .fromRight: animateSlide(layer: layer, bounds: bounds, fromRight: true)
        case .fromTop:   animateDrop(layer: layer, bounds: bounds)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { revealState.showEmoji() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { revealState.showText() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { revealState.showMeta() }

        // Rainbow glow border — almost immediate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { @MainActor [weak self] in
            guard let self else { return }
            self.addRainbowGlow(to: layer, toastRect: toastRect)
        }

        // Shimmer sweep
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { @MainActor [weak self] in
            guard let self else { return }
            self.addShimmerSweep(to: layer, toastRect: toastRect)
        }
    }

    // MARK: - Center Pop

    private func animateCenter(layer: CALayer) {
        layer.transform = CATransform3DMakeScale(0.01, 0.01, 1)
        let scale = CASpringAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.01; scale.toValue = 1.0
        scale.mass = 0.6; scale.stiffness = 280; scale.damping = 10; scale.initialVelocity = 25
        scale.duration = scale.settlingDuration
        scale.fillMode = .forwards; scale.isRemovedOnCompletion = false
        let group = CAAnimationGroup()
        group.animations = [scale, makeWobble(delay: 0.15)]
        group.duration = max(scale.settlingDuration, 0.8)
        group.fillMode = .forwards; group.isRemovedOnCompletion = false
        commitEntrance(group, to: layer)
    }

    // MARK: - Slide Left/Right

    private func animateSlide(layer: CALayer, bounds: CGRect, fromRight: Bool) {
        let offX: CGFloat = fromRight ? bounds.width * 1.2 : -bounds.width * 1.2
        layer.transform = CATransform3DConcat(
            CATransform3DMakeScale(0.6, 0.6, 1),
            CATransform3DMakeTranslation(offX, 0, 0)
        )
        let slide = CASpringAnimation(keyPath: "transform.translation.x")
        slide.fromValue = offX; slide.toValue = 0
        slide.mass = 0.7; slide.stiffness = 220; slide.damping = 12; slide.initialVelocity = 20
        slide.duration = slide.settlingDuration
        slide.fillMode = .forwards; slide.isRemovedOnCompletion = false
        let scale = CASpringAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.6; scale.toValue = 1.0
        scale.mass = 0.6; scale.stiffness = 250; scale.damping = 11; scale.initialVelocity = 18
        scale.duration = scale.settlingDuration
        scale.fillMode = .forwards; scale.isRemovedOnCompletion = false
        let tilt = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        let d: Double = fromRight ? -1 : 1
        tilt.values = [0.10 * d, -0.06 * d, 0.03 * d, 0]
        tilt.keyTimes = [0, 0.35, 0.65, 1.0]; tilt.duration = 0.5
        tilt.beginTime = CACurrentMediaTime() + 0.08
        tilt.fillMode = .forwards; tilt.isRemovedOnCompletion = false
        let group = CAAnimationGroup()
        group.animations = [slide, scale, tilt]
        group.duration = max(slide.settlingDuration, scale.settlingDuration)
        group.fillMode = .forwards; group.isRemovedOnCompletion = false
        commitEntrance(group, to: layer)
    }

    // MARK: - Drop from Top

    private func animateDrop(layer: CALayer, bounds: CGRect) {
        let drop: CGFloat = bounds.height * 1.5
        layer.transform = CATransform3DConcat(
            CATransform3DMakeScale(0.5, 0.5, 1),
            CATransform3DMakeTranslation(0, drop, 0)
        )
        let slideY = CASpringAnimation(keyPath: "transform.translation.y")
        slideY.fromValue = drop; slideY.toValue = 0
        slideY.mass = 0.7; slideY.stiffness = 240; slideY.damping = 11; slideY.initialVelocity = 22
        slideY.duration = slideY.settlingDuration
        slideY.fillMode = .forwards; slideY.isRemovedOnCompletion = false
        let scale = CASpringAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.5; scale.toValue = 1.0
        scale.mass = 0.6; scale.stiffness = 250; scale.damping = 10; scale.initialVelocity = 18
        scale.duration = scale.settlingDuration
        scale.fillMode = .forwards; scale.isRemovedOnCompletion = false
        let group = CAAnimationGroup()
        group.animations = [slideY, scale, makeWobble(delay: 0.12)]
        group.duration = max(slideY.settlingDuration, scale.settlingDuration)
        group.fillMode = .forwards; group.isRemovedOnCompletion = false
        commitEntrance(group, to: layer)
    }

    private func makeWobble(delay: Double) -> CAKeyframeAnimation {
        let w = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        w.values = [0, 0.07, -0.05, 0.03, -0.015, 0.007, 0]
        w.keyTimes = [0, 0.15, 0.3, 0.5, 0.7, 0.85, 1.0]
        w.duration = 0.6; w.beginTime = CACurrentMediaTime() + delay
        w.fillMode = .forwards; w.isRemovedOnCompletion = false
        return w
    }

    private func commitEntrance(_ anim: CAAnimationGroup, to layer: CALayer) {
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            layer.transform = CATransform3DIdentity
            layer.removeAllAnimations()
        }
        layer.add(anim, forKey: "entrance")
        CATransaction.commit()
    }

    // MARK: - Rainbow Glow Border

    /// Architecture: mask on CONTAINER (fixed), gradient rotates freely inside.
    /// This prevents the mask from spinning with the gradient.
    private func addRainbowGlow(to parentLayer: CALayer, toastRect: CGRect) {
        let containerBounds = parentLayer.bounds
        let borderRect = toastRect.insetBy(dx: 0.5, dy: 0.5)
        let borderPath = CGPath(roundedRect: borderRect,
                                cornerWidth: cornerRadius, cornerHeight: cornerRadius,
                                transform: nil)

        let rainbow: [Any] = [
            NSColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1).cgColor,
            NSColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1).cgColor,
            NSColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1).cgColor,
            NSColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1).cgColor,
            NSColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1).cgColor,
            NSColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1).cgColor,
            NSColor(red: 0.5, green: 0.0, blue: 1.0, alpha: 1).cgColor,
            NSColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1).cgColor,
            NSColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1).cgColor,
        ]

        // Rotation animation (shared)
        let spin = CABasicAnimation(keyPath: "transform.rotation.z")
        spin.fromValue = 0; spin.toValue = Double.pi * 2
        spin.duration = 2.5; spin.repeatCount = .infinity
        spin.timingFunction = CAMediaTimingFunction(name: .linear)

        // Large square gradient centered on toast — rotates around its own center
        let side = max(containerBounds.width, containerBounds.height) * 2

        func makeSpinningGradient() -> CAGradientLayer {
            let grad = CAGradientLayer()
            grad.type = .conic
            grad.frame = CGRect(
                x: borderRect.midX - side / 2,
                y: borderRect.midY - side / 2,
                width: side, height: side
            )
            grad.colors = rainbow
            grad.startPoint = CGPoint(x: 0.5, y: 0.5)
            grad.endPoint = CGPoint(x: 0.5, y: 0)
            // anchorPoint = (0.5, 0.5) by default → rotates around gradient center = toast center
            grad.add(spin, forKey: "spin")
            return grad
        }

        // --- Layer 1: Vivid glow (shadow-based, no CIFilter) ---
        let bigClip = CALayer()
        bigClip.frame = containerBounds
        let bigMask = CAShapeLayer()
        bigMask.path = borderPath
        bigMask.fillColor = .clear
        bigMask.strokeColor = NSColor.white.cgColor
        bigMask.lineWidth = 4
        bigClip.mask = bigMask
        bigClip.addSublayer(makeSpinningGradient())
        bigClip.opacity = 0.35
        bigClip.shadowColor = NSColor.white.cgColor
        bigClip.shadowRadius = 12
        bigClip.shadowOpacity = 0.7
        bigClip.shadowOffset = .zero

        // --- Layer 2: Thin sharp border ---
        let sharpClip = CALayer()
        sharpClip.frame = containerBounds
        let sharpMask = CAShapeLayer()
        sharpMask.path = borderPath
        sharpMask.fillColor = .clear
        sharpMask.strokeColor = NSColor.white.cgColor
        sharpMask.lineWidth = 1.0
        sharpClip.mask = sharpMask
        sharpClip.addSublayer(makeSpinningGradient())

        // --- Assemble ---
        let glowContainer = CALayer()
        glowContainer.frame = containerBounds
        glowContainer.masksToBounds = false
        glowContainer.addSublayer(bigClip)
        glowContainer.addSublayer(sharpClip)

        parentLayer.addSublayer(glowContainer)
        glowBorderLayer = glowContainer

        // Pulsing (voice-ready)
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 0.65; pulse.toValue = 1.0
        pulse.duration = 1.2; pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glowContainer.add(pulse, forKey: "pulse")

        // Fade in
        glowContainer.opacity = 0
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0; fade.toValue = 0.85; fade.duration = 0.6
        fade.fillMode = .forwards; fade.isRemovedOnCompletion = false
        glowContainer.add(fade, forKey: "fadeIn")
    }

    // MARK: - Shimmer Sweep

    private enum ShimmerDirection: CaseIterable {
        case leftToRight, rightToLeft, topToBottom, bottomToTop
    }

    /// Two random-direction shimmer passes with varying pause.
    private func addShimmerSweep(to parentLayer: CALayer, toastRect: CGRect) {
        let clipMask = CAShapeLayer()
        clipMask.path = CGPath(roundedRect: toastRect,
                               cornerWidth: cornerRadius, cornerHeight: cornerRadius,
                               transform: nil)

        let shimmerContainer = CALayer()
        shimmerContainer.frame = parentLayer.bounds
        shimmerContainer.mask = clipMask
        parentLayer.addSublayer(shimmerContainer)

        // Pick 2 random non-repeating directions
        let dirs = ShimmerDirection.allCases.shuffled()
        let dir1 = dirs[0]
        let dir2 = dirs[1]

        runShimmerPass(in: shimmerContainer, toastRect: toastRect, direction: dir1) {
            let pause = Double.random(in: 0.8...1.5)
            DispatchQueue.main.asyncAfter(deadline: .now() + pause) { @MainActor in
                self.runShimmerPass(in: shimmerContainer, toastRect: toastRect, direction: dir2) {
                    shimmerContainer.removeFromSuperlayer()
                }
            }
        }
    }

    private func runShimmerPass(in container: CALayer, toastRect: CGRect,
                                direction: ShimmerDirection, completion: @escaping () -> Void) {
        let isHorizontal = (direction == .leftToRight || direction == .rightToLeft)
        let shimmerThickness = isHorizontal ? toastRect.width * 0.35 : toastRect.height * 0.5

        let shimmer = CAGradientLayer()
        shimmer.colors = [
            NSColor.clear.cgColor,
            NSColor.white.withAlphaComponent(0.05).cgColor,
            NSColor.white.withAlphaComponent(0.12).cgColor,
            NSColor.white.withAlphaComponent(0.05).cgColor,
            NSColor.clear.cgColor,
        ]
        shimmer.locations = [0, 0.3, 0.5, 0.7, 1.0]

        let keyPath: String
        let fromValue: CGFloat
        let toValue: CGFloat

        switch direction {
        case .leftToRight:
            shimmer.startPoint = CGPoint(x: 0, y: 0.3)
            shimmer.endPoint = CGPoint(x: 1, y: 0.7)
            shimmer.frame = CGRect(x: 0, y: toastRect.minY,
                                   width: shimmerThickness, height: toastRect.height)
            keyPath = "position.x"
            fromValue = toastRect.minX - shimmerThickness / 2
            toValue = toastRect.maxX + shimmerThickness / 2

        case .rightToLeft:
            shimmer.startPoint = CGPoint(x: 1, y: 0.3)
            shimmer.endPoint = CGPoint(x: 0, y: 0.7)
            shimmer.frame = CGRect(x: 0, y: toastRect.minY,
                                   width: shimmerThickness, height: toastRect.height)
            keyPath = "position.x"
            fromValue = toastRect.maxX + shimmerThickness / 2
            toValue = toastRect.minX - shimmerThickness / 2

        case .topToBottom:
            shimmer.startPoint = CGPoint(x: 0.3, y: 0)
            shimmer.endPoint = CGPoint(x: 0.7, y: 1)
            shimmer.frame = CGRect(x: toastRect.minX, y: 0,
                                   width: toastRect.width, height: shimmerThickness)
            keyPath = "position.y"
            fromValue = toastRect.maxY + shimmerThickness / 2
            toValue = toastRect.minY - shimmerThickness / 2

        case .bottomToTop:
            shimmer.startPoint = CGPoint(x: 0.3, y: 1)
            shimmer.endPoint = CGPoint(x: 0.7, y: 0)
            shimmer.frame = CGRect(x: toastRect.minX, y: 0,
                                   width: toastRect.width, height: shimmerThickness)
            keyPath = "position.y"
            fromValue = toastRect.minY - shimmerThickness / 2
            toValue = toastRect.maxY + shimmerThickness / 2
        }

        container.addSublayer(shimmer)

        let slide = CABasicAnimation(keyPath: keyPath)
        slide.fromValue = fromValue
        slide.toValue = toValue
        slide.duration = Double.random(in: 1.2...1.8)
        slide.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        slide.fillMode = .forwards
        slide.isRemovedOnCompletion = false

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            shimmer.removeFromSuperlayer()
            completion()
        }
        shimmer.add(slide, forKey: "sweep")
        CATransaction.commit()
    }

    // MARK: - Dismiss

    private func startDismissCountdown() {
        dismissTask = Task {
            var remaining: Double = 10
            while remaining > 0 {
                try? await Task.sleep(for: .milliseconds(500))
                if !isHovered { remaining -= 0.5 }
            }
            dismiss()
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        guard let panel = window else { return }

        // Stop all glow animations immediately to free GPU
        stopGlowAnimations()

        guard let layer = panel.contentView?.layer else {
            panel.orderOut(nil); window = nil; return
        }

        // Stop any entrance animation that might conflict with shrink
        layer.removeAnimation(forKey: "entrance")

        CATransaction.begin()
        CATransaction.setCompletionBlock { @MainActor [weak self] in
            self?.glowBorderLayer?.removeFromSuperlayer()
            self?.glowBorderLayer = nil
            panel.orderOut(nil)
            self?.window = nil
        }

        let shrink = CASpringAnimation(keyPath: "transform.scale")
        shrink.fromValue = 1.0; shrink.toValue = 0.15
        shrink.mass = 1.0; shrink.stiffness = 350; shrink.damping = 20
        shrink.duration = 0.3; shrink.fillMode = .forwards; shrink.isRemovedOnCompletion = false
        layer.add(shrink, forKey: "shrink")

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }
        CATransaction.commit()
    }

    /// Recursively stop all animations on glow layers to free GPU before dismiss.
    private func stopGlowAnimations() {
        func removeAll(_ layer: CALayer) {
            layer.removeAllAnimations()
            layer.sublayers?.forEach { removeAll($0) }
        }
        if let glow = glowBorderLayer { removeAll(glow) }
    }
}

// MARK: - Content Reveal (Notification bridge)

@MainActor
private final class ContentRevealState {
    static let emojiNotification = Notification.Name("ToastRevealEmoji")
    static let textNotification = Notification.Name("ToastRevealText")
    static let metaNotification = Notification.Name("ToastRevealMeta")

    func showEmoji() { NotificationCenter.default.post(name: Self.emojiNotification, object: nil) }
    func showText()  { NotificationCenter.default.post(name: Self.textNotification, object: nil) }
    func showMeta()  { NotificationCenter.default.post(name: Self.metaNotification, object: nil) }
}

// MARK: - Toast View

private struct ToastView: View {
    let roast: RoastEntry
    let revealState: ContentRevealState
    let onClose: () -> Void
    let onHover: (Bool) -> Void

    @State private var emojiVisible = false
    @State private var textVisible = false
    @State private var metaVisible = false
    @State private var isHovering = false

    private var moodColor: Color {
        switch roast.mood {
        case .judging:   return Color(red: 1, green: 0.18, blue: 0.47)
        case .horrified: return Color(red: 0, green: 0.83, blue: 1)
        case .raging:    return Color(red: 1, green: 0.27, blue: 0.27)
        case .sleeping:  return Color(red: 0.55, green: 0.5, blue: 0.78)
        case .impressed: return Color(red: 0, green: 0.9, blue: 0.63)
        case .neutral:   return Color(red: 0.61, green: 0.35, blue: 1)
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .top, spacing: 16) {
                fluentEmojiView
                    .frame(width: 72, height: 72)
                    .scaleEffect(emojiVisible ? 1 : 0.01)
                    .rotationEffect(.degrees(emojiVisible ? 0 : -30))
                    .opacity(emojiVisible ? 1 : 0)
                    .keyframeAnimator(
                        initialValue: EmojiBounce(),
                        trigger: emojiVisible
                    ) { content, value in
                        content
                            .offset(y: value.offsetY)
                            .rotationEffect(.degrees(value.rotation))
                    } keyframes: { _ in
                        KeyframeTrack(\.offsetY) {
                            // 3s wobble — "talking" bounce
                            SpringKeyframe(-4, duration: 0.25, spring: .bouncy)
                            SpringKeyframe(2, duration: 0.25, spring: .bouncy)
                            SpringKeyframe(-3, duration: 0.25, spring: .bouncy)
                            SpringKeyframe(1, duration: 0.25, spring: .bouncy)
                            SpringKeyframe(-4, duration: 0.3, spring: .bouncy)
                            SpringKeyframe(2, duration: 0.2, spring: .bouncy)
                            SpringKeyframe(-2, duration: 0.3, spring: .bouncy)
                            SpringKeyframe(1, duration: 0.2, spring: .bouncy)
                            SpringKeyframe(-3, duration: 0.25, spring: .bouncy)
                            SpringKeyframe(0, duration: 0.45, spring: .bouncy)
                        }
                        KeyframeTrack(\.rotation) {
                            SpringKeyframe(3, duration: 0.3, spring: .bouncy)
                            SpringKeyframe(-3, duration: 0.3, spring: .bouncy)
                            SpringKeyframe(2, duration: 0.3, spring: .bouncy)
                            SpringKeyframe(-2, duration: 0.3, spring: .bouncy)
                            SpringKeyframe(3, duration: 0.25, spring: .bouncy)
                            SpringKeyframe(-2, duration: 0.25, spring: .bouncy)
                            SpringKeyframe(1, duration: 0.3, spring: .bouncy)
                            SpringKeyframe(-1, duration: 0.3, spring: .bouncy)
                            SpringKeyframe(0, duration: 0.4, spring: .bouncy)
                        }
                    }

                VStack(alignment: .leading, spacing: 8) {
                    Text(roast.text)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(textVisible ? 1 : 0)
                        .offset(y: textVisible ? 0 : 14)

                    Text(roast.personality)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(moodColor)
                        .opacity(metaVisible ? 1 : 0)
                        .offset(y: metaVisible ? 0 : 6)

                }
            }
            .padding(.leading, 14)
                .padding(.trailing, 38)
                .padding(.vertical, 16)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(isHovering ? 0.8 : 0.35))
                    .frame(width: 24, height: 24)
                    .background(.white.opacity(isHovering ? 0.15 : 0), in: Circle())
            }
            .buttonStyle(.plain)
            .offset(x: -10, y: 10)
            .opacity(textVisible ? 1 : 0)
        }
        .frame(width: 420)
        .background {
            ZStack {
                // Deep dark glass base
                Color(white: 0.06)

                // US flag stripes — subtle, only for character packs that feel patriotic
                flagStripes

                // Mood tint
                moodColor.opacity(0.03)

                // Top highlight band — glass edge
                LinearGradient(
                    colors: [
                        .white.opacity(0.22),
                        .white.opacity(0.08),
                        .white.opacity(0.02),
                        .clear,
                    ],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.35)
                )

                // Top-left bubble specular
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.08), .white.opacity(0.02), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 280, height: 100)
                    .offset(x: -50, y: -45)
                    .clipShape(RoundedRectangle(cornerRadius: 22))

                // Diagonal specular
                LinearGradient(
                    colors: [.clear, .white.opacity(0.06), .white.opacity(0.03), .clear],
                    startPoint: UnitPoint(x: -0.2, y: -0.1),
                    endPoint: UnitPoint(x: 0.5, y: 0.5)
                )

                // Bottom-right reflection
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.04), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 90
                        )
                    )
                    .frame(width: 140, height: 50)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .offset(x: -10, y: -8)
                    .clipShape(RoundedRectangle(cornerRadius: 22))

                // Double border
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.16), .white.opacity(0.05), .white.opacity(0.02), .white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.08), .white.opacity(0.02), .clear, .white.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
                    .padding(1.5)
            }
        }
        // Dark shadow halo — makes gradient border pop on light backgrounds
        .shadow(color: .black.opacity(0.6), radius: 10, y: 3)
        .shadow(color: .black.opacity(0.3), radius: 22, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("JudgyMac roast from \(roast.personality): \(roast.text)")
        .accessibilityAddTraits(.isStaticText)
        .onReceive(NotificationCenter.default.publisher(for: ContentRevealState.emojiNotification)) { _ in
            withAnimation(.spring(duration: 0.4, bounce: 0.5)) { emojiVisible = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: ContentRevealState.textNotification)) { _ in
            withAnimation(.spring(duration: 0.35, bounce: 0.2)) { textVisible = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: ContentRevealState.metaNotification)) { _ in
            withAnimation(.spring(duration: 0.3, bounce: 0.15)) { metaVisible = true }
        }
        .onHover { hovering in
            isHovering = hovering
            onHover(hovering)
        }
    }

    // MARK: - US Flag Background

    @ViewBuilder
    private var flagStripes: some View {
        // US flag background image
        if let url = Bundle.main.resourceURL?
            .appendingPathComponent("CharacterPacks/trump/roast_bg.png"),
           let nsImage = NSImage(contentsOf: url) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(0.15)
                .clipShape(RoundedRectangle(cornerRadius: 22))
        }
    }

    struct EmojiBounce {
        var offsetY: CGFloat = 0
        var rotation: Double = 0
    }

    @ViewBuilder
    private var fluentEmojiView: some View {
        if let emojiPath = roast.customEmoji,
           let url = Bundle.main.resourceURL?.appendingPathComponent("\(emojiPath).png"),
           let nsImage = NSImage(contentsOf: url) {
            Image(nsImage: nsImage)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .aspectRatio(contentMode: .fit)
                .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
        } else {
            let name = FluentEmoji.primary(for: roast.mood)
            if let img = FluentEmoji.swiftUIImage(named: name) {
                img.resizable().aspectRatio(contentMode: .fit)
            } else {
                Text(roast.mood.emoji).font(.system(size: 40))
            }
        }
    }
}
