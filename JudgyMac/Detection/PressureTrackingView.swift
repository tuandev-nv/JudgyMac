import AppKit
import SwiftUI

/// Transparent NSView that captures Force Touch pressure events.
/// Used as overlay content to detect touchpad slaps without Accessibility permission.
final class PressureTrackingNSView: NSView {
    var onPressureSpike: ((Double) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func pressureChange(with event: NSEvent) {
        let pressure = Double(event.pressure)
        if pressure >= Constants.Slap.pressureThreshold {
            onPressureSpike?(pressure)
        }
    }

    // Also detect via mouseDown force for some trackpad configurations
    override func mouseDown(with event: NSEvent) {
        let pressure = Double(event.pressure)
        if pressure >= Constants.Slap.pressureThreshold {
            onPressureSpike?(pressure)
        }
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
