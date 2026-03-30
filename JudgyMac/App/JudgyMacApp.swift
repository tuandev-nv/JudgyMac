import SwiftUI

@main
struct JudgyMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No scenes — everything managed by AppDelegate (NSPopover + NSWindow)
        Settings { EmptyView() }
    }
}
