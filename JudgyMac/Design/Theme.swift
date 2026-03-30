import SwiftUI

enum Theme {
    // MARK: - Colors (works in both light & dark mode)

    enum Colors {
        // Use semantic system colors — they adapt to light/dark mode automatically
        static let accent = Color.purple
        static let accentSecondary = Color.pink
        static let accentCyan = Color.cyan
        static let accentMint = Color.mint
        static let accentRed = Color.red
        static let accentOrange = Color.orange

        // Text — use system colors for proper contrast
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(.tertiaryLabelColor)

        // Cards
        static let cardBackground = Color(.controlBackgroundColor).opacity(0.5)
        static let cardBorder = Color.primary.opacity(0.06)

        static func accent(for mood: Mood) -> Color {
            switch mood {
            case .neutral:   return .purple
            case .judging:   return .pink
            case .horrified: return .cyan
            case .sleeping:  return .secondary
            case .raging:    return .red
            case .impressed: return .mint
            }
        }
    }

    // MARK: - Fonts

    enum Fonts {
        static let roastText = Font.system(.body, design: .rounded, weight: .medium)
        static let heading = Font.system(.headline, design: .rounded, weight: .bold)
        static let subheading = Font.system(.subheadline, design: .rounded, weight: .semibold)
        static let body = Font.system(.callout, design: .default, weight: .regular)
        static let caption = Font.system(.caption, design: .default, weight: .medium)
        static let stats = Font.system(.title3, design: .rounded, weight: .bold)
        static let statsLabel = Font.system(.caption2, design: .default, weight: .medium)
        static let label = Font.system(.caption2, design: .default, weight: .medium)
    }

    // MARK: - Layout

    enum Layout {
        static let popoverWidth: CGFloat = 320
        static let popoverHeight: CGFloat = 480
        static let cardCornerRadius: CGFloat = 10
        static let cardPadding: CGFloat = 12
        static let sectionSpacing: CGFloat = 12
        static let innerSpacing: CGFloat = 8
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}
