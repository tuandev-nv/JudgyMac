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
    private var cachedSpriteComposites: [NSImage] = []

    // Lid angle creak
    private var lidAngleSensor: LidAngleSensor?
    private var creakEngine: CreakAudioEngine?
    private var lidCreakTimer: Timer?

    // MARK: - App Lifecycle

    private var saveTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self

        // Load persisted data
        SettingsStore.load(into: _appState)

        warnIfNotInApplications()
        setupStatusItem()
        setupPopover()
        startEngine()
        observeMenuBarSprite()
        observeRawAppSwitches()
        SoundPlayer.isMuted = !_appState.voiceEnabled

        // Initialize Sparkle auto-updater (delayed to avoid blocking launch)
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            _ = AppUpdater.shared
        }

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
                for i in 1...4 {
                    sounds.append("\(pack.folderPath)/slap_voices/slap_voice_\(i)")
                }
                SoundPlayer.preload(sounds)
            }
        }

        // Welcome roast — greet user 3s after launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.deliverWelcomeRoast()
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
        saveTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            MainActor.assumeIsolated { [weak self] in
                guard let self else { return }
                SettingsStore.save(self._appState)
            }
        }
    }

    var skipSaveOnTerminate = false

    func applicationWillTerminate(_ notification: Notification) {
        guard !skipSaveOnTerminate else { return }
        SettingsStore.save(_appState)
    }

    // MARK: - Applications Folder Check

    private func warnIfNotInApplications() {
        #if !DEBUG
        let appPath = Bundle.main.bundlePath
        guard !appPath.hasPrefix("/Applications") else { return }

        let alert = NSAlert()
        alert.messageText = "Move to Applications"
        alert.informativeText = "JudgyMac works best from the Applications folder. Move it there for auto-updates and a better experience."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Move to Applications")
        alert.addButton(withTitle: "Continue Anyway")

        if alert.runModal() == .alertFirstButtonReturn {
            let dest = "/Applications/JudgyMac.app"
            do {
                if FileManager.default.fileExists(atPath: dest) {
                    try FileManager.default.removeItem(atPath: dest)
                }
                try FileManager.default.copyItem(atPath: appPath, toPath: dest)
                NSWorkspace.shared.open(URL(fileURLWithPath: dest))
                NSApplication.shared.terminate(nil)
            } catch {
                let errAlert = NSAlert()
                errAlert.messageText = "Could not move"
                errAlert.informativeText = "Please drag JudgyMac.app to your Applications folder manually."
                errAlert.runModal()
            }
        }
        #endif
    }

    private var currentStats: [(String, String)] {
        let cpu = Int(_appState.cpuUsage * 100)
        let ram = Int(_appState.ramUsage * 100)
        return [("CPU", "\(cpu)%"), ("RAM", "\(ram)%")]
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
        // Prime CPU monitor (needs 2 reads with delay for delta)
        _ = cpuMonitor.currentUsage()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.tickAnimation()
        }
    }

    private func startMenuBarAnimation() {
        // Respect Reduce Motion — use static icon, only update mood (no frame cycling)
        let interval: TimeInterval = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 10.0 : 2.0
        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            MainActor.assumeIsolated { [weak self] in
                self?.tickAnimation()
            }
        }
    }

    private func tickAnimation() {
        // Update mood from app state
        currentMood = _appState.currentMood

        // CPU + RAM every tick (2s)
        _appState.cpuUsage = cpuMonitor.currentUsage()
        _appState.ramUsage = currentRAMUsage()
        systemStatsTick += 1


        // Faster animation = higher CPU (skip fewer ticks)
        animationSkipRate = switch _appState.cpuUsage {
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

        let combined = renderMenuBarImage(emoji: emojiImage, stats: currentStats)
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
            img.size = NSSize(width: 18, height: 18)
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
                let combined = self.renderMenuBarImage(emoji: nil, stats: self.currentStats)
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

        // 4Hz sprite via target/selector (avoids @Sendable closure warnings)
        spriteTimer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(tickSprite), userInfo: nil, repeats: true)
    }

    @objc private func tickSprite() {
        guard !spriteFrames.isEmpty else { return }
        spriteFrame = (spriteFrame + 1) % spriteFrames.count

        // Rebuild composite cache when stats change
        let statsKey = currentStats.map { "\($0.0)\($0.1)" }.joined()
        if cachedSpriteComposites.count != spriteFrames.count || statsKey != cachedStatsPillKey {
            cachedSpriteComposites = spriteFrames.map { frame in
                renderMenuBarImage(emoji: frame, stats: currentStats)
            }
        }

        let img = cachedSpriteComposites[spriteFrame]
        img.accessibilityDescription = "JudgyMac"
        statusItem.button?.image = img
        statusItem.button?.title = ""
    }

    // MARK: - Raw App Switch Counter

    private nonisolated(unsafe) var appSwitchObserver: Any?
    private nonisolated(unsafe) var koObserver: Any?

    private func observeRawAppSwitches() {
        appSwitchObserver = NotificationCenter.default.addObserver(
            forName: .appSwitchRawCount, object: nil, queue: .main
        ) { _ in
            Task { @MainActor [weak self] in
                self?._appState.todayStats.totalAppSwitchCount += 1
            }
        }
        koObserver = NotificationCenter.default.addObserver(
            forName: .slapKO, object: nil, queue: .main
        ) { _ in
            Task { @MainActor [weak self] in
                self?._appState.todayStats.koCount += 1
            }
        }
        NotificationCenter.default.addObserver(
            forName: .triggersDidChange, object: nil, queue: .main
        ) { _ in
            Task { @MainActor [weak self] in
                self?.coordinator?.restart()
            }
        }
    }

    // MARK: - Welcome Roast

    private static let welcomeRoasts = [
        "You're back! I was starting to enjoy the silence.",
        "Oh great, YOU again. Let's see how long before you do something stupid.",
        "Another day, another chance for me to judge you. Tremendous.",
        "I've been waiting. Not because I missed you — because I have OPINIONS.",
        "Welcome back. Your MacBook told me EVERYTHING you did yesterday.",
        "Rise and shine! Time to make bad decisions while I watch.",
    ]

    private func deliverWelcomeRoast() {
        guard _appState.toastEnabled else { return }
        let pack = _appState.currentPack
        let text = Self.welcomeRoasts.randomElement()!
        SoundPlayer.play("\(pack.folderPath)/welcome", volume: 0.85)

        let entry = RoastEntry(
            text: text,
            personality: pack.displayName,
            triggerType: .lidOpen,
            mood: .judging,
            customEmoji: pack.randomEmoji()
        )
        _appState.deliverRoast(entry)
        ToastWindow.shared.show(roast: entry)
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

        // Option+Click → play random voice line instead of opening popover
        if NSApp.currentEvent?.modifierFlags.contains(.option) == true {
            playRandomVoiceLine()
            return
        }

        // No license → go straight to Settings
        if !_appState.isLicenseValid {
            openSettings()
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func playRandomVoiceLine() {
        let pack = _appState.currentPack
        guard pack.slapVoiceCount > 0 else { return }
        let index = Int.random(in: 1...pack.slapVoiceCount)
        let voicePath = "\(pack.folderPath)/slap_voices/slap_voice_\(index)"
        SoundPlayer.playVoiceReturningDuration(voicePath, volume: 0.9)
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

        // Lid angle creak
        startLidCreak()

        #if DEBUG
        print("🤨 [JudgyMac] App started. Detectors running.")
        #endif
    }

    // MARK: - Lid Angle Creak

    private func startLidCreak() {
        guard _appState.lidCreakEnabled else { return }

        let sensor = LidAngleSensor()
        guard sensor.isAvailable else { return }

        lidAngleSensor = sensor
        sensor.start()

        let creak = CreakAudioEngine()
        creak.start()
        creakEngine = creak

        // Feed angle to creak engine at 30Hz (synced with sensor)
        lidCreakTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            MainActor.assumeIsolated { [weak self] in
                guard let self, self._appState.isLicenseValid,
                      let sensor = self.lidAngleSensor, let creak = self.creakEngine else { return }
                creak.update(angle: sensor.angle)
            }
        }

        // Observe toggle
        NotificationCenter.default.addObserver(
            forName: .lidCreakDidChange, object: nil, queue: .main
        ) { _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self._appState.lidCreakEnabled {
                    self.lidAngleSensor?.start()
                    self.creakEngine?.start()
                } else {
                    self.lidAngleSensor?.stop()
                    self.creakEngine?.stop()
                }
            }
        }
    }

    private func stopLidCreak() {
        lidCreakTimer?.invalidate()
        lidCreakTimer = nil
        lidAngleSensor?.stop()
        creakEngine?.stop()
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
