import Foundation
import IOKit
import IOKit.ps
import IOKit.pwr_mgt

// IOKit power message constants (raw values since IOKit headers may not expose them in SPM)
private let sleepMessage: UInt32 = 0xE0000280
private let wakeMessage: UInt32 = 0xE0000300
private let canSleepMessage: UInt32 = 0xE0000270

/// Detects lid open/close via IOKit system power notifications.
/// Triggers: lidOpen, lidReopen, lateNight, earlyMorning
final class LidDetector: BehaviorDetector, @unchecked Sendable {
    private(set) var isRunning = false

    private var onEvent: (@Sendable (BehaviorEvent) -> Void)?
    private var notifyPortRef: IONotificationPortRef?
    private var notifierObject: io_object_t = 0
    private var rootPort: io_connect_t = 0

    private var lidOpenCountToday: Int = 0
    private var lastCloseTime: Date?
    private var lastOpenDate: Date?

    func start(onEvent: @escaping @Sendable (BehaviorEvent) -> Void) {
        guard !isRunning else { return }
        self.onEvent = onEvent
        isRunning = true
        registerForPowerNotifications()
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        deregister()
    }

    // MARK: - IOKit Power Notifications

    private func registerForPowerNotifications() {
        rootPort = IORegisterForSystemPower(
            Unmanaged.passUnretained(self).toOpaque(),
            &notifyPortRef,
            powerCallback,
            &notifierObject
        )

        guard rootPort != 0, let notifyPortRef else {
            #if DEBUG
            print("🤨 [LidDetector] ❌ IORegisterForSystemPower failed — sandbox blocking?")
            #endif
            isRunning = false
            return
        }
        #if DEBUG
        print("🤨 [LidDetector] ✅ Registered for power notifications")
        #endif

        CFRunLoopAddSource(
            CFRunLoopGetCurrent(),
            IONotificationPortGetRunLoopSource(notifyPortRef).takeUnretainedValue(),
            .defaultMode
        )
    }

    private func deregister() {
        if notifierObject != 0 {
            IODeregisterForSystemPower(&notifierObject)
            notifierObject = 0
        }
        if let notifyPortRef {
            IONotificationPortDestroy(notifyPortRef)
            self.notifyPortRef = nil
        }
        rootPort = 0
    }

    // MARK: - Handle Power Events

    fileprivate func handlePowerEvent(_ messageType: UInt32, _ messageArgument: Int) {
        #if DEBUG
        print("🤨 [LidDetector] Power event: \(String(format: "0x%X", messageType))")
        #endif
        switch messageType {
        case sleepMessage:
            IOAllowPowerChange(rootPort, messageArgument) // ACK FIRST — never delay this
            lastCloseTime = Date()

        case wakeMessage:
            handleWake()

        case canSleepMessage:
            IOAllowPowerChange(rootPort, messageArgument) // ACK FIRST — never delay this

        default:
            break
        }
    }

    private func handleWake() {
        resetIfNewDay()
        lidOpenCountToday += 1

        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)

        // Check re-open (opened again within 30s of closing)
        if let closeTime = lastCloseTime {
            let secondsSinceClose = Int(now.timeIntervalSince(closeTime))
            if secondsSinceClose <= Constants.Detection.lidReopenThresholdSeconds {
                onEvent?(.lidReopen(secondsSinceClose: secondsSinceClose))
                lastOpenDate = now
                return
            }
        }

        // Check late night
        if hour >= Constants.Detection.lateNightStartHour,
           hour < Constants.Detection.lateNightEndHour {
            onEvent?(.lateNight(hour: hour))
        }
        // Check early morning
        else if hour >= Constants.Detection.earlyMorningStartHour,
                hour < Constants.Detection.earlyMorningEndHour {
            onEvent?(.earlyMorning(hour: hour))
        }

        // Always emit lid open
        onEvent?(.lidOpen(count: lidOpenCountToday))
        lastOpenDate = now
    }

    private func resetIfNewDay() {
        guard let lastOpen = lastOpenDate else { return }
        if !Calendar.current.isDateInToday(lastOpen) {
            lidOpenCountToday = 0
        }
    }
}

// MARK: - C Callback

private func powerCallback(
    refCon: UnsafeMutableRawPointer?,
    service: io_service_t,
    messageType: UInt32,
    messageArgument: UnsafeMutableRawPointer?
) {
    guard let refCon else { return }
    let detector = Unmanaged<LidDetector>.fromOpaque(refCon).takeUnretainedValue()
    let argument = messageArgument.flatMap { Int(bitPattern: $0) } ?? 0
    detector.handlePowerEvent(messageType, argument)
}
