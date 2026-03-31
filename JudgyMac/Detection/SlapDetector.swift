import AppKit
import ApplicationServices
import SwiftUI

/// Detects slap gesture: Cmd+Shift held + Force Touch pressure spike on touchpad.
///
/// Uses a two-layer approach:
/// 1. Global monitor for modifier key changes (Cmd+Shift)
/// 2. When modifiers held → transparent overlay captures pressure locally
///
/// No cooldown — fires on every pressure spike for stress-toy mode.
/// Small debounce (200ms) prevents duplicate events from single tap.
final class SlapDetector: BehaviorDetector, @unchecked Sendable {
    private(set) var isRunning = false

    private var onEvent: (@Sendable (BehaviorEvent) -> Void)?
    private var flagsMonitor: Any?
    private var localMonitor: Any?
    private var modifiersHeld = false
    private var overlayPanel: NSPanel?
    private var lastSlapTime: Date?

    func start(onEvent: @escaping @Sendable (BehaviorEvent) -> Void) {
        guard !isRunning else { return }
        self.onEvent = onEvent
        isRunning = true

        #if DEBUG
        print("👋 [SlapDetector] Starting... Accessibility trusted: \(AXIsProcessTrusted())")
        #endif

        // Layer 1: Global monitor for Cmd+Shift flags
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { event in
            let held = event.modifierFlags.contains([.command, .shift])
            MainActor.assumeIsolated { [weak self] in
                self?.handleModifiers(held: held)
            }
        }

        // Also monitor locally (when our own windows are focused)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            let held = event.modifierFlags.contains([.command, .shift])
            MainActor.assumeIsolated { [weak self] in
                self?.handleModifiers(held: held)
            }
            return event
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false

        if let flagsMonitor { NSEvent.removeMonitor(flagsMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        flagsMonitor = nil
        localMonitor = nil

        Task { @MainActor in
            self.hideOverlay()
        }
    }

    // MARK: - Modifier Key Handling

    @MainActor
    private func handleModifiers(held: Bool) {
        if held && !modifiersHeld {
            modifiersHeld = true
            showOverlay()
            #if DEBUG
            print("👋 [SlapDetector] Cmd+Shift HELD — overlay ON")
            #endif
        } else if !held && modifiersHeld {
            modifiersHeld = false
            hideOverlay()
            #if DEBUG
            print("👋 [SlapDetector] Cmd+Shift RELEASED — overlay OFF")
            #endif
        }
    }

    // MARK: - Pressure Overlay

    @MainActor
    private func showOverlay() {
        guard overlayPanel == nil, let screen = NSScreen.main else { return }

        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        // Alpha must be > 0.01 for macOS to reliably forward click events
        panel.alphaValue = 0.02
        panel.level = .floating           // Below SlapWindow, above normal windows
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.ignoresMouseEvents = false
        panel.hasShadow = false

        // Use NSView directly — more reliable click capture than SwiftUI hosting
        let trackingNSView = PressureTrackingNSView()
        trackingNSView.frame = screen.frame
        trackingNSView.onPressureSpike = { [weak self] pressure in
            self?.handlePressureSpike(pressure)
        }
        panel.contentView = trackingNSView

        panel.orderFrontRegardless()
        panel.makeFirstResponder(trackingNSView)

        overlayPanel = panel
    }

    @MainActor
    private func hideOverlay() {
        overlayPanel?.orderOut(nil)
        overlayPanel = nil
    }

    // MARK: - Pressure Detection

    private func handlePressureSpike(_ pressure: Double) {
        // Double-check modifiers are still held (guards against stuck state)
        let currentFlags = NSEvent.modifierFlags
        guard currentFlags.contains([.command, .shift]) else {
            // Modifiers released but overlay still showing — clean up
            Task { @MainActor in
                self.modifiersHeld = false
                self.hideOverlay()
            }
            return
        }

        // Max 3 slaps per second
        let now = Date()
        if let last = lastSlapTime, now.timeIntervalSince(last) < 0.33 {
            return
        }
        lastSlapTime = now

        #if DEBUG
        print("👋 [SlapDetector] Pressure spike: \(String(format: "%.2f", pressure))")
        #endif

        onEvent?(.slap(pressure: pressure))
    }
}
