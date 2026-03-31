import AppKit
import SwiftUI

/// Transparent NSView that captures Force Touch pressure events.
/// Used as overlay content to detect touchpad slaps without Accessibility permission.
final class PressureTrackingNSView: NSView {
    var onPressureSpike: ((Double) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        // Cmd+Shift + click = instant slap, no need to hold for Force Touch
        onPressureSpike?(1.0)
    }
}

/// SwiftUI wrapper for PressureTrackingNSView.
struct PressureTrackingView: NSViewRepresentable {
    let onPressureSpike: (Double) -> Void

    func makeNSView(context: Context) -> PressureTrackingNSView {
        let view = PressureTrackingNSView()
        view.onPressureSpike = onPressureSpike
        return view
    }

    func updateNSView(_ nsView: PressureTrackingNSView, context: Context) {
        nsView.onPressureSpike = onPressureSpike
    }
}
