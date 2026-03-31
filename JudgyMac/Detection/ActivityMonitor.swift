import CoreGraphics
import Foundation

/// Shared activity monitor — polls CGEventSource once per interval
/// so multiple detectors don't make redundant system calls.
final class ActivityMonitor: @unchecked Sendable {
    static let shared = ActivityMonitor()

    /// Cached idle seconds (updated every poll)
    private(set) var idleSeconds: TimeInterval = 0

    private var timer: Timer?
    private var refCount = 0
    private let pollInterval: TimeInterval = 60

    private init() {}

    /// Call from each detector's start(). Starts polling on first subscriber.
    func subscribe() {
        refCount += 1
        guard timer == nil else { return }
        poll() // Immediate first read
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    /// Call from each detector's stop(). Stops polling when no subscribers remain.
    func unsubscribe() {
        refCount = max(refCount - 1, 0)
        guard refCount == 0 else { return }
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        let mouseIdle = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState, eventType: .mouseMoved
        )
        let keyIdle = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState, eventType: .keyDown
        )
        idleSeconds = min(mouseIdle, keyIdle)
    }
}
