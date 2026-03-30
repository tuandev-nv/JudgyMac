import AppKit
import SwiftUI

/// Custom floating toast — dark, bold, screenshot-worthy.
@MainActor
final class ToastWindow {
    private var window: NSPanel?
    private var dismissTask: Task<Void, Never>?

    static let shared = ToastWindow()
    private init() {}

    func show(roast: RoastEntry) {
        dismiss()

        let toastView = ToastView(roast: roast)
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
        panel.hasShadow = false // We draw our own shadow
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = false

        let fittingSize = hostingController.view.fittingSize
        panel.setContentSize(NSSize(width: 420, height: fittingSize.height))

        // Position: center-top of main screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 210
            let y = screenFrame.maxY - fittingSize.height - 40
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        window = panel

        // Animate: slide down + fade in
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

        // Auto-dismiss after 6 seconds
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(10))
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
    @State private var emojiAppeared = false

    private var moodColor: Color {
        switch roast.mood {
        case .judging:   return Color(red: 1, green: 0.18, blue: 0.47) // #FF2D78
        case .horrified: return Color(red: 0, green: 0.83, blue: 1)    // #00D4FF
        case .raging:    return Color(red: 1, green: 0.27, blue: 0.27) // #FF4444
        case .sleeping:  return Color(red: 0.55, green: 0.5, blue: 0.78) // #8B7FC7
        case .impressed: return Color(red: 0, green: 0.9, blue: 0.63)  // #00E5A0
        case .neutral:   return Color(red: 0.61, green: 0.35, blue: 1)  // #9B59FF
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Mood accent bar
            Rectangle()
                .fill(moodColor)
                .frame(height: 3)

            HStack(alignment: .top, spacing: 16) {
                // Big emoji
                Text(roast.mood.emoji)
                    .font(.system(size: 48))
                    .scaleEffect(emojiAppeared ? 1 : 0.3)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.5)
                            .delay(0.15),
                        value: emojiAppeared
                    )

                VStack(alignment: .leading, spacing: 8) {
                    // Roast text — the star
                    Text(roast.text)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Personality name
                    Text(roast.personality)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(moodColor)

                    // Branding
                    HStack(spacing: 4) {
                        Text("🤨")
                            .font(.system(size: 10))
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
        // Main shadow
        .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
        // Mood color glow
        .shadow(color: moodColor.opacity(0.25), radius: 30, y: 12)
        .onAppear { emojiAppeared = true }
    }
}
