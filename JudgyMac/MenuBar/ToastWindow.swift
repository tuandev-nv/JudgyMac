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

        // Animate in: slide down + fade
        panel.alphaValue = 0
        let finalOrigin = panel.frame.origin
        panel.setFrameOrigin(NSPoint(x: finalOrigin.x, y: finalOrigin.y + 20))
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.4
            ctx.timingFunction = CAMediaTimingFunction(name: .default)
            panel.animator().alphaValue = 1
            panel.animator().setFrameOrigin(finalOrigin)
        }

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

        let origin = panel.frame.origin
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.25
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
            panel.animator().setFrameOrigin(NSPoint(x: origin.x, y: origin.y + 15))
        }, completionHandler: { [weak self] in
            panel.orderOut(nil)
            self?.window = nil
        })
    }
}

// MARK: - Toast View

private struct ToastView: View {
    let roast: RoastEntry
    let onClose: () -> Void
    let onHover: (Bool) -> Void
    @State private var emojiAppeared = false
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
        VStack(spacing: 0) {
            // Mood accent bar
            Rectangle()
                .fill(moodColor)
                .frame(height: 3)

            ZStack(alignment: .topTrailing) {
                HStack(alignment: .top, spacing: 16) {
                    // Fluent 3D Emoji
                    fluentEmojiView
                        .frame(width: 56, height: 56)
                        .scaleEffect(emojiAppeared ? 1 : 0.3)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.5).delay(0.15),
                            value: emojiAppeared
                        )

                    VStack(alignment: .leading, spacing: 8) {
                        Text(roast.text)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(roast.personality)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(moodColor)

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
            }
        }
        .frame(width: 420)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.88))
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(moodColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
        .shadow(color: moodColor.opacity(0.25), radius: 30, y: 12)
        .onAppear { emojiAppeared = true }
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
