import AppKit
import SwiftUI

/// Floating window for the slap face animation.
/// Panel is created ONCE and reused — show/hide instead of create/destroy.
@MainActor
final class SlapWindow {
    static let shared = SlapWindow()
    private init() { setupPanel() }

    private var panel: NSPanel!
    private var hostingController: NSHostingController<AnyView>!
    private let slapState = SlapState()
    private var dismissTask: Task<Void, Never>?
    private var isDismissing = false
    private var currentCharacter: SlapCharacter?

    // MARK: - Pre-create panel (called once)

    private func setupPanel() {
        let size = Constants.Slap.windowSize
        let windowHeight = size + 120

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: size, height: windowHeight),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = false
        panel.ignoresMouseEvents = true

        // Center on screen
        if let screen = NSScreen.main {
            let sf = screen.frame
            let x = sf.midX - size / 2
            let y = sf.midY - windowHeight / 2 + 80
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.panel = panel
    }

    // MARK: - Slap

    func slap(character: SlapCharacter) {
        dismissTask?.cancel()
        dismissTask = nil

        if isDismissing {
            isDismissing = false
            panel.animator().alphaValue = 1
        }

        slapState.hitCount += 1
        slapState.impactTrigger += 1

        #if DEBUG
        print("👋 [SlapWindow] Hit #\(slapState.hitCount)")
        #endif

        // Create/update hosting controller if character changed or first time
        if currentCharacter?.id != character.id || hostingController == nil {
            let view = SlapAnimationView(
                state: slapState,
                character: character,
                onClose: { [weak self] in self?.dismiss() }
            )
            hostingController = NSHostingController(rootView: AnyView(view))
            panel.contentViewController = hostingController
            currentCharacter = character
        }

        if !panel.isVisible {
            panel.alphaValue = 1
            panel.orderFrontRegardless()
            // Trigger first impact after view is mounted
            DispatchQueue.main.async {
                self.slapState.impactTrigger += 1
            }
        }

        // Play sounds
        let reaction = character.reaction(forHitCount: slapState.hitCount)
        let voiceName = reaction?.voices.randomElement()
        SoundPlayer.playSlapCombo(slapSound: character.slapSoundName, voiceSound: voiceName)

        restartDismissTimer()
    }

    // MARK: - Dismiss

    func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        guard panel.isVisible, !isDismissing else { return }

        isDismissing = true

        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            panel.orderOut(nil)
            resetState()
        } else {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.3
                panel.animator().alphaValue = 0
            }, completionHandler: {
                Task { @MainActor [weak self] in
                    guard let self, self.isDismissing else { return }
                    self.panel.orderOut(nil)
                    self.resetState()
                }
            })
        }
    }

    private func resetState() {
        isDismissing = false
        slapState.reset()
    }

    // MARK: - Dismiss Timer

    private func restartDismissTimer() {
        dismissTask?.cancel()
        dismissTask = nil
        let seconds = Constants.Slap.dismissIdleSeconds
        dismissTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(seconds))
                guard !Task.isCancelled else { return }
                self?.dismiss()
            } catch {
                // Cancelled by new slap
            }
        }
    }
}

// MARK: - Slap State

@Observable
final class SlapState {
    var hitCount: Int = 0
    var impactTrigger: Int = 0

    var deformationLevel: Int {
        switch hitCount {
        case 0:      return 0
        case 1...3:  return 1
        case 4...7:  return 2
        case 8...15: return 3
        default:     return 4
        }
    }

    func reset() {
        hitCount = 0
        impactTrigger = 0
    }
}
