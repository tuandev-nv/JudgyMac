import IOKit
import IOKit.hid
import Foundation
import QuartzCore

/// Reads MacBook lid angle via IOKit HID sensor (Apple Silicon).
/// Adapted from github.com/samhenrigold/LidAngleSensor.
final class LidAngleSensor: @unchecked Sendable {

    // MARK: - State

    private(set) var angle = 120.0
    private(set) var velocity = 0.0
    private(set) var isAvailable = false

    // MARK: - HID

    private var hidDevice: IOHIDDevice?
    private var isDeviceOpen = false
    private var timer: Timer?
    private var hidReport = [UInt8](repeating: 0, count: 8)

    // MARK: - Velocity Smoothing

    private var lastAngle = 0.0
    private var smoothedAngle = 0.0
    private var smoothedVelocity = 0.0
    private var lastUpdateTime: TimeInterval = 0
    private var lastMovementTime: TimeInterval = 0
    private var isFirstUpdate = true

    private static let noOptions = IOOptionBits(kIOHIDOptionsTypeNone)
    private static let angleSmoothingFactor = 0.3
    private static let velocitySmoothingFactor = 0.6
    private static let movementThreshold = 0.3
    private static let movementTimeout: TimeInterval = 0.03
    private static let velocityDecay = 0.3
    private static let additionalDecay = 0.5

    // MARK: - Init

    init() {
        if let device = Self.findHIDDevice() {
            hidDevice = device
            isAvailable = true
            #if DEBUG
            print("🔧 [LidAngle] Sensor available")
            #endif
        } else {
            #if DEBUG
            print("🔧 [LidAngle] Sensor not found on this Mac")
            #endif
        }
    }

    deinit {
        stop()
    }

    // MARK: - Control

    func start() {
        guard isAvailable, timer == nil, let device = hidDevice else { return }
        guard IOHIDDeviceOpen(device, Self.noOptions) == kIOReturnSuccess else { return }
        isDeviceOpen = true
        timer = .scheduledTimer(withTimeInterval: 1.0 / 10.0, repeats: true) { [weak self] _ in
            self?.poll()
        }
        #if DEBUG
        print("🔧 [LidAngle] Started polling at 30Hz")
        #endif
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if isDeviceOpen, let device = hidDevice {
            IOHIDDeviceClose(device, Self.noOptions)
            isDeviceOpen = false
        }
    }

    // MARK: - Polling

    private func poll() {
        guard let device = hidDevice else { return }

        var length = CFIndex(hidReport.count)
        let result = IOHIDDeviceGetReport(
            device,
            kIOHIDReportTypeFeature,
            1,
            &hidReport,
            &length
        )

        guard result == kIOReturnSuccess, length >= 3 else { return }

        let rawValue = UInt16(hidReport[2]) << 8 | UInt16(hidReport[1])
        let rawAngle = Double(rawValue)

        updateVelocity(from: rawAngle)
        angle = rawAngle
    }

    // MARK: - Velocity

    private func updateVelocity(from rawAngle: Double) {
        let now = CACurrentMediaTime()

        guard !isFirstUpdate else {
            lastAngle = rawAngle
            smoothedAngle = rawAngle
            lastUpdateTime = now
            lastMovementTime = now
            isFirstUpdate = false
            return
        }

        let dt = now - lastUpdateTime
        guard dt > 0, dt < 1.0 else {
            lastUpdateTime = now
            return
        }

        smoothedAngle = Self.angleSmoothingFactor * rawAngle
            + (1 - Self.angleSmoothingFactor) * smoothedAngle

        let delta = smoothedAngle - lastAngle
        let instantVelocity: Double

        if abs(delta) < Self.movementThreshold {
            instantVelocity = 0
        } else {
            instantVelocity = abs(delta / dt)
            lastAngle = smoothedAngle
        }

        if instantVelocity > 0 {
            smoothedVelocity = Self.velocitySmoothingFactor * instantVelocity
                + (1 - Self.velocitySmoothingFactor) * smoothedVelocity
            lastMovementTime = now
        } else {
            smoothedVelocity *= Self.velocityDecay
        }

        if now - lastMovementTime > Self.movementTimeout {
            smoothedVelocity *= Self.additionalDecay
        }

        lastUpdateTime = now
        velocity = smoothedVelocity
    }

    // MARK: - HID Device Discovery

    private static func findHIDDevice() -> IOHIDDevice? {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, noOptions)
        guard IOHIDManagerOpen(manager, noOptions) == kIOReturnSuccess else { return nil }
        defer { IOHIDManagerClose(manager, noOptions) }

        let matching: [String: Any] = [
            kIOHIDVendorIDKey as String: 0x05AC,
            kIOHIDProductIDKey as String: 0x8104,
            "UsagePage": 0x0020,
            "Usage": 0x008A,
        ]

        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)

        guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>,
              !devices.isEmpty else { return nil }

        for device in devices {
            guard IOHIDDeviceOpen(device, noOptions) == kIOReturnSuccess else { continue }
            defer { IOHIDDeviceClose(device, noOptions) }

            var report = [UInt8](repeating: 0, count: 8)
            var length = CFIndex(report.count)

            let result = IOHIDDeviceGetReport(
                device,
                kIOHIDReportTypeFeature,
                1,
                &report,
                &length
            )

            if result == kIOReturnSuccess, length >= 3 {
                return device
            }
        }
        return nil
    }
}
