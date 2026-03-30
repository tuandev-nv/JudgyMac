import SwiftUI
import ServiceManagement

// Keep SettingsView for SwiftUI Settings scene compatibility (unused but required)
struct SettingsView: View {
    @Environment(AppState.self) private var appState
    var body: some View { EmptyView() }
}

// MARK: - General Tab

struct GeneralSettingsTab: View {
    @Environment(AppState.self) private var appState
    @State private var launchAtLogin = AppDelegate.isLaunchAtLoginEnabled

    var body: some View {
        @Bindable var state = appState

        Form {
            Section {
                Toggle("Start at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        AppDelegate.setLaunchAtLogin(newValue)
                    }
            }

            Section("Roast Intensity") {
                Picker("Level", selection: $state.intensity) {
                    Text("Mild — gentle nudges").tag(1)
                    Text("Medium — solid roasts").tag(2)
                    Text("Savage — no mercy").tag(3)
                }
                .pickerStyle(.radioGroup)
                .onChange(of: appState.intensity) { _, _ in SettingsStore.save(appState) }

                LabeledContent("Daily roast limit") {
                    Text("50 per day")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Today") {
                LabeledContent("Roasts received") {
                    Text("\(appState.todayStats.roastCount)")
                }
                LabeledContent("Lid opens") {
                    Text("\(appState.todayStats.lidOpenCount)")
                }
                LabeledContent("Max idle") {
                    Text("\(appState.todayStats.maxIdleMinutes) min")
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Triggers Tab

struct TriggersSettingsTab: View {
    @Environment(AppState.self) private var appState
    var body: some View {
        Form {
            Section("Behavior Triggers") {
                ForEach(TriggerType.allCases, id: \.self) { trigger in
                    Toggle(isOn: triggerBinding(for: trigger)) {
                        HStack(spacing: 10) {
                            Image(systemName: trigger.icon)
                                .foregroundStyle(.purple)
                                .frame(width: 20)
                            Text(trigger.displayName)
                        }
                    }
                }
            }

            Section("No special permissions needed") {
                Text("All 6 triggers work without any extra permissions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Cooldowns") {
                LabeledContent("Between same trigger") {
                    Text("5 minutes").foregroundStyle(.secondary)
                }
                LabeledContent("Same roast repeat") {
                    Text("24 hours").foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func triggerBinding(for trigger: TriggerType) -> Binding<Bool> {
        Binding(
            get: { appState.enabledTriggers.contains(trigger) },
            set: { enabled in
                if enabled { appState.enabledTriggers.insert(trigger) }
                else { appState.enabledTriggers.remove(trigger) }
                SettingsStore.save(appState)
            }
        )
    }
}

// MARK: - Personality Tab

struct PersonalitySettingsTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        Form {
            Section("Active Personality") {
                Picker("Judge", selection: $state.selectedPersonality) {
                    ForEach(PersonalityPack.catalog) { pack in
                        HStack(spacing: 8) {
                            Text(packEmoji(pack.id))
                            Text(pack.displayName)
                            Text("— \(pack.language.uppercased())")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .tag(pack.id)
                    }
                }
                .pickerStyle(.radioGroup)
                .onChange(of: appState.selectedPersonality) { _, _ in SettingsStore.save(appState) }
            }

            Section("Preview") {
                Text(previewText(for: appState.selectedPersonality))
                    .font(.system(.body, design: .rounded))
                    .italic()
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
    }

    private func packEmoji(_ id: String) -> String {
        switch id {
        case "the-critic": return "🤨"
        case "vietnamese-mom": return "🇻🇳"
        case "toxic-boss": return "👔"
        case "drill-sergeant": return "🎖️"
        case "shakespeare": return "🎭"
        case "therapist": return "🛋️"
        default: return "😐"
        }
    }

    private func previewText(for id: String) -> String {
        switch id {
        case "the-critic":
            return "\"You've opened this lid 7 times. What are you looking for? Meaning? It's not in there.\""
        case "vietnamese-mom":
            return "\"Lại mở máy rồi. Hôm nay 7 lần rồi đó. Con nhà người ta thì đi ngủ sớm.\""
        case "toxic-boss":
            return "\"Per my last observation, that's excessive. Going forward, be more intentional.\""
        case "drill-sergeant":
            return "\"LAPTOP OPEN #7! DROP AND GIVE ME TWENTY PRODUCTIVE MINUTES!\""
        case "shakespeare":
            return "\"What light through yonder lid breaks? 'Tis the fool, returning for the 7th time.\""
        case "therapist":
            return "\"So, you've opened your laptop 7 times. How does that make you feel?\""
        default:
            return ""
        }
    }
}

// MARK: - About Tab

struct AboutSettingsTab: View {
    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Text("🤨").font(.system(size: 48))
                        Text("JudgyMac").font(.title2.bold())
                        Text("Version 1.0.0 (1)").foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }

            Section {
                LabeledContent("Website") {
                    Link("judgymac.com", destination: URL(string: "https://judgymac.com")!)
                }
                LabeledContent("Support") {
                    Link("support@judgymac.com", destination: URL(string: "mailto:support@judgymac.com")!)
                }
            }

            Section {
                LabeledContent("License") {
                    Text("One-time purchase. All updates included.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }
}
