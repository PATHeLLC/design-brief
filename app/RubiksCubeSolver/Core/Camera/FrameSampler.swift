import CoreMedia
import CoreVideo
import Foundation
import QuartzCore

/// Throttles a live `CVPixelBuffer` stream to a target interval. Designed so
/// that `GridDetector` and `StickerClassifier` don't run on every frame (30
/// Hz is wasteful for cube scanning — 4 Hz is plenty).
public final class FrameSampler {
    private let interval: TimeInterval
    private let handler: (CVPixelBuffer) -> Void
    private var lastEmission: TimeInterval = 0
    private let lock = NSLock()

    public init(interval: TimeInterval = 0.25,
                handler: @escaping (CVPixelBuffer) -> Void) {
        self.interval = interval
        self.handler = handler
    }

    public func receive(_ buffer: CVPixelBuffer) {
        let now = CACurrentMediaTime()
        lock.lock()
        let shouldEmit = now - lastEmission >= interval
        if shouldEmit { lastEmission = now }
        lock.unlock()
        if shouldEmit { handler(buffer) }
    }
}
