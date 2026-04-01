import AppKit
import SwiftUI
import UserNotifications
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, @preconcurrency UNUserNotificationCenterDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var settingsController: SettingsWindowController?
    let _appState = AppState()
    private var coordinator: DetectionCoordinator?
    private var presenter: RoastPresenter?
    private var slapPresenter: SlapPresenter?

    // Animated menu bar icon
    private let cpuMonitor = CPUMonitor()
    private var animationTimer: Timer?
    private var animationFrame = 0
    private var currentMood: Mood = .neutral
    private var animationSkipRate = 1  // 1 = every tick, 2 = every other tick, etc.
    private var systemStatsTick = 0  // throttle heavy stats polling

    // Sprite run cycle for character packs
    private var spriteFrames: [NSImage] = []
    private var spriteTimer: Timer?
    private var spriteFrame = 0
    private var cachedStatsPill: NSImage?
    private var cachedStatsPillKey = ""

    // MARK: - App Lifecycle

    private var saveTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self

        // Load persisted data
        SettingsStore.load(into: _appState)

        setupStatusItem()
        setupPopover()
        startEngine()
        observeMenuBarSprite()
        SoundPlayer.isMuted = !_appState.voiceEnabled

        // Pre-warm slap window + sounds so first slap is instant (only if licensed)
        if _appState.isLicenseValid {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self else { return }
                let pack = self._appState.currentPack

                // Warm up slap window (creates NSHostingController)
                SlapWindow.shared.warmUp(pack: pack)

                // Preload slap sounds + first few voice lines
                var sounds = [
                    pack.slapSoundPath,
                    "\(pack.folderPath)/slap_voice",
                    "\(pack.folderPath)/umph",
                ]
                // Preload first 4 slap voice files
                for i in 1...4 {
                    sounds.append("\(pack.folderPath)/slap_voices/slap_voice_\(i)")
                }
                SoundPlayer.preload(sounds)
            }
        }

        #if DEBUG
        // Ctrl+Shift+S → trigger slap (dev shortcut, bypass popover)
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.control, .shift]),
               event.charactersIgnoringModifiers == "s" {
                let slapEvent = BehaviorEvent.slap(pressure: 0.95)
                self?._appState.handleEvent(slapEvent)
                NotificationCenter.default.post(
                    name: .behaviorEventDetected,
                    object: nil,
                    userInfo: ["event": slapEvent]
                )
                return nil
            }
            // Ctrl+Shift+T → trigger screen time roast (dev shortcut)
            if event.modifierFlags.contains([.control, .shift]),
               event.charactersIgnoringModifiers == "t" {
                let stEvent = BehaviorEvent.screenTime(minutes: 45)
                self?._appState.handleEvent(stEvent)
                NotificationCenter.default.post(
                    name: .behaviorEventDetected,
                    object: nil,
                    userInfo: ["event": stEvent]
                )
                return nil
            }
            return event
        }
        #endif

        // Auto-save every 30 seconds
        saveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            MainActor.assumeIsolated { [weak self] in
                guard let self else { return }
                SettingsStore.save(self._appState)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        SettingsStore.save(_appState)
    }

    // MARK: - Status Item (Menu Bar Icon)

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        loadSpriteFrames()

        if let button = statusItem.button {
            updateMenuBarIcon()
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Animate menu bar icon — speed based on CPU
        startMenuBarAnimation()
    }

    private func startMenuBarAnimation() {
        // Respect Reduce Motion — use static icon, only update mood (no frame cycling)
        let interval: TimeInterval = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 10.0 : 5.0
        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            MainActor.assumeIsolated { [weak self] in
                self?.tickAnimation()
            }
        }
    }

    private func tickAnimation() {
        // Update mood from app state
        currentMood = _appState.currentMood

        // CPU every tick (5s), RAM every ~10s, GPU every ~15s
        let cpu = cpuMonitor.currentUsage()
        _appState.cpuUsage = cpu
        systemStatsTick += 1
        if systemStatsTick % 2 == 0 {
            _appState.ramUsage = currentRAMUsage()
        }
        if systemStatsTick % 3 == 0 {
            _appState.gpuUsage = currentGPUUsage()
        }

        // Faster animation = higher CPU (skip fewer ticks)
        animationSkipRate = switch cpu {
        case 0.8...: 1   // Every tick — panic
        case 0.5..<0.8: 1 // Every tick — stressed
        case 0.2..<0.5: 1 // Every tick — normal
        default: 2         // Every other tick — chill
        }

        // Advance frame (static on Reduce Motion — always frame 0)
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            animationFrame = 0
        } else if systemStatsTick % animationSkipRate == 0 {
            animationFrame = (animationFrame + 1) % 4
        }
        updateMenuBarIcon()
    }

    private func updateMenuBarIcon() {
        // Sprite animation handles its own icon updates
        if spriteTimer != nil { return }
        // Don't restore emoji while desktop runner is active
        if DesktopRunnerWindow.shared.isActive { return }

        let faceName = FluentEmoji.face(for: currentMood, frame: animationFrame)
        let emojiImage = FluentEmoji.menuBarImage(named: faceName)

        let cpu = Int(_appState.cpuUsage * 100)
        let gpu = Int(_appState.gpuUsage * 100)
        let ram = Int(_appState.ramUsage * 100)

        let stats = [
            ("CPU", "\(cpu)%"),
            ("GPU", "\(gpu)%"),
            ("RAM", "\(ram)%"),
        ]

        let combined = renderMenuBarImage(emoji: emojiImage, stats: stats)
        combined.accessibilityDescription = "JudgyMac — \(currentMood.displayName)"
        statusItem.button?.image = combined
        statusItem.button?.title = ""
    }

    /// Renders stats pill only (gradient bg + text). Cached between updates.
    private func renderStatsPill(stats: [(String, String)]) -> NSImage {
        let colGap: CGFloat = 8
        let hPad: CGFloat = 8
        let vPad: CGFloat = 1
        let labelValueGap: CGFloat = -3

        let labelFont = NSFont.systemFont(ofSize: 7, weight: .semibold)
        let valueFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .bold)

        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let gradStart = isDark
            ? NSColor(red: 0.35, green: 0.25, blue: 0.18, alpha: 1)
            : NSColor(red: 1.0, green: 0.92, blue: 0.82, alpha: 1)
        let gradEnd = isDark
            ? NSColor(red: 0.25, green: 0.18, blue: 0.30, alpha: 1)
            : NSColor(red: 0.95, green: 0.85, blue: 0.92, alpha: 1)
        let borderColor = isDark
            ? NSColor(white: 1, alpha: 0.12)
            : NSColor(white: 0, alpha: 0.08)
        let labelColor = isDark
            ? NSColor(white: 1, alpha: 0.55)
            : NSColor(white: 0, alpha: 0.4)
        let valueColor = isDark
            ? NSColor(white: 1, alpha: 0.95)
            : NSColor(white: 0, alpha: 0.8)

        var colWidths: [CGFloat] = []
        for (label, value) in stats {
            let lw = (label as NSString).size(withAttributes: [.font: labelFont]).width
            let vw = (value as NSString).size(withAttributes: [.font: valueFont]).width
            colWidths.append(max(lw, vw))
        }

        let labelHeight = ("X" as NSString).size(withAttributes: [.font: labelFont]).height
        let valueHeight = ("0" as NSString).size(withAttributes: [.font: valueFont]).height
        let contentHeight = labelHeight + labelValueGap + valueHeight

        let statsWidth = colWidths.reduce(0, +) + CGFloat(stats.count - 1) * colGap
        let bgWidth = statsWidth + hPad * 2
        let bgHeight = contentHeight + vPad * 2

        let pill = NSImage(size: NSSize(width: bgWidth, height: bgHeight))
        pill.lockFocus()

        let bgRect = NSRect(x: 0, y: 0, width: bgWidth, height: bgHeight)
        let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: 5, yRadius: 5)

        NSGraphicsContext.saveGraphicsState()
        bgPath.addClip()
        let gradient = NSGradient(starting: gradStart, ending: gradEnd)
        gradient?.draw(in: bgRect, angle: 0)
        NSGraphicsContext.restoreGraphicsState()

        borderColor.setStroke()
        bgPath.lineWidth = 0.5
        bgPath.stroke()

        var x: CGFloat = hPad
        let contentY = vPad

        for (i, (label, value)) in stats.enumerated() {
            let colW = colWidths[i]
            let labelAttrs: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: labelColor]
            (label as NSString).draw(
                at: NSPoint(x: x, y: contentY + valueHeight + labelValueGap),
                withAttributes: labelAttrs
            )
            let valueAttrs: [NSAttributedString.Key: Any] = [.font: valueFont, .foregroundColor: valueColor]
            let valueSize = (value as NSString).size(withAttributes: valueAttrs)
            (value as NSString).draw(
                at: NSPoint(x: x + (colW - valueSize.width) / 2, y: contentY),
                withAttributes: valueAttrs
            )
            x += colW + colGap
        }

        pill.unlockFocus()
        return pill
    }

    /// Lightweight compose: sprite + cached stats pill → single menu bar image.
    private func renderMenuBarImage(emoji: NSImage?, stats: [(String, String)]) -> NSImage {
        let barHeight: CGFloat = 22
        let emojiSize: CGFloat = 18
        let gapAfterEmoji: CGFloat = 5

        // Cache stats pill — only re-render when values change
        let statsKey = stats.map { "\($0.0)\($0.1)" }.joined()
        if statsKey != cachedStatsPillKey {
            cachedStatsPillKey = statsKey
            cachedStatsPill = renderStatsPill(stats: stats)
        }

        let pillWidth = cachedStatsPill?.size.width ?? 0
        let pillHeight = cachedStatsPill?.size.height ?? 0
        let totalWidth = emojiSize + gapAfterEmoji + pillWidth + 2

        let image = NSImage(size: NSSize(width: totalWidth, height: barHeight))
        image.lockFocus()

        if let emoji {
            emoji.draw(in: NSRect(x: 0, y: (barHeight - emojiSize) / 2,
                                  width: emojiSize, height: emojiSize))
        }

        if let pill = cachedStatsPill {
            let pillX = emojiSize + gapAfterEmoji
            let pillY = (barHeight - pillHeight) / 2
            pill.draw(in: NSRect(x: pillX, y: pillY, width: pillWidth, height: pillHeight))
        }

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    // MARK: - Sprite Animation

    /// Load run-cycle frames from CharacterPacks/{packId}/menubar_frames/
    private func loadSpriteFrames() {
        spriteTimer?.invalidate()
        spriteTimer = nil
        spriteFrames.removeAll()

        let packId = _appState.currentPack.id
        guard let dirURL = Bundle.main.resourceURL?
            .appendingPathComponent("CharacterPacks")
            .appendingPathComponent(packId)
            .appendingPathComponent("menubar_frames") else { return }

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: dirURL, includingPropertiesForKeys: nil
        ).filter({ $0.pathExtension == "png" }).sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
        else { return }

        spriteFrames = files.compactMap { url in
            guard let img = NSImage(contentsOf: url) else { return nil }
            img.size = NSSize(width: 20, height: 22)
            img.isTemplate = false
            return img
        }

        #if DEBUG
        print("🎬 [Sprite] Loaded \(spriteFrames.count) menubar frames for '\(packId)'")
        #endif

        if !spriteFrames.isEmpty {
            startSpriteAnimation()
        }
    }

    // MARK: - Menu Bar Sprite Visibility (for Desktop Runner)

    private func observeMenuBarSprite() {
        NotificationCenter.default.addObserver(
            forName: .hideMenuBarSprite, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated { [weak self] in
                guard let self else { return }
                self.spriteTimer?.invalidate()
                self.spriteTimer = nil
                let cpu = Int(self._appState.cpuUsage * 100)
                let gpu = Int(self._appState.gpuUsage * 100)
                let ram = Int(self._appState.ramUsage * 100)
                let stats = [("CPU", "\(cpu)%"), ("GPU", "\(gpu)%"), ("RAM", "\(ram)%")]
                let combined = self.renderMenuBarImage(emoji: nil, stats: stats)
                self.statusItem.button?.image = combined
                self.statusItem.button?.title = ""
            }
        }
        NotificationCenter.default.addObserver(
            forName: .showMenuBarSprite, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated { [weak self] in
                self?.loadSpriteFrames()
            }
        }
    }

    private var spriteTick = 0

    private func startSpriteAnimation() {
        spriteFrame = 0
        spriteTick = 0
        // 12Hz tick, frame advance rate scales with CPU
        spriteTimer = Timer.scheduledTimer(withTimeInterval: 0.083, repeats: true) { _ in
            MainActor.assumeIsolated { [weak self] in
                guard let self, !self.spriteFrames.isEmpty else { return }
                let cpu = self._appState.cpuUsage

                // CPU → how often to advance frame
                // Low CPU (0%): every 8 ticks = 1fps stroll
                // Mid CPU (30%): every 3 ticks = 2.7fps jog
                // High CPU (70%): every 1 tick = 8fps sprint
                let skipRate = max(1, Int(round(8 * (1 - cpu * 1.2))))
                self.spriteTick += 1
                if self.spriteTick >= skipRate {
                    self.spriteTick = 0
                    self.spriteFrame = (self.spriteFrame + 1) % self.spriteFrames.count
                }

                // Only update status bar when sprite frame actually changes
                guard self.spriteTick == 0 else { return }

                let image = self.spriteFrames[self.spriteFrame]
                let cpuPct = Int(cpu * 100)
                let gpu = Int(self._appState.gpuUsage * 100)
                let ram = Int(self._appState.ramUsage * 100)

                let stats = [("CPU", "\(cpuPct)%"), ("GPU", "\(gpu)%"), ("RAM", "\(ram)%")]
                let combined = self.renderMenuBarImage(emoji: image, stats: stats)
                combined.accessibilityDescription = "JudgyMac"
                self.statusItem.button?.image = combined
                self.statusItem.button?.title = ""
            }
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 480)
        popover.behavior = .transient
        popover.animates = true

        let contentView = MenuBarView(
            onOpenSettings: { [weak self] in
                self?.openSettings()
            },
            onShare: { [weak self] in
                self?.shareSummary()
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )
        .environment(_appState)

        popover.contentViewController = NSHostingController(rootView: contentView)
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Ensure popover window is key so clicks work
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - Actions (run after popover closes)

    private func openSettings() {
        if popover.isShown {
            popover.performClose(nil)
        }
        showSettingsWindow()
    }

    private func showSettingsWindow() {
        if settingsController == nil {
            settingsController = SettingsWindowController(appState: _appState)

            // No activation policy change needed during dev
        }

        settingsController?.showAndFocus()
    }

    private func shareSummary() {
        if popover.isShown {
            popover.performClose(nil)
        }
        let summary = DailySummaryGenerator.generate(
            stats: _appState.todayStats,
            history: _appState.roastHistory
        )
        SummaryShareHelper.shareSummary(summary)
    }

    // MARK: - Engine

    private func startEngine() {
        let p = RoastPresenter(appState: _appState)
        p.requestPermission()
        presenter = p

        slapPresenter = SlapPresenter(appState: _appState)

        let coord = DetectionCoordinator(appState: _appState)
        coord.start()
        coordinator = coord

        #if DEBUG
        print("🤨 [JudgyMac] App started. Detectors running.")
        #endif
    }

    // MARK: - Update Menu Bar Icon

    func updateIcon(for mood: Mood) {
        let symbolName: String = switch mood {
        case .neutral:   "face.smiling"
        case .judging:   "face.smiling.inverse"
        case .horrified: "exclamationmark.triangle"
        case .sleeping:  "zzz"
        case .raging:    "flame"
        case .impressed: "star"
        }

        statusItem.button?.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: mood.displayName
        )
        statusItem.button?.image?.size = NSSize(width: 18, height: 18)
    }

    // MARK: - Notification Delegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.actionIdentifier {
        case "SHUT_UP":
            NotificationCenter.default.post(name: .snoozeRoasts, object: nil)
        case "MORE_LIKE_THIS":
            NotificationCenter.default.post(name: .moreLikeThis, object: nil)
        default:
            break
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Launch at Login

    static func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            #if DEBUG
            print("🤨 [LaunchAtLogin] Failed: \(error.localizedDescription)")
            #endif
        }
    }

    static var isLaunchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
}

extension Notification.Name {
    static let snoozeRoasts = Notification.Name("com.judgymac.snoozeRoasts")
    static let moreLikeThis = Notification.Name("com.judgymac.moreLikeThis")

}
