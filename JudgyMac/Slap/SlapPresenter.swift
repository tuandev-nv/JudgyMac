import Foundation

/// Orchestrates slap events: picks character pack, plays sound combo, shows animation.
/// Listens for `.slap` BehaviorEvents via NotificationCenter.
@MainActor
final class SlapPresenter {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        observeEvents()
    }

    private func observeEvents() {
        NotificationCenter.default.addObserver(
            forName: .behaviorEventDetected,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let event = notification.userInfo?["event"] as? BehaviorEvent,
                  event.type == .slap else { return }
            Task { @MainActor in
                self?.handleSlap(event)
            }
        }
    }

    private func handleSlap(_ event: BehaviorEvent) {
        let pack = appState.currentPack

        #if DEBUG
        print("👋 [SlapPresenter] Slap detected! Pack: \(pack.displayName)")
        #endif

        SlapWindow.shared.slap(pack: pack)
    }
}
