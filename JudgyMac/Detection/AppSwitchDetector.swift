import AppKit
import Foundation

/// Detects rapid app switching — a sign of procrastination.
/// Uses NSWorkspace.didActivateApplicationNotification (no permissions needed).
/// Fires when user switches apps > threshold times within a rolling window.
final class AppSwitchDetector: BehaviorDetector, @unchecked Sendable {
    private(set) var isRunning = false

    private var onEvent: (@Sendable (BehaviorEvent) -> Void)?
    private var observer: NSObjectProtocol?
    private var switchTimestamps: [Date] = []
    private var lastFireTime: Date?

    /// Fire when user switches apps this many times within the window
    private let switchThreshold = 15
    /// Rolling time window (seconds)
    private let windowSeconds: TimeInterval = 120  // 2 minutes
    /// Cooldown between fires
    private let cooldownSeconds: TimeInterval = 300  // 5 minutes

    func start(onEvent: @escaping @Sendable (BehaviorEvent) -> Void) {
        guard !isRunning else { return }
        self.onEvent = onEvent
        isRunning = true

        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            let appName = (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?
                .localizedName ?? "Unknown"
            self.recordSwitch(app: appName)
        }

        #if DEBUG
        print("🔄 [AppSwitch] Started — threshold: \(switchThreshold) switches in \(Int(windowSeconds))s")
        #endif
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        observer = nil
    }

    private func recordSwitch(app: String) {
        let now = Date()
        switchTimestamps.append(now)

        // Prune timestamps outside the window
        switchTimestamps.removeAll { now.timeIntervalSince($0) > windowSeconds }

        // Check threshold
        guard switchTimestamps.count >= switchThreshold else { return }

        // Cooldown check
        if let lastFire = lastFireTime, now.timeIntervalSince(lastFire) < cooldownSeconds {
            return
        }

        lastFireTime = now
        let count = switchTimestamps.count

        #if DEBUG
        print("🔄 [AppSwitch] \(count) switches in \(Int(windowSeconds))s — procrastinating! Last app: \(app)")
        #endif

        onEvent?(.appSwitch(count: count, app: app))

        // Reset after firing
        switchTimestamps.removeAll()
    }
}
