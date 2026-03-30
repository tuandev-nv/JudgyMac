import SwiftUI

/// Scrollable list of recent roasts.
struct HistoryView: View {
    let history: [RoastEntry]
    let onCopy: (RoastEntry) -> Void

    var body: some View {
        VStack(spacing: 12) {
            header

            if history.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(history) { entry in
                            HistoryRow(entry: entry, onCopy: onCopy)
                        }
                    }
                }
                .frame(maxHeight: 320)
            }
        }
        .padding(Theme.Layout.cardPadding)
        .frame(width: Theme.Layout.popoverWidth)
        .background(Color(.windowBackgroundColor))
    }

    private var header: some View {
        HStack {
            Text("Roast History")
                .font(Theme.Fonts.heading)
                .foregroundStyle(Theme.Colors.textPrimary)
            Spacer()
            Text("\(history.count) roasts")
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("😐")
                .font(.system(size: 36))
            Text("No roasts yet")
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.textSecondary)
            Text("Do something questionable and check back.")
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - History Row

private struct HistoryRow: View {
    let entry: RoastEntry
    let onCopy: (RoastEntry) -> Void

    var body: some View {
        GlassCard(padding: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.text)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(3)

                HStack {
                    Text("\(entry.mood.emoji) \(entry.personality)")
                        .font(Theme.Fonts.label)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    Spacer()

                    Text(entry.timeAgo)
                        .font(Theme.Fonts.label)
                        .foregroundStyle(Theme.Colors.textTertiary)

                    Button {
                        onCopy(entry)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("Copy roast")
                }
            }
        }
    }
}
