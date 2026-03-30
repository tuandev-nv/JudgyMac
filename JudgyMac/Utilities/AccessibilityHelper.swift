import AppKit
import ApplicationServices

/// Checks and requests Accessibility permission for global key monitoring.
@MainActor
enum AccessibilityHelper {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Prompt the system Accessibility dialog (shows once, then user must go to Settings).
    /// Returns true if already trusted.
    @discardableResult
    static func requestIfNeeded() -> Bool {
        if isTrusted { return true }

        // This triggers the system "allow Accessibility" alert on first call.
        // Subsequent calls do nothing — user must go to System Settings manually.
        let options = [String("AXTrustedCheckOptionPrompt"): true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)

        return false
    }

    /// Open System Settings → Privacy → Accessibility directly.
    static func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
