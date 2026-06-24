import Foundation
import SwiftUI

/// Drives the six-face scan flow: tracks which face is being captured, holds
/// the classified colors per face, and assembles a `CubeState` at the end.
@MainActor
final class ScanViewModel: ObservableObject {
    /// Scripted order — matches the on-screen net diagram in `ScanFlowView`.
    static let captureOrder: [FaceKind] = [.U, .R, .F, .D, .L, .B]

    @Published var currentIndex: Int = 0
    @Published var capturedFaces: [FaceKind: [StickerColor]] = [:]
    @Published var lastCapturedImage: UIImage?
    @Published var isClassifying: Bool = false
    @Published var errorMessage: String?

    let classifier: StickerClassifier

    init(classifier: StickerClassifier) {
        self.classifier = classifier
    }

    var currentFace: FaceKind? {
        guard currentIndex < Self.captureOrder.count else { return nil }
        return Self.captureOrder[currentIndex]
    }

    var isComplete: Bool { capturedFaces.count == 6 }

    /// Classify a captured JPEG against the current expected face. Saves the
    /// classified colors and advances the index on success.
    func ingest(jpeg: Data) async {
        guard let face = currentFace else { return }
        isClassifying = true
        errorMessage = nil
        defer { isClassifying = false }
        do {
            let colors = try await classifier.classify(faceJPEG: jpeg, faceLabel: face)
            capturedFaces[face] = colors
            if let ui = UIImage(data: jpeg) { lastCapturedImage = ui }
            advance()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func advance() {
        if currentIndex < Self.captureOrder.count { currentIndex += 1 }
    }

    func retakeCurrent() {
        if let face = currentFace { capturedFaces[face] = nil }
    }

    /// Apply a user-edit from `StickerGridEditor` to the face's stored grid.
    func overwrite(face: FaceKind, colors: [StickerColor]) {
        capturedFaces[face] = colors
    }

    /// Assemble the six faces into a full `CubeState`. Returns `nil` if any
    /// face is missing or sticker count is wrong.
    func buildCube() -> CubeState? {
        var faces: [Face] = []
        for kind in FaceKind.allCases {
            guard let colors = capturedFaces[kind], colors.count == 9 else {
                return nil
            }
            faces.append(Face(stickers: colors))
        }
        return CubeState(faces: faces)
    }
}
