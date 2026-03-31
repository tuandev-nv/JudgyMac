import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @State private var showHistory = false

    // Actions handled by AppDelegate (closes popover first)
    var onOpenSettings: () -> Void = {}
    var onShare: () -> Void = {}
    var onQuit: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            if showHistory {
                historyContent
            } else {
                mainContent
            }

            Divider()
            bottomBar
        }
        .frame(width: 360)
    }

    // MARK: - Main

    private var mainContent: some View {
        VStack(spacing: 14) {
            // Header
            HStack(spacing: 12) {
                packIcon(pack: appState.currentPack, size: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text("JudgyMac")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text(appState.currentPack.displayName)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Roast (only show when there's an actual roast)
            if appState.currentRoast != nil {
                roastBubble
            }

            // Stats
            statsRow

            // Judgment bar
            judgmentBar

            #if DEBUG
            devTools
            #endif
        }
        .padding(16)
    }

    // MARK: - Dev Tools (DEBUG only)

    #if DEBUG
    @State private var devExpanded = true

    private var devTools: some View {
        DisclosureGroup(isExpanded: $devExpanded) {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)
            LazyVGrid(columns: columns, spacing: 6) {
                DevGridButton(icon: "🧪", label: "Lid Open") {
                    fireDevEvent(.lidOpen(count: appState.todayStats.lidOpenCount + 1))
                }
                DevGridButton(icon: "😴", label: "Idle") {
                    fireDevEvent(.idle(minutes: 30))
                }
                DevGridButton(icon: "🌙", label: "Late Night") {
                    fireDevEvent(.lateNight(hour: 3))
                }
                DevGridButton(icon: "🌅", label: "Morning") {
                    fireDevEvent(.earlyMorning(hour: 6))
                }
                DevGridButton(icon: "🔥", label: "Thermal") {
                    fireDevEvent(.thermal(state: "critical"))
                }
                DevGridButton(icon: "👋", label: "Slap") {
                    fireDevEvent(.slap(pressure: 0.95))
                }
                DevGridButton(icon: "🔄", label: "App Switch") {
                    fireDevEvent(.appSwitch(count: 15, app: "Safari"))
                }
                DevGridButton(icon: "🖥", label: "Screen Time") {
                    fireDevEvent(.screenTime(minutes: 90))
                }
                DevGridButton(icon: "🗑", label: "Reset") {
                    appState.todayStats = UserStats()
                    appState.currentRoast = nil
                    appState.currentMood = .neutral
                }
            }
        } label: {
            Button {
                withAnimation { devExpanded.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Text("🛠 Dev Tools")
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.secondary)
        .padding(8)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    private func fireDevEvent(_ event: BehaviorEvent) {
        appState.handleEvent(event)
        NotificationCenter.default.post(
            name: .behaviorEventDetected,
            object: nil,
            userInfo: ["event": event]
        )
    }
    #endif

    // MARK: - Roast

    private var roastBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            let roast = appState.currentRoast
            Text(roast?.text ?? "Watching you... waiting for you to do something questionable.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text("— \(roast?.personality ?? "The Critic")")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                packIcon(pack: appState.currentPack, size: 32)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.purple.opacity(0.15), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current roast: \(appState.currentRoast?.text ?? "No roast yet") by \(appState.currentRoast?.personality ?? "The Critic")")
    }

    // MARK: - Stats

    private var statsRow: some View {
        let stats = appState.todayStats
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)
        return LazyVGrid(columns: columns, spacing: 6) {
            StatPill(icon: "laptopcomputer", value: "\(stats.lidOpenCount)", label: "Opens")
            StatPill(icon: "flame", value: "\(stats.roastCount)", label: "Roasts")
            StatPill(icon: "clock.arrow.circlepath", value: "\(stats.screenTimeMinutes)m", label: "Screen")
            StatPill(icon: "hand.raised", value: "\(stats.slapCount)", label: "Slaps")
            StatPill(icon: "arrow.left.arrow.right", value: "\(stats.appSwitchCount)", label: "Alt-Tab")
            StatPill(icon: "thermometer.sun.fill", value: "\(stats.thermalCount)", label: "Overheat")
        }
    }

    // MARK: - Judgment Bar

    private var judgmentBar: some View {
        VStack(spacing: 5) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary).frame(height: 5)
                    Capsule()
                        .fill(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(geo.size.width * appState.todayStats.judgmentLevel, 5), height: 5)
                }
            }
            .frame(height: 5)

            HStack {
                Text("Unjudged").font(.system(size: 10)).foregroundStyle(.tertiary)
                Spacer()
                Text("Fully Roasted").font(.system(size: 10)).foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 0) {
            if showHistory {
                BarButton(icon: "chevron.left", label: "Back", color: .purple) {
                    showHistory = false
                }
            } else {
                BarButton(icon: "clock", label: "History") {
                    showHistory = true
                }
            }

            BarButton(icon: "gearshape", label: "Settings") {
                onOpenSettings()
            }

            BarButton(icon: "xmark.circle", label: "Quit") {
                onQuit()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
    }

    // MARK: - History

    private var historyContent: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Roast History")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
                Text("\(appState.roastHistory.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(.quaternary, in: Capsule())
            }

            if appState.roastHistory.isEmpty {
                VStack(spacing: 8) {
                    Text("😐").font(.system(size: 32))
                    Text("No roasts yet")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(appState.roastHistory.reversed()) { entry in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(entry.text)
                                    .font(.system(size: 12, design: .rounded))
                                    .lineLimit(2)

                                HStack {
                                    Text("\(entry.mood.emoji) \(entry.personality)")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(entry.timeAgo)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.tertiary)
                                    Button {
                                        SummaryShareHelper.copyRoastText(entry)
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.tertiary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(10)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
        .padding(16)
    }
}

// MARK: - Pack Icon Helper

private func packIcon(pack: CharacterPack, size: CGFloat) -> some View {
    Group {
        // Try avatar first (square crop), fallback to icon
        let avatarPath = "\(pack.folderPath)/avatar"
        let iconPath = pack.iconImagePath
        if let url = Bundle.main.resourceURL?.appendingPathComponent("\(avatarPath).png"),
           let nsImage = NSImage(contentsOf: url) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if !iconPath.isEmpty,
                  let url = Bundle.main.resourceURL?.appendingPathComponent("\(iconPath).png"),
                  let nsImage = NSImage(contentsOf: url) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Text("🤨").font(.system(size: size * 0.8))
        }
    }
    .frame(width: size, height: size)
    .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
}

// MARK: - Fluent Emoji Helper

private func fluentFace(mood: Mood, size: CGFloat) -> some View {
    Group {
        let name = FluentEmoji.primary(for: mood)
        if let img = FluentEmoji.swiftUIImage(named: name) {
            img.resizable().aspectRatio(contentMode: .fit)
        } else {
            Text(mood.emoji).font(.system(size: size * 0.8))
        }
    }
    .frame(width: size, height: size)
}

// MARK: - Bar Button

private struct BarButton: View {
    let icon: String
    let label: String
    var color: Color = .secondary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - Stat Pill

private struct StatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .contentTransition(.numericText())

            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Dev Grid Button (DEBUG only)

#if DEBUG
private struct DevGridButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(icon).font(.system(size: 16))
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}
#endif

// MARK: - Previews

#Preview("Popover") {
    MenuBarView()
        .environment(AppState())
}

#Preview("Popover with roast") {
    let state = AppState()
    state.currentRoast = RoastEntry(
        text: "You opened this lid 7 times today. What are you looking for? Meaning? It's not in there.",
        personality: "The Critic",
        triggerType: .lidOpen,
        mood: .judging
    )
    state.todayStats.lidOpenCount = 7
    state.todayStats.roastCount = 3
    state.todayStats.maxIdleMinutes = 23
    state.todayStats.keystrokeCount = 847
    return MenuBarView()
        .environment(state)
}
