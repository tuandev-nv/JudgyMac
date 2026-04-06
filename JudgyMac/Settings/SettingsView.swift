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
    @State private var licenseInput = ""
    @State private var licenseStatus: String?
    @State private var isValidating = false

    var body: some View {
        @Bindable var state = appState

        Form {
            // License
            Section("License") {
                if appState.isLicenseValid {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Text("Activated")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Text("••••••••")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    #if DEBUG
                    Button("Remove License") {
                        appState.licenseKey = ""
                        appState.isLicenseValid = false
                        licenseInput = ""
                        licenseStatus = nil
                        SettingsStore.save(appState)
                    }
                    .foregroundStyle(.red)
                    .font(.system(size: 11))
                    #endif
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            LeftAlignedTextField(text: $licenseInput, placeholder: "Enter license key")
                            Button(isValidating ? "Validating..." : "Activate") {
                                activateLicense()
                            }
                            .disabled(licenseInput.isEmpty || isValidating)
                        }
                        if let status = licenseStatus {
                            Text(status)
                                .font(.system(size: 11))
                                .foregroundStyle(status.contains("✓") ? .green : .red)
                        }
                        HStack(spacing: 4) {
                            Text("Don't have a key?")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Link("Buy license", destination: URL(string: "https://judgymac.xyz/#pricing")!)
                                .font(.system(size: 11))
                        }
                    }
                }
            }

            if appState.isLicenseValid {
                Section {
                    HStack {
                        Text("Start at login")
                        Spacer()
                        Toggle("", isOn: $launchAtLogin)
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .onChange(of: launchAtLogin) { _, newValue in
                                AppDelegate.setLaunchAtLogin(newValue)
                            }
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

            Section("Updates") {
                HStack {
                    Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?")")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Check for Updates") {
                        AppUpdater.shared.checkForUpdates()
                    }
                }
            }

        }
        .formStyle(.grouped)
        .environment(\.layoutDirection, .leftToRight)
    }

    private func activateLicense() {
        isValidating = true
        licenseStatus = nil
        Task {
            let result = await LicenseManager.validate(key: licenseInput)
            isValidating = false
            switch result {
            case .valid:
                appState.licenseKey = licenseInput.trimmingCharacters(in: .whitespacesAndNewlines)
                appState.isLicenseValid = true
                licenseStatus = "✓ License activated!"
                SettingsStore.save(appState)
                NotificationCenter.default.post(name: .licenseDidActivate, object: nil)
                // Pre-warm assets for instant first slap
                SlapWindow.shared.warmUp(pack: appState.currentPack)
                SoundPlayer.preload([
                    appState.currentPack.slapSoundPath,
                    "\(appState.currentPack.folderPath)/slap_voice",
                ])
            case .invalid:
                licenseStatus = "✗ Invalid license key"
            case .error(let msg):
                licenseStatus = "✗ Error: \(msg)"
            }
        }
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
        @Bindable var state = appState

        if !appState.isLicenseValid {
            VStack(spacing: 12) {
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                Text("Activate your license to configure triggers")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Text("Go to General → License")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {

        Form {
            // Slap + Voice grouped together
            Section("Slap") {
                Toggle(isOn: triggerBinding(for: .slap)) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Image(systemName: TriggerType.slap.icon)
                                .foregroundStyle(.purple)
                                .frame(width: 18)
                            Text(TriggerType.slap.displayName)
                                .font(.system(size: 13, weight: .medium))
                        }
                        Text(TriggerType.slap.triggerDescription)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 26)
                    }
                    .padding(.vertical, 2)
                }
                Toggle("Voice sounds", isOn: $state.voiceEnabled)
                    .onChange(of: appState.voiceEnabled) { _, newValue in
                        SoundPlayer.isMuted = !newValue
                        SettingsStore.save(appState)
                    }

                // Sensitivity slider — only enabled when slap is on
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Slap sensitivity")
                            .font(.system(size: 13))
                        Spacer()
                        Text(String(format: "%.3fg", appState.slapSensitivity))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $state.slapSensitivity, in: 0.02...0.1, step: 0.001)
                        .disabled(!appState.enabledTriggers.contains(.slap))
                        .onChange(of: appState.slapSensitivity) { _, newValue in
                            SettingsStore.save(appState)
                            #if ACCELEROMETER_ENABLED
                            SlapSignalProcessor.magnitudeFloor = newValue
                            #endif
                        }
                    HStack {
                        Text("Butterfly landing")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                        Spacer()
                        Text("Full commitment")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.top, 4)
            }

            // Lid creak toggle
            Section {
                Toggle("Lid creak sound", isOn: $state.lidCreakEnabled)
                    .onChange(of: appState.lidCreakEnabled) { _, _ in
                        SettingsStore.save(appState)
                        NotificationCenter.default.post(name: .lidCreakDidChange, object: nil)
                    }
            }

            // Toast notification toggle
            Section {
                Toggle("Toast notifications", isOn: $state.toastEnabled)
                    .onChange(of: appState.toastEnabled) { _, _ in SettingsStore.save(appState) }
            }

            // Behavior triggers (excluding slap)
            Section {
                ForEach(TriggerType.allCases.filter({ $0 != .slap }), id: \.self) { trigger in
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
                    .disabled(!appState.toastEnabled)
                }
            } header: {
                Text("Behavior Triggers")
            } footer: {
                Text("Each trigger has a 2-minute cooldown to avoid spam.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .opacity(appState.toastEnabled ? 1 : 0.4)
        }
        .formStyle(.grouped)
        .environment(\.layoutDirection, .leftToRight)

        } // else isLicenseValid
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
                NotificationCenter.default.post(name: .triggersDidChange, object: nil)
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
                    Link("judgymac.xyz", destination: URL(string: "https://judgymac.xyz")!)
                }
                LabeledContent("Support") {
                    Link("support@judgymac.xyz", destination: URL(string: "mailto:support@judgymac.xyz")!)
                }
            }

            Section {
                LabeledContent("License") {
                    Text("One-time purchase. All updates included.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Parody & Disclaimer") {
                Text("JudgyMac is a parody and satirical entertainment product. All character voices are AI-generated and clearly fictional. This product is not affiliated with, endorsed by, or associated with any real person. All character likenesses are original caricature artwork created for comedic purposes.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
        .environment(\.layoutDirection, .leftToRight)
    }
}

// MARK: - Left-Aligned TextField (NSViewRepresentable)

struct LeftAlignedTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.placeholderString = placeholder
        field.font = .systemFont(ofSize: 13)
        field.alignment = .left
        field.lineBreakMode = .byTruncatingTail
        field.isBordered = true
        field.isBezeled = true
        field.bezelStyle = .roundedBezel
        field.delegate = context.coordinator
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var text: Binding<String>
        init(text: Binding<String>) { self.text = text }
        func controlTextDidChange(_ obj: Notification) {
            if let field = obj.object as? NSTextField {
                text.wrappedValue = field.stringValue
            }
        }
    }
}
