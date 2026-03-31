import CoreGraphics
import Foundation

/// Detects continuous screen usage without breaks.
/// Fires `.screenTime` after 45 minutes of active use, then every 45 minutes.
/// Resets when user is idle for 5+ minutes (actual break taken).
final class ScreenTimeDetector: BehaviorDetector, @unchecked Sendable {
    private(set) var isRunning = false

    private var onEvent: (@Sendable (BehaviorEvent) -> Void)?
    private var timer: Timer?
    private var sessionStartTime: Date?
    private var lastFireTime: Date?

    private let checkInterval: TimeInterval = 60          // Poll every 60s
    private let breakThresholdSeconds: TimeInterval = 300  // 5 min idle = break taken
    private let fireIntervalMinutes: Int = 45              // Remind every 45 min

    func start(onEvent: @escaping @Sendable (BehaviorEvent) -> Void) {
        guard !isRunning else { return }
        self.onEvent = onEvent
        isRunning = true
        sessionStartTime = Date()

        timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            self?.check()
        }

        #if DEBUG
        print("👁️ [ScreenTime] Started — will remind every \(fireIntervalMinutes) min")
        #endif
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func check() {
        let keyIdle = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState, eventType: .keyDown
        )
        let mouseIdle = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState, eventType: .mouseMoved
        )
        let idleSeconds = min(keyIdle, mouseIdle)

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
        let activeMinutes = Int(Date().timeIntervalSince(start) / 60)

        // Not yet time to fire
        guard activeMinutes >= fireIntervalMinutes else { return }

        // Check if we already fired recently (within this interval)
        if let lastFire = lastFireTime {
            let minutesSinceLastFire = Int(Date().timeIntervalSince(lastFire) / 60)
            guard minutesSinceLastFire >= fireIntervalMinutes else { return }
        }

        lastFireTime = Date()

        #if DEBUG
        print("👁️ [ScreenTime] \(activeMinutes) min continuous — take a break!")
        #endif

        onEvent?(.screenTime(minutes: activeMinutes))
    }
}
