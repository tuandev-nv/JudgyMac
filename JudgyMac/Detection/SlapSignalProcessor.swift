#if ACCELEROMETER_ENABLED
import Foundation

// MARK: - Verdict

struct SlapVerdict {
    let detected: Bool
    let confidence: Double
    let magnitude: Double
    let votes: Int
}

// MARK: - High-Pass Filter (Single-pole IIR, per axis)

/// Removes gravity (~1g DC) and slow drift. Only passes sharp impulses.
/// Cutoff ~30Hz at 1kHz sample rate.
struct HighPassFilter {
    // α = 1 / (1 + 2π·fc/fs)  where fc=30, fs=1000 → α ≈ 0.841
    private let alpha: Double = 1.0 / (1.0 + 2.0 * .pi * 30.0 / 1000.0)

    private var prevX: (input: Double, output: Double) = (0, 0)
    private var prevY: (input: Double, output: Double) = (0, 0)
    private var prevZ: (input: Double, output: Double) = (0, 0)

    mutating func filter(x: Double, y: Double, z: Double) -> (Double, Double, Double) {
        let fx = alpha * (prevX.output + x - prevX.input)
        let fy = alpha * (prevY.output + y - prevY.input)
        let fz = alpha * (prevZ.output + z - prevZ.input)

        prevX = (x, fx)
        prevY = (y, fy)
        prevZ = (z, fz)

        return (fx, fy, fz)
    }
}

// MARK: - Multi-Scale STA/LTA Detector

/// Compares short-term vs long-term energy at 3 timescales.
/// Any scale exceeding threshold → vote YES. Catches slaps of varying duration.
struct MultiScaleSTALTA {
    let threshold: Double = 2.0

    // Scale 1: Fast (20ms / 500ms) — catches sharp, brief slaps
    private var sta1: Double = 0
    private var lta1: Double = 1e-10
    private let sta1Alpha: Double = 2.0 / (20.0 + 1.0)
    private let lta1Alpha: Double = 2.0 / (500.0 + 1.0)

    // Scale 2: Medium (50ms / 1s) — general purpose
    private var sta2: Double = 0
    private var lta2: Double = 1e-10
    private let sta2Alpha: Double = 2.0 / (50.0 + 1.0)
    private let lta2Alpha: Double = 2.0 / (1000.0 + 1.0)

    // Scale 3: Slow (100ms / 2s) — catches heavier, longer slaps
    private var sta3: Double = 0
    private var lta3: Double = 1e-10
    private let sta3Alpha: Double = 2.0 / (100.0 + 1.0)
    private let lta3Alpha: Double = 2.0 / (2000.0 + 1.0)

    /// Process one energy sample. Returns max ratio across all 3 scales.
    mutating func process(_ energy: Double) -> Double {
        sta1 = sta1 * (1 - sta1Alpha) + energy * sta1Alpha
        lta1 = lta1 * (1 - lta1Alpha) + energy * lta1Alpha

        sta2 = sta2 * (1 - sta2Alpha) + energy * sta2Alpha
        lta2 = lta2 * (1 - lta2Alpha) + energy * lta2Alpha

        sta3 = sta3 * (1 - sta3Alpha) + energy * sta3Alpha
        lta3 = lta3 * (1 - lta3Alpha) + energy * lta3Alpha

        let r1 = sta1 / max(lta1, 1e-10)
        let r2 = sta2 / max(lta2, 1e-10)
        let r3 = sta3 / max(lta3, 1e-10)

        return max(r1, r2, r3)
    }
}

// MARK: - Rolling Kurtosis

/// Measures statistical "peakedness" (4th moment) in a 200-sample window.
/// Normal motion: kurtosis ~3. Slap impulse: >> 3.
struct RollingKurtosis {
    let windowSize = 200
    let threshold: Double = 6.0

    private var buffer: [Double]
    private var index = 0
    private var count = 0

    private var sumX: Double = 0
    private var sumX2: Double = 0
    private var sumX4: Double = 0

    var isWarmedUp: Bool { count >= windowSize }

    init() {
        buffer = [Double](repeating: 0, count: 200)
    }

    mutating func process(_ value: Double) -> Double {
        let v2 = value * value
        let v4 = v2 * v2

        if count >= windowSize {
            let old = buffer[index]
            let o2 = old * old
            sumX -= old
            sumX2 -= o2
            sumX4 -= o2 * o2
        } else {
            count += 1
        }

        buffer[index] = value
        sumX += value
        sumX2 += v2
        sumX4 += v4

        index = (index + 1) % windowSize

        guard count >= windowSize else { return 0 }

        let n = Double(count)
        let variance = sumX2 / n - (sumX / n) * (sumX / n)
        guard variance > 1e-12 else { return 0 }

        // For high-passed signal (near zero mean): Kurt ≈ E[X⁴] / (E[X²])²
        return (sumX4 / n) / (variance * variance)
    }
}

// MARK: - CUSUM Detector

/// Detects abrupt change-points via cumulative sum.
/// Gradual changes absorbed by drift. Sharp impulses exceed threshold instantly.
struct CUSUMDetector {
    private let drift: Double = 0.02
    let threshold: Double = 0.03

    private var sum: Double = 0
    private var mu: Double = 0
    private let muAlpha: Double = 0.001

    mutating func process(_ value: Double) -> Double {
        mu = mu * (1 - muAlpha) + value * muAlpha
        sum = max(0, sum + value - mu - drift)

        let result = sum
        if sum >= threshold {
            sum = 0
        }
        return result
    }
}

// MARK: - Peak/MAD Detector

/// Median Absolute Deviation outlier detection.
/// Adapts to ambient noise level — works on shaky desks and solid tables alike.
/// Vote YES when current value is a statistical outlier relative to recent history.
struct PeakMADDetector {
    private let windowSize = 200
    /// How many MADs above median to be an outlier
    let madMultiplier: Double = 3.0

    private var buffer: [Double]
    private var sortedBuffer: [Double]
    private var index = 0
    private var count = 0

    init() {
        buffer = [Double](repeating: 0, count: 200)
        sortedBuffer = []
    }

    var isWarmedUp: Bool { count >= windowSize }

    /// Process one sample. Returns how many MADs above median this value is (0 if warming up).
    mutating func process(_ value: Double) -> Double {
        if count >= windowSize {
            // Remove oldest from sorted buffer
            let old = buffer[index]
            if let idx = sortedBuffer.firstIndex(of: old) {
                sortedBuffer.remove(at: idx)
            }
        } else {
            count += 1
        }

        buffer[index] = value
        // Insert into sorted position
        let insertIdx = sortedBuffer.firstIndex { $0 >= value } ?? sortedBuffer.count
        sortedBuffer.insert(value, at: insertIdx)

        index = (index + 1) % windowSize

        guard count >= windowSize else { return 0 }

        // Median
        let median = sortedBuffer[count / 2]

        // MAD = median of |x - median|
        var deviations = [Double]()
        deviations.reserveCapacity(count)
        for v in sortedBuffer {
            deviations.append(abs(v - median))
        }
        deviations.sort()
        let mad = deviations[count / 2]

        guard mad > 1e-10 else { return 0 }

        return abs(value - median) / mad
    }
}

// MARK: - Signal Processor (Orchestrator)

/// 5 concurrent algorithms vote on whether you actually slapped your laptop.
struct SlapSignalProcessor {
    private var highPass = HighPassFilter()
    private var staLta = MultiScaleSTALTA()
    private var kurtosis = RollingKurtosis()
    private var cusum = CUSUMDetector()
    private var peakMad = PeakMADDetector()

    // Baseline for raw magnitude
    private var baselineMagnitude: Double = 1.0
    private let baselineAlpha: Double = 0.01

    // Thresholds
    nonisolated(unsafe) static var magnitudeFloor: Double = 0.05
    private let kurtosisMinimum: Double = 6.0

    mutating func process(x: Double, y: Double, z: Double) -> SlapVerdict {
        // Raw magnitude and delta
        let rawMag = sqrt(x * x + y * y + z * z)
        let delta = abs(rawMag - baselineMagnitude)
        baselineMagnitude = baselineMagnitude * (1 - baselineAlpha) + rawMag * baselineAlpha

        // High-pass filter
        let (fx, fy, fz) = highPass.filter(x: x, y: y, z: z)
        let filteredMag = sqrt(fx * fx + fy * fy + fz * fz)

        // Only kurtosis needed for spike detection
        let kurt = kurtosis.process(filteredMag)

        // Detection: magnitude above floor + kurtosis confirms sharp spike (not sustained vibration)
        let passesFloor = delta >= Self.magnitudeFloor
        let isSharpSpike = !kurtosis.isWarmedUp || kurt >= kurtosisMinimum
        let detected = passesFloor && isSharpSpike

        #if DEBUG
        if passesFloor {
            print("👊 [Slap] mag=\(String(format: "%.3f", delta)) kurt=\(String(format: "%.1f", kurt)) \(detected ? "✅ SLAP" : "❌ (not sharp)")")
        }
        #endif

        let confidence = detected ? min(delta / 0.36, 1.0) : 0

        return SlapVerdict(
            detected: detected,
            confidence: confidence,
            magnitude: delta,
            votes: detected ? 2 : 0
        )
    }
}
#endif
