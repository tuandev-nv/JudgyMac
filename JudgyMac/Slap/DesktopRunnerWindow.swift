import AppKit
import SwiftUI

/// Fullscreen transparent window for Trump running across desktop after KO.
/// `ignoresMouseEvents = true` — user can interact with apps underneath.
@MainActor
final class DesktopRunnerWindow {
    static let shared = DesktopRunnerWindow()

    private var panel: NSPanel!
    private var hostingController: NSHostingController<AnyView>?
    private(set) var isActive = false

    private init() {
        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .popUpMenu
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
    }

    func run(pack: CharacterPack, onFinished: @escaping @MainActor () -> Void) {
        guard !isActive else { return }
        guard let screen = NSScreen.main else {
            onFinished()
            return
        }

        let screenFrame = screen.frame
        panel.setFrame(screenFrame, display: true)

        let view = DesktopRunnerView(
            pack: pack,
            screenSize: screenFrame.size,
            onFinished: { [weak self] in
                self?.dismiss()
                onFinished()
            }
        )

        hostingController = NSHostingController(rootView: AnyView(view))
        hostingController?.view.frame = NSRect(origin: .zero, size: screenFrame.size)
        panel.contentView = hostingController?.view

        isActive = true
        panel.orderFrontRegardless()
    }

    private func dismiss() {
        isActive = false
        panel.orderOut(nil)
        hostingController = nil
    }
}
