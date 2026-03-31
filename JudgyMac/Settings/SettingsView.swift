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
        Form {
            Section {
                Toggle("Start at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        AppDelegate.setLaunchAtLogin(newValue)
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
                if enabled {
                    appState.enabledTriggers.insert(trigger)
                } else {
                    appState.enabledTriggers.remove(trigger)
                }
                SettingsStore.save(appState)
            }
        )
    }
}

// MARK: - Character Pack Tab

struct CharacterPackTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        Form {
            Section("Character Pack") {
                Picker("Pack", selection: $state.selectedCharacterPack) {
                    ForEach(CharacterPackCatalog.all) { pack in
                        HStack(spacing: 12) {
                            packIcon(pack)
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(pack.displayName)
                                    .font(.system(size: 13, weight: .semibold))
                                Text(pack.description)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tag(pack.id)
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
                .onChange(of: appState.selectedCharacterPack) { _, _ in SettingsStore.save(appState) }
            }

            Section("Preview") {
                let pack = appState.currentPack
                VStack(alignment: .leading, spacing: 12) {
                    // Sample roast
                    if let sample = pack.templates(for: .lidOpen).first {
                        Text("\"\(sample.text)\"")
                            .font(.system(.body, design: .rounded))
                            .italic()
                            .foregroundStyle(.secondary)
                    }

                    // Pack info
                    HStack(spacing: 16) {
                        Label("\(pack.language.uppercased())", systemImage: "globe")
                        Label("Slap limit: \(pack.slapLimit)", systemImage: "hand.raised")
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private func packIcon(_ pack: CharacterPack) -> some View {
        let path = pack.iconImagePath
        if !path.isEmpty,
           let url = Bundle.main.resourceURL?.appendingPathComponent("\(path).png"),
           let nsImage = NSImage(contentsOf: url) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Text("🤨").font(.system(size: 24))
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
