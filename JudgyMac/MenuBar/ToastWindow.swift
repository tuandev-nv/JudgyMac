import AppKit
import SwiftUI

/// Custom floating toast — dark, bold, screenshot-worthy.
/// Hover pauses auto-dismiss. Close button always visible.
@MainActor
final class ToastWindow {
    private var window: NSPanel?
    private var dismissTask: Task<Void, Never>?
    private var isHovered = false

    static let shared = ToastWindow()
    private init() {}

    func show(roast: RoastEntry) {
        dismiss()

        let toastView = ToastView(
            roast: roast,
            onClose: { [weak self] in self?.dismiss() },
            onHover: { [weak self] hovering in self?.isHovered = hovering }
        )
        let hostingController = NSHostingController(rootView: toastView)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 1),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = hostingController
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = false

        let fittingSize = hostingController.view.fittingSize
        panel.setContentSize(NSSize(width: 420, height: fittingSize.height))

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 210
            let y = screenFrame.maxY - fittingSize.height - 40
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        window = panel

        // Show immediately — all animation is handled by SwiftUI inside ToastView
        panel.alphaValue = 1
        panel.orderFrontRegardless()

        // Auto-dismiss after 10s (paused while hovered)
        startDismissCountdown()
    }

    private func startDismissCountdown() {
        dismissTask = Task {
            var remaining: Double = 10
            while remaining > 0 {
                try? await Task.sleep(for: .milliseconds(500))
                if !isHovered {
                    remaining -= 0.5
                }
            }
            dismiss()
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        guard let panel = window else { return }

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.3
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: {
            Task { @MainActor [weak self] in
                panel.orderOut(nil)
                self?.window = nil
            }
        })
    }
}

// MARK: - Toast View

private struct ToastView: View {
    let roast: RoastEntry
    let onClose: () -> Void
    let onHover: (Bool) -> Void

    // Staggered entrance states
    @State private var bubblePopped = false
    @State private var emojiPopped = false
    @State private var textRevealed = false
    @State private var personalityRevealed = false
    @State private var wobblePhase: Double = 0
    @State private var isHovering = false
    private let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

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
        let skipAnim = reduceMotion

        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                HStack(alignment: .top, spacing: 16) {
                    // Fluent 3D Emoji — pops in first
                    fluentEmojiView
                        .frame(width: 56, height: 56)
                        .scaleEffect(skipAnim || emojiPopped ? 1 : 0.01)
                        .rotationEffect(.degrees(skipAnim || emojiPopped ? 0 : -30))

                    VStack(alignment: .leading, spacing: 8) {
                        // Roast text — slides up after emoji
                        Text(roast.text)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(skipAnim || textRevealed ? 1 : 0)
                            .offset(y: skipAnim || textRevealed ? 0 : 12)

                        // Personality label — fades in last
                        Text(roast.personality)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(moodColor)
                            .opacity(skipAnim || personalityRevealed ? 1 : 0)
                            .offset(y: skipAnim || personalityRevealed ? 0 : 8)

                        HStack(spacing: 4) {
                            Text("JudgyMac")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.4))
                            Text("·")
                                .foregroundStyle(.white.opacity(0.2))
                            Text("judgymac.com")
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                        .opacity(skipAnim || personalityRevealed ? 1 : 0)
                    }
                }
                .padding(20)

                // Close button
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(isHovering ? 0.8 : 0.3))
                        .frame(width: 20, height: 20)
                        .background(.white.opacity(isHovering ? 0.15 : 0), in: Circle())
                }
                .buttonStyle(.plain)
                .padding(10)
                .opacity(skipAnim || textRevealed ? 1 : 0)
            }
        }
        .frame(width: 420)
        .background {
            ZStack {
                // Base bubble
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.88))

                // 3D bubble highlight — top-left sheen
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [moodColor.opacity(0.15), .clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )

                // Inner highlight — soap bubble reflection
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.08), .clear],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 180
                        )
                    )
                    .frame(width: 200, height: 80)
                    .offset(x: -60, y: -30)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [moodColor.opacity(0.5), moodColor.opacity(0.1), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 25, y: 10)
        .shadow(color: moodColor.opacity(0.3), radius: 40, y: 15)
        // Bubble pop-in: scale from tiny with overshoot
        .scaleEffect(skipAnim || bubblePopped ? 1 : 0.3)
        .opacity(skipAnim || bubblePopped ? 1 : 0)
        // Subtle wobble after landing
        .rotation3DEffect(
            .degrees(wobblePhase > 0 ? sin(wobblePhase * 3) * 1.5 : 0),
            axis: (x: 0, y: 0, z: 1),
            perspective: 0.5
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("JudgyMac roast from \(roast.personality): \(roast.text)")
        .accessibilityAddTraits(.isStaticText)
        .onAppear {
            guard !reduceMotion else {
                bubblePopped = true
                emojiPopped = true
                textRevealed = true
                personalityRevealed = true
                return
            }
            // Step 1: Bubble pops in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
                bubblePopped = true
            }
            // Step 2: Emoji pops
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.45)) {
                    emojiPopped = true
                }
            }
            // Step 3: Text slides up
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    textRevealed = true
                }
            }
            // Step 4: Personality + footer
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    personalityRevealed = true
                }
            }
            // Step 5: Wobble settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 1.2)) {
                    wobblePhase = .pi * 4
                }
            }
        }
        .onHover { hovering in
            isHovering = hovering
            onHover(hovering)
        }
    }

    @ViewBuilder
    private var fluentEmojiView: some View {
        let name = FluentEmoji.primary(for: roast.mood)
        if let img = FluentEmoji.swiftUIImage(named: name) {
            img.resizable().aspectRatio(contentMode: .fit)
        } else {
            Text(roast.mood.emoji).font(.system(size: 40))
        }
    }
}
