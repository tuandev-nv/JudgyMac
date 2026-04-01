import AppKit
import SwiftUI

/// Native NSToolbar-based Settings window — looks like CleanShotX / System Settings.
final class SettingsWindowController: NSWindowController, NSToolbarDelegate {
    private let appState: AppState
    private var currentTab: SettingsTab = .general
    private var cachedControllers: [SettingsTab: NSHostingController<AnyView>] = [:]

    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case triggers = "Triggers"
        case about = "About"

        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .triggers: return "bolt.fill"
            case .about: return "info.circle"
            }
        }

        var toolbarItemIdentifier: NSToolbarItem.Identifier {
            NSToolbarItem.Identifier(rawValue)
        }
    }

    init(appState: AppState) {
        self.appState = appState

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "General"
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 560, height: 300)
        window.maxSize = NSSize(width: 560, height: 10000)
        window.setContentSize(NSSize(width: 560, height: 500))
        window.center()

        super.init(window: window)

        setupToolbar()
        showTab(.general)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    // MARK: - Toolbar

    private func setupToolbar() {
        let toolbar = NSToolbar(identifier: "SettingsToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        toolbar.selectedItemIdentifier = SettingsTab.general.toolbarItemIdentifier

        window?.toolbar = toolbar
        window?.toolbarStyle = .preference  // This gives the CleanShotX look!
    }

    // MARK: - NSToolbarDelegate

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        SettingsTab.allCases.map(\.toolbarItemIdentifier)
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        SettingsTab.allCases.map(\.toolbarItemIdentifier)
    }

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        SettingsTab.allCases.map(\.toolbarItemIdentifier)
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let tab = SettingsTab(rawValue: itemIdentifier.rawValue) else { return nil }

        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label = tab.rawValue
        item.image = NSImage(systemSymbolName: tab.icon, accessibilityDescription: tab.rawValue)
        item.target = self
        item.action = #selector(toolbarItemClicked(_:))
        return item
    }

    @objc private func toolbarItemClicked(_ sender: NSToolbarItem) {
        guard let tab = SettingsTab(rawValue: sender.itemIdentifier.rawValue) else { return }
        showTab(tab)
    }

    // MARK: - Switch Tabs

    private func showTab(_ tab: SettingsTab) {
        currentTab = tab
        window?.title = tab.rawValue
        window?.toolbar?.selectedItemIdentifier = tab.toolbarItemIdentifier

        // Cache controllers — don't recreate on every tab switch
        if cachedControllers[tab] == nil {
            let view: AnyView = switch tab {
            case .general:     AnyView(GeneralSettingsTab().environment(appState))
            case .triggers:    AnyView(TriggersSettingsTab().environment(appState))
            case .about:       AnyView(AboutSettingsTab())
            }
            let controller = NSHostingController(rootView: view)
            cachedControllers[tab] = controller
        }

        window?.contentViewController = cachedControllers[tab]

        // Resize per tab — keep top edge fixed, width locked
        let height: CGFloat = switch tab {
        case .general:  420
        case .triggers: 700
        case .about:    500
        }
        if let window {
            var frame = window.frame
            let topY = frame.maxY
            let titlebarHeight = frame.height - (window.contentView?.frame.height ?? 0)
            frame.size = NSSize(width: 560, height: height + titlebarHeight)
            frame.origin.y = topY - frame.size.height
            window.setFrame(frame, display: true, animate: true)
        }
    }

    // MARK: - Show

    func showAndFocus() {
        if !(window?.isVisible ?? false) {
            window?.center()
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
