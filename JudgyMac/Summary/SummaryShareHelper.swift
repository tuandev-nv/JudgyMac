import AppKit
import SwiftUI

/// Exports summary card as PNG and presents macOS share sheet.
@MainActor
enum SummaryShareHelper {
    static func shareSummary(_ summary: DailySummary) {
        let cardView = SummaryCardView(summary: summary)
        guard let image = cardView.renderToImage() else { return }
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else { return }

        // Save to app's cache directory (sandbox-safe)
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let tempURL = cacheDir.appendingPathComponent("JudgyMac_Summary_\(Int(Date().timeIntervalSince1970)).png")

        do {
            try pngData.write(to: tempURL)
            let picker = NSSharingServicePicker(items: [tempURL])

            // Show from menu bar area
            if let button = NSApp.windows.first?.contentView {
                picker.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        } catch {
            // Fallback: copy image to clipboard
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([image])
        }
    }

    static func copyRoastText(_ roast: RoastEntry) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(roast.shareText, forType: .string)
    }
}
