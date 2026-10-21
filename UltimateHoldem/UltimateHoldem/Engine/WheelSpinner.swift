import Foundation

enum WheelSpinner {
    /// Picks a segment index using each segment's weight.
    static func pickIndex<G: RandomNumberGenerator>(segments: [WheelSegment] = GameConfig.wheelSegments,
                                                     using generator: inout G) -> Int {
        let total = segments.reduce(0) { $0 + $1.weight }
        var roll = Int.random(in: 0..<total, using: &generator)
        for (i, s) in segments.enumerated() {
            if roll < s.weight { return i }
            roll -= s.weight
        }
        return segments.count - 1
    }

    static func pickIndex() -> Int {
        var g = SystemRandomNumberGenerator()
        return pickIndex(using: &g)
    }

    /// Final wheel rotation (degrees) so the chosen segment lands under the top pointer.
    /// Segment 0 starts at the top and segments run clockwise.
    static func targetRotation(for index: Int, segmentCount: Int, currentRotation: Double, extraSpins: Int = 6) -> Double {
        let slice = 360.0 / Double(segmentCount)
        let jitter = Double.random(in: -slice * 0.3...slice * 0.3)
        // Rotating the wheel clockwise by R moves angle a to a+R; we need center of index at 0 (top).
        let center = slice * Double(index) + slice / 2
        let base = (360 - center + jitter).truncatingRemainder(dividingBy: 360)
        let currentMod = currentRotation.truncatingRemainder(dividingBy: 360)
        var delta = base - currentMod
        if delta < 0 { delta += 360 }
        return currentRotation + delta + Double(extraSpins) * 360
    }
}
