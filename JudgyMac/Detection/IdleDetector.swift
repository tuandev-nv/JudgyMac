import Foundation

/// Detects user idle time via shared ActivityMonitor.
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

        ActivityMonitor.shared.subscribe()
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
        ActivityMonitor.shared.unsubscribe()
    }

    private func checkIdle() {
        let idleMinutes = Int(ActivityMonitor.shared.idleSeconds / 60)

        if idleMinutes >= Constants.Detection.idleThresholdMinutes {
            if !hasTriggeredThisIdlePeriod {
                hasTriggeredThisIdlePeriod = true
                onEvent?(.idle(minutes: idleMinutes))
            }
        } else {
            hasTriggeredThisIdlePeriod = false
        }
    }
}
