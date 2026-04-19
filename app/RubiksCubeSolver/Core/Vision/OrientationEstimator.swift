import Foundation

/// Determines which cube face is toward the camera by matching the live
/// center-sticker color against the known faces of the scanned `CubeState`.
///
/// Also reports whether the user is using the front (mirror) camera so the
/// solve guide can flip left/right when phrasing instructions.
///
/// Real AR overlay uses device motion too (see `CMDeviceMotion` tilt); this
/// simple estimator only needs the dominant color of the center sticker,
/// which the classifier already provides. The view layer calls
/// `OrientationEstimator.infer(centerColor:)` after each scan-like frame.
public struct OrientationEstimator {
    public let cube: CubeState

    public init(cube: CubeState) { self.cube = cube }

    /// Map an observed center color to the face currently pointed at the
    /// camera. Returns `nil` if the cube doesn't have that color as any
    /// center (shouldn't happen for validated cubes).
    public func faceFacingCamera(centerColor: StickerColor) -> FaceKind? {
        FaceKind.allCases.first { cube[$0].center == centerColor }
    }

    /// Derive the user's `PrescriptiveGuide.Orientation` from the face they
    /// currently see. `topColor` is inferred from which face sits "above"
    /// the visible face in the cube's adjacency, defaulting to the U-face
    /// color if we can't tell from the image alone.
    public func orientation(facingFace: FaceKind,
                            observedTopColor: StickerColor?,
                            usingFrontCamera: Bool) -> PrescriptiveGuide.Orientation {
        let frontColor = cube[facingFace].center
        let topColor = observedTopColor ?? cube[.U].center
        return PrescriptiveGuide.Orientation(
            topColor: topColor,
            frontColor: frontColor,
            usingFrontCamera: usingFrontCamera
        )
    }
}
