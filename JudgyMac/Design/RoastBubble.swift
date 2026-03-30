import SwiftUI

struct RoastBubble: View {
    let text: String
    let personality: String
    let mood: Mood

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(Theme.Fonts.roastText)
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineSpacing(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text("— \(personality)")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Spacer()
                Text(mood.emoji)
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.accent(for: mood).opacity(0.15), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.Colors.accent(for: mood).opacity(0.2), lineWidth: 0.5)
        )
    }
}
