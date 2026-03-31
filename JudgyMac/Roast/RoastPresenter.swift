import Foundation
import UserNotifications
import CoreGraphics

/// Delivers roasts via macOS notifications and updates the app state.
@MainActor
final class RoastPresenter {
    private let appState: AppState
    private let engine: RoastEngine
    private var snoozedUntil: Date?
    private nonisolated(unsafe) var eventObserver: NSObjectProtocol?
    private nonisolated(unsafe) var snoozeObserver: NSObjectProtocol?

    init(appState: AppState) {
        self.appState = appState
        self.engine = RoastEngine(appState: appState)
        setupNotifications()
        observeEvents()
        observeSnooze()
    }

    deinit {
        if let eventObserver { NotificationCenter.default.removeObserver(eventObserver) }
        if let snoozeObserver { NotificationCenter.default.removeObserver(snoozeObserver) }
        if let screenUnlockObserver { DistributedNotificationCenter.default().removeObserver(screenUnlockObserver) }
    }

    // MARK: - Setup

    private func setupNotifications() {
        let center = UNUserNotificationCenter.current()

        let shutUp = UNNotificationAction(
            identifier: "SHUT_UP",
            title: "Shut up",
            options: []
        )
        let moreLikeThis = UNNotificationAction(
            identifier: "MORE_LIKE_THIS",
            title: "More like this",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: "ROAST",
            actions: [shutUp, moreLikeThis],
            intentIdentifiers: []
        )

        center.setNotificationCategories([category])
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, _ in }
    }

    // MARK: - Event Observation

    private func observeEvents() {
        eventObserver = NotificationCenter.default.addObserver(
            forName: .behaviorEventDetected,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let event = notification.userInfo?["event"] as? BehaviorEvent else { return }
            Task { @MainActor in
                self?.handleEvent(event)
            }
        }
    }

    private func observeSnooze() {
        snoozeObserver = NotificationCenter.default.addObserver(
            forName: .snoozeRoasts,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.snoozedUntil = Date().addingTimeInterval(3600) // 1 hour
            }
        }
    }

    private func handleEvent(_ event: BehaviorEvent) {
        // Slap events are handled by SlapPresenter
        guard event.type != .slap else { return }

        // Check snooze
        if let snoozedUntil, Date() < snoozedUntil { return }

        guard let roast = engine.generateRoast(for: event) else { return }

        appState.deliverRoast(roast)

        showToastWhenUnlocked(roast: roast)
    }

    // MARK: - Toast (wait for screen unlock)

    private var pendingRoast: RoastEntry?
    private nonisolated(unsafe) var screenUnlockObserver: Any?

    private func showToastWhenUnlocked(roast: RoastEntry) {
        let isLocked = CGSessionCopyCurrentDictionary()
            .flatMap { ($0 as NSDictionary)["CGSSessionScreenIsLocked"] as? Bool } ?? false

        if isLocked {
            // Screen locked — queue roast and wait for unlock
            pendingRoast = roast
            if screenUnlockObserver == nil {
                screenUnlockObserver = DistributedNotificationCenter.default().addObserver(
                    forName: NSNotification.Name("com.apple.screenIsUnlocked"),
                    object: nil,
                    queue: .main
                ) { [weak self] _ in
                    Task { @MainActor in
                        // Delay 2s after unlock so user sees desktop first
                        try? await Task.sleep(for: .seconds(2))
                        if let pending = self?.pendingRoast {
                            self?.showToast(pending)
                            self?.pendingRoast = nil
                        }
                    }
                }
            }
        } else {
            showToast(roast)
        }
    }

    private func showToast(_ roast: RoastEntry) {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            if settings.authorizationStatus == .authorized {
                ToastWindow.shared.show(roast: roast)
            }
        }
    }

    // MARK: - Notification Delivery

    private func sendNotification(roast: RoastEntry) {
        let content = UNMutableNotificationContent()
        content.title = "\(roast.mood.emoji) JudgyMac"
        content.body = roast.text
        content.subtitle = "— \(roast.personality)"
        content.categoryIdentifier = "ROAST"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: roast.id.uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
