import Foundation
import CoreGraphics

/// Detects user idle time via CGEventSource.
/// Triggers: idle (when user has been inactive for threshold duration)
final class IdleDetector: BehaviorDetector, @unchecked Sendable {
    private(set) var isRunning = false

    private var onEvent: (@Sendable (BehaviorEvent) -> Void)?
    private var timer: Timer?
    private var hasTriggeredThisIdlePeriod = false

    func start(onEvent: @escaping @Sendable (BehaviorEvent) -> Void) {
        guard !isRunning else { return }
        self.onEvent = onEvent
        isRunning = true

        timer = Timer.scheduledTimer(
            withTimeInterval: Constants.Detection.idlePollIntervalSeconds,
            repeats: true
        ) { [weak self] _ in
            self?.checkIdle()
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func checkIdle() {
        let idleSeconds = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .mouseMoved
        )

        // Also check keyboard activity
        let keyIdleSeconds = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .keyDown
        )

        // Use the minimum (most recent activity of either type)
        let effectiveIdle = min(idleSeconds, keyIdleSeconds)
        let idleMinutes = Int(effectiveIdle / 60)

        if idleMinutes >= Constants.Detection.idleThresholdMinutes {
            if !hasTriggeredThisIdlePeriod {
                hasTriggeredThisIdlePeriod = true
                onEvent?(.idle(minutes: idleMinutes))
            }
        } else {
            // User is active again, reset for next idle period
            hasTriggeredThisIdlePeriod = false
        }
    }
}
