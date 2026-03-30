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
                fluentFace(mood: appState.currentMood, size: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text("JudgyMac")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    HStack(spacing: 8) {
                        Text(appState.todayStats.todayVibe)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        if appState.cpuUsage > 0.01 {
                            Text("CPU \(Int(appState.cpuUsage * 100))%")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(appState.cpuUsage > 0.7 ? .red : .secondary)
                        }
                    }
                }
                Spacer()
            }

            // Roast
            roastBubble

            // Stats
            statsRow

            // Judgment bar
            judgmentBar

            // DEBUG: Test button (remove before release)
            Button {
                let event = BehaviorEvent.lidOpen(count: appState.todayStats.lidOpenCount + 1)
                appState.handleEvent(event)
                NotificationCenter.default.post(
                    name: .behaviorEventDetected,
                    object: nil,
                    userInfo: ["event": event]
                )
            } label: {
                Text("🧪 Test Roast")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(.purple.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }

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
                fluentFace(mood: roast?.mood ?? .neutral, size: 24)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.purple.opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Stats

    private var statsRow: some View {
        let stats = appState.todayStats
        return HStack(spacing: 8) {
            StatPill(icon: "laptopcomputer", value: "\(stats.lidOpenCount)", label: "Opens")
            StatPill(icon: "flame", value: "\(stats.roastCount)", label: "Roasts")
            StatPill(icon: "zzz", value: "\(stats.maxIdleMinutes)m", label: "Idle")
            StatPill(icon: "keyboard", value: "\(stats.keystrokeCount)", label: "Keys")
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

            BarButton(icon: "doc.on.doc", label: "Copy") {
                if let roast = appState.currentRoast {
                    SummaryShareHelper.copyRoastText(roast)
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
                        ForEach(appState.roastHistory) { entry in
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
    }
}

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
