import Foundation

/// Orchestrates slap events: picks character pack, plays sound combo, shows animation.
/// Listens for `.slap` BehaviorEvents via NotificationCenter.
@MainActor
final class SlapPresenter {
    private let appState: AppState
    private nonisolated(unsafe) var observer: NSObjectProtocol?

    private static let milestoneRoasts = [
        "{count} slaps today. You've made slapping great again. Tremendous. The best slapping anyone has ever seen.",
        "{count} slaps! That's more hits than my approval ratings. And my ratings are VERY high. Believe me.",
        "You've slapped me {count} times today. I've been impeached TWICE and this is worse. Much worse.",
        "{count} slaps. Nobody in the history of this country has been slapped more than me. NOBODY. It's a record.",
    ]

    init(appState: AppState) {
        self.appState = appState
        observeEvents()
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    private func observeEvents() {
        observer = NotificationCenter.default.addObserver(
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
        let source = event.metadata["source"] ?? "trackpad"

        #if DEBUG
        print("👋 [SlapPresenter] Slap detected! Source: \(source), Pack: \(pack.displayName)")
        #endif

        // Always do normal slap animation
        SlapWindow.shared.slap(pack: pack)

        // Milestone roast every 100 slaps
        if appState.todayStats.slapCount > 0 && appState.todayStats.slapCount % 100 == 0 {
            let milestone = Self.milestoneRoasts.randomElement()!
            let count = appState.todayStats.slapCount
            let text = milestone.replacingOccurrences(of: "{count}", with: "\(count)")
            let entry = RoastEntry(
                text: text,
                personality: pack.displayName,
                triggerType: .slap,
                mood: .raging,
                customEmoji: pack.randomEmoji()
            )
            appState.deliverRoast(entry)
            if appState.toastEnabled {
                ToastWindow.shared.show(roast: entry)
            }
        }

        if source == "body" {
            // Physical slap → also trigger desktop runner simultaneously
            NotificationCenter.default.post(name: .hideMenuBarSprite, object: nil)
            DesktopRunnerWindow.shared.run(pack: pack) {
                NotificationCenter.default.post(name: .showMenuBarSprite, object: nil)
            }
        }
    }
}
