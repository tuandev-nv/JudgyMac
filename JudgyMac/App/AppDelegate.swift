import AppKit
import SwiftUI
import UserNotifications
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, @preconcurrency UNUserNotificationCenterDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var settingsController: SettingsWindowController?
    let _appState = AppState()
    private var coordinator: DetectionCoordinator?
    private var presenter: RoastPresenter?
    private var slapPresenter: SlapPresenter?

    // Animated menu bar icon
    private let cpuMonitor = CPUMonitor()
    private var animationTimer: Timer?
    private var animationFrame = 0
    private var currentMood: Mood = .neutral
    private var currentAnimationInterval: TimeInterval = 2.5

    // MARK: - App Lifecycle

    private var saveTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self

        // Load persisted data
        SettingsStore.load(into: _appState)

        setupStatusItem()
        setupPopover()
        startEngine()

        #if DEBUG
        // Ctrl+Shift+S → trigger slap (dev shortcut, bypass popover)
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.control, .shift]),
               event.charactersIgnoringModifiers == "s" {
                let slapEvent = BehaviorEvent.slap(pressure: 0.95)
                self?._appState.handleEvent(slapEvent)
                NotificationCenter.default.post(
                    name: .behaviorEventDetected,
                    object: nil,
                    userInfo: ["event": slapEvent]
                )
                return nil // Consume event
            }
            return event
        }
        #endif

        // Auto-save every 30 seconds
        saveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                SettingsStore.save(self._appState)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        SettingsStore.save(_appState)
    }

    // MARK: - Status Item (Menu Bar Icon)

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            // Initial icon — Fluent Emoji
            updateMenuBarIcon()
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Animate menu bar icon — speed based on CPU
        startMenuBarAnimation()
    }

    private func startMenuBarAnimation() {
        // Respect Reduce Motion — use static icon, only update mood (no frame cycling)
        let interval: TimeInterval = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 5.0 : 1.5
        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.tickAnimation()
            }
        }
    }

    private func tickAnimation() {
        // Update mood from app state
        currentMood = _appState.currentMood

        // Read CPU and adjust animation speed
        let cpu = cpuMonitor.currentUsage()
        _appState.cpuUsage = cpu

        // Faster animation = higher CPU
        let newInterval: TimeInterval = switch cpu {
        case 0.8...: 0.3   // Very fast — panic
        case 0.5..<0.8: 0.6 // Fast — stressed
        case 0.2..<0.5: 1.2 // Normal
        default: 2.5        // Slow — chill
        }

        // Only recreate timer when interval bracket changes
        if newInterval != currentAnimationInterval {
            currentAnimationInterval = newInterval
            animationTimer?.invalidate()
            animationTimer = Timer.scheduledTimer(withTimeInterval: newInterval, repeats: true) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    self.tickAnimation()
                }
            }
        }

        // Advance frame (static on Reduce Motion — always frame 0)
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            animationFrame = 0
        } else {
            animationFrame = (animationFrame + 1) % 4
        }
        updateMenuBarIcon()
    }

    private func updateMenuBarIcon() {
        let faceName = FluentEmoji.face(for: currentMood, frame: animationFrame)
        if let image = FluentEmoji.menuBarImage(named: faceName) {
            image.accessibilityDescription = "JudgyMac — \(currentMood.displayName)"
            statusItem.button?.image = image
        }

        // Stats text next to icon
        let cpu = Int(_appState.cpuUsage * 100)
        let roasts = _appState.todayStats.roastCount
        let statsText = " \(roasts)  CPU \(cpu)%"

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium),
            .foregroundColor: NSColor.controlTextColor,
        ]
        statusItem.button?.attributedTitle = NSAttributedString(string: statsText, attributes: attrs)
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 480)
        popover.behavior = .transient
        popover.animates = true

        let contentView = MenuBarView(
            onOpenSettings: { [weak self] in
                self?.openSettings()
            },
            onShare: { [weak self] in
                self?.shareSummary()
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )
        .environment(_appState)

        popover.contentViewController = NSHostingController(rootView: contentView)
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Ensure popover window is key so clicks work
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - Actions (run after popover closes)

    private func openSettings() {
        if popover.isShown {
            popover.performClose(nil)
        }
        showSettingsWindow()
    }

    private func showSettingsWindow() {
        if settingsController == nil {
            settingsController = SettingsWindowController(appState: _appState)

            // No activation policy change needed during dev
        }

        settingsController?.showAndFocus()
    }

    private func shareSummary() {
        if popover.isShown {
            popover.performClose(nil)
        }
        let summary = DailySummaryGenerator.generate(
            stats: _appState.todayStats,
            history: _appState.roastHistory
        )
        SummaryShareHelper.shareSummary(summary)
    }

    // MARK: - Engine

    private func startEngine() {
        let p = RoastPresenter(appState: _appState)
        p.requestPermission()
        presenter = p

        slapPresenter = SlapPresenter(appState: _appState)

        let coord = DetectionCoordinator(appState: _appState)
        coord.start()
        coordinator = coord

        #if DEBUG
        print("🤨 [JudgyMac] App started. Detectors running.")
        #endif
    }

    // MARK: - Update Menu Bar Icon

    func updateIcon(for mood: Mood) {
        let symbolName: String = switch mood {
        case .neutral:   "face.smiling"
        case .judging:   "face.smiling.inverse"
        case .horrified: "exclamationmark.triangle"
        case .sleeping:  "zzz"
        case .raging:    "flame"
        case .impressed: "star"
        }

        statusItem.button?.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: mood.displayName
        )
        statusItem.button?.image?.size = NSSize(width: 18, height: 18)
    }

    // MARK: - Notification Delegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.actionIdentifier {
        case "SHUT_UP":
            NotificationCenter.default.post(name: .snoozeRoasts, object: nil)
        case "MORE_LIKE_THIS":
            NotificationCenter.default.post(name: .moreLikeThis, object: nil)
        default:
            break
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Launch at Login

    static func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            #if DEBUG
            print("🤨 [LaunchAtLogin] Failed: \(error.localizedDescription)")
            #endif
        }
    }

    static var isLaunchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
}

extension Notification.Name {
    static let snoozeRoasts = Notification.Name("com.judgymac.snoozeRoasts")
    static let moreLikeThis = Notification.Name("com.judgymac.moreLikeThis")

}
