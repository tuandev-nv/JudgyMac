import Foundation
import AppKit

/// Detects continuous screen usage without breaks.
/// Fires `.screenTime` after 45 minutes of active use, then every 45 minutes.
/// Resets when user is idle for 5+ minutes (actual break taken).
final class ScreenTimeDetector: BehaviorDetector, @unchecked Sendable {
    private(set) var isRunning = false

    private var onEvent: (@Sendable (BehaviorEvent) -> Void)?
    private var timer: Timer?
    private var sessionStartTime: Date?
    private var lastFireTime: Date?

    private let checkInterval: TimeInterval = 60
    private let breakThresholdSeconds: TimeInterval = 300  // 5 min idle = break
    private let fireIntervalMinutes: Int = 45
    private var lastCheckTime: Date?
    private var sleepObservers: [NSObjectProtocol] = []

    func start(onEvent: @escaping @Sendable (BehaviorEvent) -> Void) {
        guard !isRunning else { return }
        self.onEvent = onEvent
        isRunning = true
        sessionStartTime = Date()
        lastCheckTime = Date()

        ActivityMonitor.shared.subscribe()
        timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            self?.check()
        }

        // Reset session on wake from sleep
        let wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.sessionStartTime = nil
            self?.lastFireTime = nil
            self?.lastCheckTime = Date()
        }
        sleepObservers.append(wakeObserver)

        #if DEBUG
        print("👁️ [ScreenTime] Started — will remind every \(fireIntervalMinutes) min")
        #endif
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        timer?.invalidate()
        timer = nil
        for obs in sleepObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
        }
        sleepObservers.removeAll()
        ActivityMonitor.shared.unsubscribe()
    }

    private func check() {
        // Detect sleep gap — if last check was more than 2 min ago, machine was sleeping
        let now = Date()
        if let lastCheck = lastCheckTime, now.timeIntervalSince(lastCheck) > checkInterval * 2 {
            sessionStartTime = nil
            lastFireTime = nil
        }
        lastCheckTime = now

        let idleSeconds = ActivityMonitor.shared.idleSeconds

        // User took a real break — reset session
        if idleSeconds >= breakThresholdSeconds {
            sessionStartTime = nil
            lastFireTime = nil
            return
        }

        // User is active — start session if not already
        if sessionStartTime == nil {
            sessionStartTime = Date()
        }

        guard let start = sessionStartTime else { return }
        let activeMinutes = Int(now.timeIntervalSince(start) / 60)

        guard activeMinutes >= fireIntervalMinutes else { return }

        if let lastFire = lastFireTime {
            let minutesSinceLastFire = Int(now.timeIntervalSince(lastFire) / 60)
            guard minutesSinceLastFire >= fireIntervalMinutes else { return }
        }

        lastFireTime = Date()

        #if DEBUG
        print("👁️ [ScreenTime] \(activeMinutes) min continuous — take a break!")
        #endif

        onEvent?(.screenTime(minutes: activeMinutes))
    }
}
