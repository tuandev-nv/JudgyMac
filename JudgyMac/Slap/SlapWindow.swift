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
    private var currentPackId: String?
    private var slapVoiceQueue: [Int] = []
    private let slapVoiceChance = 0.5  // 50% chance to play voice each slap

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

        self.panel = panel
    }

    /// Re-center panel on the current main screen (handles multi-display, resolution changes)
    private func centerOnScreen() {
        let size = Constants.Slap.windowSize
        let windowHeight = size + 120

        // Use the screen with the current mouse pointer for multi-display support
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main

        guard let screen else { return }
        let visibleFrame = screen.visibleFrame
        let x = visibleFrame.midX - size / 2
        let y = visibleFrame.midY - windowHeight / 2
        panel.setFrame(NSRect(x: x, y: y, width: size, height: windowHeight), display: false)
    }

    // MARK: - Slap

    func slap(pack: CharacterPack) {
        // KO — ignore all slaps during cooldown
        if slapState.isKnockedOut {
            return
        }

        dismissTask?.cancel()
        dismissTask = nil

        if isDismissing {
            isDismissing = false
            panel.animator().alphaValue = 1
        }

        slapState.hitCount += 1

        // Check if this hit triggers KO
        if slapState.hitCount >= pack.slapLimit {
            slapState.isKnockedOut = true
            slapState.impactTrigger += 1

            // Play rage voice if available
            if let rage = pack.rageReaction, let voicePath = rage.voicePath {
                SoundPlayer.play(voicePath)
            }

            // After 5s: dismiss and reset so they can slap again
            dismissTask?.cancel()
            dismissTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                self?.dismiss()
            }
            return
        }

        #if DEBUG
        print("👋 [SlapWindow] Hit #\(slapState.hitCount)")
        #endif

        // Create/update hosting controller if pack changed or first time
        let needsNewView = currentPackId != pack.id || hostingController == nil
        if needsNewView {
            let view = SlapAnimationView(
                state: slapState,
                pack: pack,
                onClose: { [weak self] in self?.dismiss() }
            )
            hostingController = NSHostingController(rootView: AnyView(view))
            panel.contentViewController = hostingController
            currentPackId = pack.id
        }

        if !panel.isVisible {
            centerOnScreen()
            panel.alphaValue = 1
            panel.orderFrontRegardless()
        }

        // Trigger impact after view is mounted (single trigger, no double-fire)
        DispatchQueue.main.async {
            self.slapState.impactTrigger += 1
        }

        // Play slap impact always + random voice (50% chance, round-robin shuffle)
        let voicePath = nextSlapVoice(pack: pack)
        SoundPlayer.playSlapCombo(slapSound: pack.slapSoundPath, voiceSound: voicePath)

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

    // MARK: - Slap Voice (round-robin shuffle, 50% chance)

    /// Returns a voice path or nil. Round-robin ensures all voices play once before reshuffling.
    private func nextSlapVoice(pack: CharacterPack) -> String? {
        let voiceCount = pack.slapVoiceCount
        guard voiceCount > 0 else { return nil }

        // 50% chance to skip voice entirely
        guard Double.random(in: 0...1) < slapVoiceChance else { return nil }

        // Refill queue when empty (shuffle 1...voiceCount)
        if slapVoiceQueue.isEmpty {
            slapVoiceQueue = Array(1...voiceCount).shuffled()
        }

        let index = slapVoiceQueue.removeFirst()
        return "\(pack.folderPath)/slap_voices/slap_voice_\(index)"
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
    var isKnockedOut: Bool = false

    var deformationLevel: Int {
        switch hitCount {
        case 0:       return 0
        case 1...3:   return 1
        case 4...7:   return 2
        case 8...12:  return 3
        case 13...20: return 4
        case 21...30: return 5
        case 31...40: return 6
        case 41...49: return 7
        default:      return 8  // KO / rage
        }
    }

    func reset() {
        hitCount = 0
        impactTrigger = 0
        isKnockedOut = false
    }
}
