#if ACCELEROMETER_ENABLED
import AppKit
import Foundation
import IOKit

/// Detects physical slaps on MacBook body via built-in accelerometer (Apple Silicon).
/// Uses IOKit HID to read the Bosch BMI286 accelerometer.
/// Requires non-sandboxed build (IOKit HID blocked by App Sandbox).
final class AccelerometerDetector: BehaviorDetector, @unchecked Sendable {
    private(set) var isRunning = false

    private var onEvent: (@Sendable (BehaviorEvent) -> Void)?
    private var hidDevice: IOHIDDevice?
    private var reportBuffer: UnsafeMutablePointer<UInt8>?
    private let reportBufferSize = 64
    private var lastSlapTime: Date = .distantPast
    private var processor = SlapSignalProcessor()
    private var suppressedUntil: Date = .distantPast
    private var sleepWakeObservers: [NSObjectProtocol] = []

    // Tuning
    private let debounceInterval: TimeInterval = 0.5
    /// Suppress detection for this many seconds around sleep/wake (lid close/open).
    private let lidSuppressionSeconds: TimeInterval = 3.0

    func start(onEvent: @escaping @Sendable (BehaviorEvent) -> Void) {
        guard !isRunning else { return }
        self.onEvent = onEvent

        #if DEBUG
        print("🏋️ [Accelerometer] Attempting to open accelerometer...")
        #endif

        guard openAccelerometer() else {
            #if DEBUG
            print("🏋️ [Accelerometer] ❌ Failed — Cmd+Shift slap still works.")
            #endif
            return
        }

        isRunning = true
        observeSleepWake()
        #if DEBUG
        print("🏋️ [Accelerometer] ✅ Started — multi-algorithm voting (≥3/4)")
        #endif
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false

        for observer in sleepWakeObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        sleepWakeObservers.removeAll()

        if let device = hidDevice {
            IOHIDDeviceUnscheduleFromRunLoop(device, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
        }
        hidDevice = nil
        reportBuffer?.deallocate()
        reportBuffer = nil
    }

    // MARK: - Sleep/Wake Suppression

    /// Suppress accelerometer around lid close/open to avoid false slaps from physical impact.
    private func observeSleepWake() {
        let center = NSWorkspace.shared.notificationCenter

        let willSleep = center.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.suppressedUntil = Date().addingTimeInterval(self.lidSuppressionSeconds)
            #if DEBUG
            print("🏋️ [Accelerometer] 😴 Sleep — suppressing for \(self.lidSuppressionSeconds)s")
            #endif
        }

        let didWake = center.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.suppressedUntil = Date().addingTimeInterval(self.lidSuppressionSeconds)
            // Reset processor baselines after wake (accelerometer state may have drifted)
            self.processor = SlapSignalProcessor()
            #if DEBUG
            print("🏋️ [Accelerometer] ☀️ Wake — suppressing for \(self.lidSuppressionSeconds)s, reset processor")
            #endif
        }

        sleepWakeObservers = [willSleep, didWake]
    }

    // MARK: - IOKit HID Setup

    private func openAccelerometer() -> Bool {
        // Step 1: Wake ALL SPU sensors via AppleSPUHIDDriver
        wakeSensors()

        // Step 2: Find accelerometer device (usage page 0xFF00, usage 3)
        let matching = IOServiceMatching("AppleSPUHIDDevice") as NSMutableDictionary
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            #if DEBUG
            print("🏋️ [Accelerometer] ❌ IOServiceGetMatchingServices failed")
            #endif
            return false
        }
        defer { IOObjectRelease(iterator) }

        var accelService: io_service_t = 0
        var serviceCount = 0
        var service = IOIteratorNext(iterator)
        while service != 0 {
            serviceCount += 1
            defer {
                if service != accelService { IOObjectRelease(service) }
                service = IOIteratorNext(iterator)
            }

            var props: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                  let dict = props?.takeRetainedValue() as? [String: Any] else { continue }

            let usagePage = dict["PrimaryUsagePage"] as? Int ?? 0
            let usage = dict["PrimaryUsage"] as? Int ?? 0

            #if DEBUG
            print("🏋️ [Accelerometer] Service \(serviceCount): usagePage=0x\(String(usagePage, radix: 16)) usage=\(usage)")
            #endif

            if usagePage == 0xFF00 && usage == 3 {
                accelService = service
                break
            }
        }

        #if DEBUG
        print("🏋️ [Accelerometer] Found \(serviceCount) services, accel=\(accelService != 0)")
        #endif

        guard accelService != 0 else { return false }
        defer { IOObjectRelease(accelService) }

        // Step 3: Create and open HID device
        guard let dev = IOHIDDeviceCreate(kCFAllocatorDefault, accelService) else {
            #if DEBUG
            print("🏋️ [Accelerometer] ❌ IOHIDDeviceCreate failed")
            #endif
            return false
        }

        let openResult = IOHIDDeviceOpen(dev, IOOptionBits(kIOHIDOptionsTypeNone))
        guard openResult == kIOReturnSuccess else {
            #if DEBUG
            print("🏋️ [Accelerometer] ❌ IOHIDDeviceOpen failed: \(String(format: "0x%X", openResult))")
            #endif
            return false
        }

        // Step 4: Also wake via device properties (belt and suspenders)
        IOHIDDeviceSetProperty(dev, "ReportInterval" as CFString, 1000 as CFNumber)
        IOHIDDeviceSetProperty(dev, "SensorPropertyReportingState" as CFString, 1 as CFNumber)
        IOHIDDeviceSetProperty(dev, "SensorPropertyPowerState" as CFString, 1 as CFNumber)

        hidDevice = dev

        // Step 5: Register callback
        reportBuffer = .allocate(capacity: reportBufferSize)
        reportBuffer?.initialize(repeating: 0, count: reportBufferSize)

        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(
            dev,
            reportBuffer!,
            reportBufferSize,
            accelReportCallback,
            context
        )

        IOHIDDeviceScheduleWithRunLoop(dev, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        return true
    }

    /// Wake sensors via AppleSPUHIDDriver (required before reading from Device)
    private func wakeSensors() {
        var iterator: io_iterator_t = 0
        guard let matching = IOServiceMatching("AppleSPUHIDDriver") as NSMutableDictionary?,
              IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            #if DEBUG
            print("🏋️ [Accelerometer] ⚠️ No AppleSPUHIDDriver found")
            #endif
            return
        }
        defer { IOObjectRelease(iterator) }

        var count = 0
        var svc = IOIteratorNext(iterator)
        while svc != 0 {
            count += 1
            IORegistryEntrySetCFProperty(svc, "SensorPropertyReportingState" as CFString, 1 as CFNumber)
            IORegistryEntrySetCFProperty(svc, "SensorPropertyPowerState" as CFString, 1 as CFNumber)
            IORegistryEntrySetCFProperty(svc, "ReportInterval" as CFString, 1000 as CFNumber)
            IOObjectRelease(svc)
            svc = IOIteratorNext(iterator)
        }

        #if DEBUG
        print("🏋️ [Accelerometer] Woke \(count) SPU drivers")
        #endif
    }

    // MARK: - Report Parsing

    private var reportCount = 0

    fileprivate func handleReport(_ report: UnsafeMutablePointer<UInt8>, length: CFIndex) {
        guard length >= 18 else { return }

        // Suppress during lid close/open
        guard Date() >= suppressedUntil else { return }

        // Suppress when screen is locked
        let isLocked = CGSessionCopyCurrentDictionary()
            .flatMap { ($0 as NSDictionary)["CGSSessionScreenIsLocked"] as? Bool } ?? false
        guard !isLocked else { return }

        // Parse BMI286 accelerometer data (Q16 fixed-point, little-endian)
        let x = parseQ16(report + 6)
        let y = parseQ16(report + 10)
        let z = parseQ16(report + 14)

        reportCount += 1

        // Multi-algorithm voting
        let verdict = processor.process(x: x, y: y, z: z)

        guard verdict.detected else { return }

        // Debounce
        let now = Date()
        guard now.timeIntervalSince(lastSlapTime) >= debounceInterval else { return }
        lastSlapTime = now

        #if DEBUG
        print("🏋️ [Accelerometer] 💥 SLAP! votes=\(verdict.votes)/4 mag=\(String(format: "%.3f", verdict.magnitude))g conf=\(String(format: "%.2f", verdict.confidence))")
        #endif

        onEvent?(.slap(pressure: verdict.confidence, source: "body"))
    }

    private func parseQ16(_ ptr: UnsafeMutablePointer<UInt8>) -> Double {
        let raw = Int32(ptr[0]) | (Int32(ptr[1]) << 8) | (Int32(ptr[2]) << 16) | (Int32(ptr[3]) << 24)
        return Double(raw) / 65536.0
    }
}

// MARK: - C Callback

private func accelReportCallback(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    type: IOHIDReportType,
    reportID: UInt32,
    report: UnsafeMutablePointer<UInt8>,
    reportLength: CFIndex
) {
    guard let context else { return }
    let detector = Unmanaged<AccelerometerDetector>.fromOpaque(context).takeUnretainedValue()
    detector.handleReport(report, length: reportLength)
}
#endif
