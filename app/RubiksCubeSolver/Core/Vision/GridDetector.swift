import CoreImage
import Foundation
import Vision

/// Detects a square-ish 3x3 grid (the face of a cube) in a live camera frame.
///
/// Uses `VNDetectRectanglesRequest` with a tight aspect-ratio window. The
/// detection is used for two things:
///   1. Draw a lock-on overlay in `FaceCaptureView` so the user knows when a
///      face is well-framed.
///   2. Hold detection stable for ~400 ms, then trigger auto-capture.
public struct GridDetector {
    public struct Detection: Equatable {
        /// Normalized 0..1 rect in Vision's coordinate space (origin bottom-left).
        public var normalizedRect: CGRect
        public var confidence: Float
    }

    public init() {}

    public func detect(in pixelBuffer: CVPixelBuffer) async -> Detection? {
        await withCheckedContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, _ in
                let best = (request.results as? [VNRectangleObservation])?
                    .filter { $0.confidence > 0.5 }
                    .max { $0.confidence < $1.confidence }
                if let r = best {
                    continuation.resume(returning: Detection(
                        normalizedRect: r.boundingBox,
                        confidence: r.confidence
                    ))
                } else {
                    continuation.resume(returning: nil)
                }
            }
            request.minimumAspectRatio = 0.85
            request.maximumAspectRatio = 1.15
            request.minimumSize = 0.2
            request.quadratureTolerance = 15
            request.maximumObservations = 4

            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: .up
            )
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
}
