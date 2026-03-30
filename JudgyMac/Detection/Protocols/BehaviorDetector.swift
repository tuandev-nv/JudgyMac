import Foundation

/// Protocol for all behavior detectors.
/// Each detector monitors one type of user behavior and emits BehaviorEvents.
protocol BehaviorDetector: AnyObject, Sendable {
    var isRunning: Bool { get }
    func start(onEvent: @escaping @Sendable (BehaviorEvent) -> Void)
    func stop()
}
