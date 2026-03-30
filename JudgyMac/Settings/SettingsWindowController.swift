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
        case personality = "Personality"
        case about = "About"

        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .triggers: return "bolt.fill"
            case .personality: return "theatermasks"
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
        window.minSize = NSSize(width: 560, height: 600)
        window.setContentSize(NSSize(width: 560, height: 600))
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
            case .personality: AnyView(PersonalitySettingsTab().environment(appState))
            case .about:       AnyView(AboutSettingsTab())
            }
            let controller = NSHostingController(rootView: view)
            controller.preferredContentSize = NSSize(width: 560, height: 600)
            cachedControllers[tab] = controller
        }

        window?.contentViewController = cachedControllers[tab]
    }

    // MARK: - Show

    func showAndFocus() {
        if !(window?.isVisible ?? false) {
            window?.setContentSize(NSSize(width: 560, height: 600))
            window?.center()
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
