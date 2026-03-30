import Foundation

/// Orchestrates slap events: picks character, plays sound combo, shows animation.
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
        let characterId = appState.selectedSlapCharacter
        let character = SlapCharacterCatalog.character(for: characterId)
            ?? SlapCharacterCatalog.defaultCharacter

        #if DEBUG
        print("👋 [SlapPresenter] Slap detected! Character: \(character.displayName)")
        #endif

        SlapWindow.shared.slap(character: character)
    }
}
