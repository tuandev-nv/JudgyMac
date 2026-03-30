import Foundation

/// Reads system CPU usage via host_statistics64 (sandbox safe, same as RunCat).
final class CPUMonitor: @unchecked Sendable {
    private var previousTicks: (user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)?

    /// Returns CPU usage 0.0 - 1.0. Call periodically (every 1-2 seconds).
    func currentUsage() -> Double {
        var loadInfo = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &loadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }

        let user = UInt64(loadInfo.cpu_ticks.0)   // CPU_STATE_USER
        let system = UInt64(loadInfo.cpu_ticks.1)  // CPU_STATE_SYSTEM
        let idle = UInt64(loadInfo.cpu_ticks.2)    // CPU_STATE_IDLE
        let nice = UInt64(loadInfo.cpu_ticks.3)    // CPU_STATE_NICE

        defer {
            previousTicks = (user, system, idle, nice)
        }

        guard let prev = previousTicks else { return 0 }

        let userDelta = user - prev.user
        let systemDelta = system - prev.system
        let idleDelta = idle - prev.idle
        let niceDelta = nice - prev.nice
        let totalDelta = userDelta + systemDelta + idleDelta + niceDelta

        guard totalDelta > 0 else { return 0 }

        return Double(userDelta + systemDelta + niceDelta) / Double(totalDelta)
    }
}
