import Foundation

/// Clock-based trigger detection.
/// This detector doesn't run on its own — it's called by LidDetector
/// to add time-of-day context when the lid opens.
/// Kept as a separate module for testability and clarity.
final class TimeOfDayDetector: BehaviorDetector, @unchecked Sendable {
    private(set) var isRunning = false

    private var onEvent: (@Sendable (BehaviorEvent) -> Void)?
    private var timer: Timer?

    func start(onEvent: @escaping @Sendable (BehaviorEvent) -> Void) {
        guard !isRunning else { return }
        self.onEvent = onEvent
        isRunning = true

        // Check every 30 minutes if user is active during unusual hours
        timer = Timer.scheduledTimer(
            withTimeInterval: 1800,
            repeats: true
        ) { [weak self] _ in
            self?.checkTimeOfDay()
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func checkTimeOfDay() {
        let hour = Calendar.current.component(.hour, from: Date())

        // Only trigger if there's recent user activity (not sleeping Mac)
        let idleSeconds = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .keyDown
        )

        // User was active in last 5 minutes during late hours
        guard idleSeconds < 300 else { return }

        if hour >= Constants.Detection.lateNightStartHour,
           hour < Constants.Detection.lateNightEndHour {
            onEvent?(.lateNight(hour: hour))
        } else if hour >= Constants.Detection.earlyMorningStartHour,
                  hour < Constants.Detection.earlyMorningEndHour {
            onEvent?(.earlyMorning(hour: hour))
        }
    }
}

import CoreGraphics
