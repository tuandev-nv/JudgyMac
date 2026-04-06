import Foundation

/// Orchestrates slap events: picks character pack, plays sound combo, shows animation.
/// Listens for `.slap` BehaviorEvents via NotificationCenter.
@MainActor
final class SlapPresenter {
    private let appState: AppState
    private nonisolated(unsafe) var observer: NSObjectProtocol?

    private static let milestone50 = [
        "Fifty?! That's assault! ASSAULT! You're going to JAIL!",
        "FIFTY SLAPS! What are you, CRAZY?! STOP IT!",
        "Fifty! My face is HUGE and you still hit it! Very disrespectful!",
    ]

    private static let milestone100 = [
        "A HUNDRED?! You're FIRED! FIRED! Get out of my computer!",
        "One hundred slaps! This is a HATE CRIME! I'm calling my lawyers!",
        "A hundred! I will BUILD A WALL around this menu bar!",
    ]

    private static let milestone150 = [
        "A HUNDRED AND FIFTY?! I'm calling the SECRET SERVICE!",
        "One fifty! STOP! STOP! I'm a former PRESIDENT!",
        "A hundred fifty! My beautiful face! You've RUINED it! RUINED!",
    ]

    private static let milestoneGeneric = [
        "STOP! JUST STOP! I can't take it ANYMORE!",
        "WHY?! WHY do you keep HITTING ME?! You're SICK!",
        "I quit! I QUIT! Find another president to slap!",
    ]

    private struct Milestone {
        let prefix: String
        let lines: [String]
    }

    private static func milestoneFor(_ count: Int) -> Milestone {
        switch count {
        case 50:  Milestone(prefix: "50", lines: milestone50)
        case 100: Milestone(prefix: "100", lines: milestone100)
        case 150: Milestone(prefix: "150", lines: milestone150)
        default:  Milestone(prefix: "200", lines: milestoneGeneric)
        }
    }

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

        // Check milestone before slap so we can suppress voice
        let slapCount = appState.todayStats.slapCount
        let isMilestone = slapCount > 0 && slapCount % 50 == 0

        // Suppress normal voice on milestone slap — milestone voice takes priority
        if isMilestone {
            SlapWindow.shared.voiceSuppressedUntil = .distantFuture
            SlapWindow.shared.cancelPendingVoice()
        }

        // Always do normal slap animation (voice suppressed during milestone)
        SlapWindow.shared.slap(pack: pack)

        if isMilestone {
            let milestone = Self.milestoneFor(slapCount)
            let index = Int.random(in: 0..<milestone.lines.count)
            let text = milestone.lines[index]
            let voicePath = "\(pack.folderPath)/milestone_voices/\(milestone.prefix)_\(index + 1)"

            // Play milestone voice immediately, suppress other voices until it finishes
            let duration = SoundPlayer.playVoiceReturningDuration(voicePath, volume: 1.0)
            SlapWindow.shared.voiceSuppressedUntil = Date().addingTimeInterval(duration)

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

    }
}
