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

            Section("Character Pack") {
                Picker("Pack", selection: $state.selectedCharacterPack) {
                    ForEach(CharacterPackCatalog.all) { pack in
                        HStack(spacing: 12) {
                            packIcon(pack)
                                .frame(width: 72, height: 72)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color(white: 0.92))
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))

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
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private func packIcon(_ pack: CharacterPack) -> some View {
        let avatarPath = "\(pack.folderPath)/avatar"
        let iconPath = pack.iconImagePath
        if let url = Bundle.main.resourceURL?.appendingPathComponent("\(avatarPath).png"),
           let nsImage = NSImage(contentsOf: url) {
            Image(nsImage: nsImage)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .aspectRatio(contentMode: .fill)
        } else if !iconPath.isEmpty,
                  let url = Bundle.main.resourceURL?.appendingPathComponent("\(iconPath).png"),
                  let nsImage = NSImage(contentsOf: url) {
            Image(nsImage: nsImage)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .aspectRatio(contentMode: .fill)
        } else {
            Text("🤨").font(.system(size: 24))
        }
    }
}

// MARK: - Triggers Tab

struct TriggersSettingsTab: View {
    @Environment(AppState.self) private var appState
    var body: some View {
        Form {
            Section {
                ForEach(TriggerType.allCases, id: \.self) { trigger in
                    Toggle(isOn: triggerBinding(for: trigger)) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 8) {
                                Image(systemName: trigger.icon)
                                    .foregroundStyle(.purple)
                                    .frame(width: 18)
                                Text(trigger.displayName)
                                    .font(.system(size: 13, weight: .medium))
                            }
                            Text(trigger.triggerDescription)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .padding(.leading, 26)
                        }
                        .padding(.vertical, 2)
                    }
                }
            } header: {
                Text("Behavior Triggers")
            } footer: {
                Text("Each trigger has a 2-minute cooldown to avoid spam.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
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
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                            .foregroundStyle(.secondary)
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
