import Foundation

/// Clock-based trigger detection.
/// This detector doesn't run on its own — it's called by LidDetector
/// to add time-of-day context when the lid opens.
/// Kept as a separate module for testability and clarity.
final class TimeOfDayDetector: BehaviorDetector, @unchecked Sendable {
    private(set) var isRunning = false

    private var onEvent: (@Sendable (BehaviorEvent) -> Void)?
    private var timer: Timer?
    private var lastTriggeredDate: Date?  // Only fire once per night

    func start(onEvent: @escaping @Sendable (BehaviorEvent) -> Void) {
        guard !isRunning else { return }
        self.onEvent = onEvent
        isRunning = true

        // First check after 10 minutes
        timer = Timer.scheduledTimer(
            withTimeInterval: 600,
            repeats: false
        ) { [weak self] _ in
            self?.checkTimeOfDay()
            // Then every 45 minutes
            self?.timer = Timer.scheduledTimer(
                withTimeInterval: 2700,
                repeats: true
            ) { [weak self] _ in
                self?.checkTimeOfDay()
            }
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

        // Check both keyboard AND mouse activity
        let keyIdle = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .keyDown
        )
        let mouseIdle = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .mouseMoved
        )
        let idleSeconds = min(keyIdle, mouseIdle)

        // User was active in last 5 minutes during late hours
        guard idleSeconds < 300 else { return }

        // Only trigger once per night (reset when leaving late hours)
        if hour >= Constants.Detection.lateNightStartHour,
           hour < Constants.Detection.lateNightEndHour {
            guard !Calendar.current.isDateInToday(lastTriggeredDate ?? .distantPast)  else { return }
            lastTriggeredDate = Date()
            onEvent?(.lateNight(hour: hour))
        } else if hour >= Constants.Detection.earlyMorningStartHour,
                  hour < Constants.Detection.earlyMorningEndHour {
            guard !Calendar.current.isDateInToday(lastTriggeredDate ?? .distantPast) else { return }
            lastTriggeredDate = Date()
            onEvent?(.earlyMorning(hour: hour))
        } else {
            // Daytime — reset for next night
            lastTriggeredDate = nil
        }
    }
}

import CoreGraphics
