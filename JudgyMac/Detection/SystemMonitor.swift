import Foundation
import IOKit

/// Reads RAM usage via host_statistics64 (sandbox safe).
/// Returns fraction 0.0 - 1.0.
func currentRAMUsage() -> Double {
    var stats = vm_statistics64_data_t()
    var count = mach_msg_type_number_t(
        MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
    )

    let result = withUnsafeMutablePointer(to: &stats) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
        }
    }
    guard result == KERN_SUCCESS else { return 0 }

    let pageSize = UInt64(getpagesize())
    let active = UInt64(stats.active_count) * pageSize
    let wired = UInt64(stats.wire_count) * pageSize
    let compressed = UInt64(stats.compressor_page_count) * pageSize
    let used = active + wired + compressed

    let total = UInt64(ProcessInfo.processInfo.physicalMemory)
    guard total > 0 else { return 0 }

    return Double(used) / Double(total)
}

/// Reads disk usage for the boot volume.
/// Returns fraction 0.0 - 1.0.
func currentDiskUsage() -> Double {
    guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
          let totalSize = attrs[.systemSize] as? UInt64,
          let freeSize = attrs[.systemFreeSize] as? UInt64,
          totalSize > 0
    else { return 0 }

    return Double(totalSize - freeSize) / Double(totalSize)
}

/// Reads GPU usage via IOKit (Apple Silicon integrated GPU).
/// Returns fraction 0.0 - 1.0, or 0 if not available.
func currentGPUUsage() -> Double {
    var iterator: io_iterator_t = 0
    let matching = IOServiceMatching("IOAccelerator")

    guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
        return 0
    }
    defer { IOObjectRelease(iterator) }

    var entry = IOIteratorNext(iterator)
    while entry != 0 {
        defer { IOObjectRelease(entry) }

        var properties: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = properties?.takeRetainedValue() as? [String: Any],
              let perfStats = dict["PerformanceStatistics"] as? [String: Any]
        else {
            entry = IOIteratorNext(iterator)
            continue
        }

        // Apple Silicon uses "Device Utilization %" or "GPU Activity(%)"
        if let utilization = perfStats["Device Utilization %"] as? Int {
            return Double(utilization) / 100.0
        }
        if let activity = perfStats["GPU Activity(%)"] as? Int {
            return Double(activity) / 100.0
        }

        entry = IOIteratorNext(iterator)
    }

    return 0
}
