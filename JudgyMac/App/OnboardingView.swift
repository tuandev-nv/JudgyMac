import SwiftUI

struct OnboardingView: View {
    let appState: AppState
    @State private var currentPage = 0
    let onComplete: () -> Void

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage.tag(0)
            triggersPage.tag(1)
            personalityPage.tag(2)
            permissionsPage.tag(3)
        }
        .tabViewStyle(.automatic)
        .frame(width: 440, height: 500)
    }

    private var welcomePage: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("🤨").font(.system(size: 72))
            Text("Meet Your New Judge").font(.title.bold())
            Text("Your MacBook is about to develop\na very strong personality.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            nextButton
        }
        .padding(32)
    }

    private var triggersPage: some View {
        VStack(spacing: 16) {
            Text("What I'll Watch").font(.title2.bold())
            Text("Toggle which behaviors trigger roasts").font(.caption).foregroundStyle(.secondary)
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(TriggerType.allCases, id: \.self) { trigger in
                        HStack {
                            Image(systemName: trigger.icon).frame(width: 24).foregroundStyle(.purple)
                            Text(trigger.displayName).font(.callout)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { appState.enabledTriggers.contains(trigger) },
                                set: { on in
                                    if on { appState.enabledTriggers.insert(trigger) }
                                    else { appState.enabledTriggers.remove(trigger) }
                                }
                            )).labelsHidden()
                        }
                        .padding(8)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            nextButton
        }
        .padding(32)
    }

    private var personalityPage: some View {
        VStack(spacing: 16) {
            Text("Pick Your Poison").font(.title2.bold())
            RoastBubble(
                text: "You opened this lid 7 times today. What are you looking for? Meaning? It's not in there.",
                personality: "The Critic",
                mood: .judging
            )
            Text("6 personalities included").font(.caption).foregroundStyle(.secondary)
            nextButton
        }
        .padding(32)
    }

    private var permissionsPage: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("🔔").font(.system(size: 48))
            Text("Ready to Be Judged?").font(.title2.bold())
            Text("JudgyMac needs notification permission\nto deliver its honest commentary.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button {
                appState.isOnboarded = true
                UserDefaults.standard.set(true, forKey: SettingsStore.Keys.isOnboarded)
                onComplete()
            } label: {
                Text("Let the judging begin")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(32)
    }

    private var nextButton: some View {
        Button { withAnimation { currentPage += 1 } } label: {
            Text("Next")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.purple)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
