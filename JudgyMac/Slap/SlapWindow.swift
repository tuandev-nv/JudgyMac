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
    private var reactionQueue: [CharacterPack.ReactionLine] = []

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

    /// Pre-warm the hosting controller for the given pack so first slap is instant.
    func warmUp(pack: CharacterPack) {
        guard currentPackId != pack.id || hostingController == nil else { return }
        let view = SlapAnimationView(
            state: slapState,
            pack: pack,
            onClose: { [weak self] in self?.dismiss() }
        )
        hostingController = NSHostingController(rootView: AnyView(view))
        panel.contentViewController = hostingController
        currentPackId = pack.id
        #if DEBUG
        print("👋 [SlapWindow] Pre-warmed for pack '\(pack.id)'")
        #endif
    }

    /// Suppress slap voice lines until this time (milestone voice playing).
    var voiceSuppressedUntil: Date = .distantPast

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

        // Create hosting controller if needed (should already be pre-warmed)
        if currentPackId != pack.id || hostingController == nil {
            warmUp(pack: pack)
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

            // After 3s: dismiss slap window → launch desktop runner
            dismissTask?.cancel()
            dismissTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }
                self?.dismiss()
                self?.launchDesktopRunner(pack: pack)
            }
            return
        }

        #if DEBUG
        print("👋 [SlapWindow] Hit #\(slapState.hitCount)")
        #endif

        if !panel.isVisible {
            centerOnScreen()
            panel.alphaValue = 1
            panel.orderFrontRegardless()
        }

        // Trigger impact after view is mounted
        DispatchQueue.main.async {
            self.slapState.impactTrigger += 1
        }

        // Pick ONE reaction line → use both text and voice
        let pickedLine = pickReactionLine(pack: pack)
        slapState.currentReactionText = pickedLine?.text
        let isVoiceSuppressed = Date() < voiceSuppressedUntil
        SoundPlayer.playSlapCombo(
            slapSound: pack.slapSoundPath,
            umphSound: "\(pack.folderPath)/slap_voice",
            voiceSound: isVoiceSuppressed ? nil : pickedLine?.voicePath
        )

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

    // MARK: - Reaction Line Picker (round-robin shuffle ALL lines)

    /// Shuffles all reaction lines from all tiers. Each line appears once before reshuffling.
    private func pickReactionLine(pack: CharacterPack) -> CharacterPack.ReactionLine? {
        if reactionQueue.isEmpty {
            reactionQueue = pack.reactions.flatMap(\.lines).shuffled()
        }
        return reactionQueue.isEmpty ? nil : reactionQueue.removeFirst()
    }

    // MARK: - Desktop Runner

    private func launchDesktopRunner(pack: CharacterPack) {
        NotificationCenter.default.post(name: .hideMenuBarSprite, object: nil)

        DesktopRunnerWindow.shared.run(pack: pack) {
            NotificationCenter.default.post(name: .showMenuBarSprite, object: nil)
        }
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
    var currentReactionText: String?  // Set by SlapWindow, used by SlapAnimationView

    var deformationLevel: Int {
        switch hitCount {
        case 0...1:   return 0  // idle
        case 2...4:   return 1
        case 5...8:   return 2
        case 9...12:  return 3
        case 13...16: return 4
        case 17...20: return 5
        case 21...25: return 6
        case 26...31: return 7
        default:      return 8  // KO / rage
        }
    }

    func reset() {
        hitCount = 0
        impactTrigger = 0
        isKnockedOut = false
        currentReactionText = nil
    }
}
