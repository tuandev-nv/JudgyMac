import Foundation

/// Clock-based trigger detection for late night / early morning usage.
/// Uses shared ActivityMonitor instead of polling CGEventSource directly.
final class TimeOfDayDetector: BehaviorDetector, @unchecked Sendable {
    private(set) var isRunning = false

    private var onEvent: (@Sendable (BehaviorEvent) -> Void)?
    private var timer: Timer?
    private var lastTriggeredDate: Date?  // Only fire once per night

    func start(onEvent: @escaping @Sendable (BehaviorEvent) -> Void) {
        guard !isRunning else { return }
        self.onEvent = onEvent
        isRunning = true

        ActivityMonitor.shared.subscribe()

        // First check after 5 minutes, then every 15 minutes
        timer = Timer.scheduledTimer(
            withTimeInterval: 300,
            repeats: false
        ) { [weak self] _ in
            self?.checkTimeOfDay()
            self?.timer = Timer.scheduledTimer(
                withTimeInterval: 900,
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
        ActivityMonitor.shared.unsubscribe()
    }

    private func checkTimeOfDay() {
        let hour = Calendar.current.component(.hour, from: Date())
        let idleSeconds = ActivityMonitor.shared.idleSeconds

        // User was active in last 5 minutes during late hours
        guard idleSeconds < 300 else { return }

        if hour >= Constants.Detection.lateNightStartHour,
           hour < Constants.Detection.lateNightEndHour {
            guard !Calendar.current.isDateInToday(lastTriggeredDate ?? .distantPast) else { return }
            lastTriggeredDate = Date()
            onEvent?(.lateNight(hour: hour))
        } else if hour >= Constants.Detection.earlyMorningStartHour,
                  hour < Constants.Detection.earlyMorningEndHour {
            guard !Calendar.current.isDateInToday(lastTriggeredDate ?? .distantPast) else { return }
            lastTriggeredDate = Date()
            onEvent?(.earlyMorning(hour: hour))
        } else {
            lastTriggeredDate = nil
        }
    }
}
