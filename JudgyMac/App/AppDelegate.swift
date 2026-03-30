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

    // MARK: - App Lifecycle

    private var saveTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self

        // Load persisted data
        SettingsStore.load(into: _appState)

        setupStatusItem()
        setupPopover()
        startEngine()

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
            button.image = NSImage(systemSymbolName: "face.smiling", accessibilityDescription: "JudgyMac")
            button.image?.size = NSSize(width: 18, height: 18)
            button.action = #selector(togglePopover)
            button.target = self
        }
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

        let coord = DetectionCoordinator(appState: _appState)
        coord.start()
        coordinator = coord

        print("🤨 [JudgyMac] App started. Detectors running.")
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
        } catch {}
    }

    static var isLaunchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
}

extension Notification.Name {
    static let snoozeRoasts = Notification.Name("com.judgymac.snoozeRoasts")
    static let moreLikeThis = Notification.Name("com.judgymac.moreLikeThis")
}
