import Foundation

/// Detects Mac overheating via ProcessInfo.thermalState.
/// Triggers: thermal (when state reaches .serious or .critical)
/// No special permissions required.
final class ThermalDetector: BehaviorDetector, @unchecked Sendable {
    private(set) var isRunning = false

    private var onEvent: (@Sendable (BehaviorEvent) -> Void)?
    private var observer: NSObjectProtocol?
    private var lastReportedState: ProcessInfo.ThermalState?

    func start(onEvent: @escaping @Sendable (BehaviorEvent) -> Void) {
        guard !isRunning else { return }
        self.onEvent = onEvent
        isRunning = true

        observer = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleThermalChange()
        }

        // Check current state on start
        handleThermalChange()
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        if let observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
    }

    private func handleThermalChange() {
        let state = ProcessInfo.processInfo.thermalState

        // Only trigger on serious/critical, and only if state changed
        guard state != lastReportedState else { return }
        lastReportedState = state

        switch state {
        case .serious:
            onEvent?(.thermal(state: "serious"))
        case .critical:
            onEvent?(.thermal(state: "critical"))
        case .nominal, .fair:
            break // Back to normal, no event
        @unknown default:
            break
        }
    }
}
