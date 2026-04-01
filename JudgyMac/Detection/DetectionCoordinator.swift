import Foundation

/// Orchestrates all behavior detectors.
/// Routes detected events to the AppState and RoastEngine pipeline.
@MainActor
final class DetectionCoordinator {
    private let appState: AppState
    private var detectors: [TriggerType: any BehaviorDetector] = [:]
    private var isRunning = false

    init(appState: AppState) {
        self.appState = appState
        setupDetectors()
    }

    // MARK: - Setup

    private func setupDetectors() {
        let lidDetector = LidDetector()
        detectors[.lidOpen] = lidDetector
        detectors[.lidReopen] = lidDetector

        // TimeOfDayDetector polls every 30min — fires even without lid open/close
        let timeDetector = TimeOfDayDetector()
        detectors[.lateNight] = timeDetector
        detectors[.earlyMorning] = timeDetector

        detectors[.idle] = IdleDetector()
        detectors[.screenTime] = ScreenTimeDetector()
        detectors[.appSwitch] = AppSwitchDetector()
        detectors[.thermal] = ThermalDetector()
        #if ACCELEROMETER_ENABLED
        detectors[.slap] = AccelerometerDetector()
        #else
        detectors[.slap] = SlapDetector()
        #endif
    }

    // MARK: - Start / Stop

    func start() {
        guard !isRunning else { return }
        isRunning = true
        #if DEBUG
        print("🤨 [Coordinator] Starting detectors... Enabled triggers: \(appState.enabledTriggers.map(\.rawValue))")
        #endif

        // Collect unique detectors (some triggers share the same detector)
        var started: Set<ObjectIdentifier> = []

        for (triggerType, detector) in detectors {
            let id = ObjectIdentifier(detector)

            // Skip if trigger is disabled by user
            guard appState.enabledTriggers.contains(triggerType) else { continue }

            // Skip if already started (shared detector)
            guard !started.contains(id) else { continue }
            started.insert(id)

            detector.start { [weak self] event in
                Task { @MainActor in
                    self?.handleEvent(event)
                }
            }
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false

        var stopped: Set<ObjectIdentifier> = []
        for (_, detector) in detectors {
            let id = ObjectIdentifier(detector)
            guard !stopped.contains(id) else { continue }
            stopped.insert(id)
            detector.stop()
        }
    }

    func restart() {
        stop()
        start()
    }

    // MARK: - Event Handling

    private func handleEvent(_ event: BehaviorEvent) {
        // Check if this trigger type is enabled
        guard appState.enabledTriggers.contains(event.type) else { return }

        // Update app state (mood + stats)
        appState.handleEvent(event)

        // Post notification for RoastEngine to pick up
        NotificationCenter.default.post(
            name: .behaviorEventDetected,
            object: nil,
            userInfo: ["event": event]
        )
    }

    // All 6 triggers work without special permissions
}

// MARK: - Notification Name

extension Notification.Name {
    static let behaviorEventDetected = Notification.Name("com.judgymac.behaviorEventDetected")
    static let hideMenuBarSprite = Notification.Name("com.judgymac.hideMenuBarSprite")
    static let showMenuBarSprite = Notification.Name("com.judgymac.showMenuBarSprite")
}
