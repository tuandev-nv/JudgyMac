import SwiftUI

struct SummaryCardView: View {
    let summary: DailySummary

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("🤨").font(.system(size: 48))
                Text("JudgyMac").font(.system(.title, design: .rounded, weight: .bold))
                Text(summary.formattedDate).font(.caption).foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("TODAY YOU:").font(.caption2).foregroundStyle(.secondary).tracking(1)
                ForEach(Array(summary.highlights.enumerated()), id: \.offset) { _, highlight in
                    HStack(spacing: 8) {
                        Circle().fill(.purple).frame(width: 5, height: 5)
                        Text(highlight).font(.callout)
                    }
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            if let roast = summary.topRoast {
                RoastBubble(text: roast.text, personality: roast.personality, mood: roast.mood)
            }

            VStack(spacing: 4) {
                Text("VERDICT").font(.caption2).foregroundStyle(.secondary).tracking(2)
                Text("\"\(summary.verdict)\"")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.purple)
            }

            Spacer()
            Text("judgymac.com").font(.caption).foregroundStyle(.tertiary)
        }
        .padding(32)
        .frame(width: 360, height: 480)
        .background(Color(.windowBackgroundColor))
    }
}

extension SummaryCardView {
    @MainActor
    func renderToImage(scale: CGFloat = 3.0) -> NSImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = scale
        return renderer.nsImage
    }
}
