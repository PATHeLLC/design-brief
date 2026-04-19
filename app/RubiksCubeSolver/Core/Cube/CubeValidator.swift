import Foundation

public enum CubeValidationError: Error, LocalizedError, Equatable {
    case wrongFaceCount(got: Int)
    case wrongStickerCount(face: FaceKind, got: Int)
    case colorCountMismatch(color: StickerColor, got: Int)
    case duplicateCenter(StickerColor)
    case missingCenterColor(StickerColor)

    public var errorDescription: String? {
        switch self {
        case .wrongFaceCount(let n):
            return "Expected 6 faces, got \(n)."
        case .wrongStickerCount(let f, let n):
            return "Face \(f.letter) should have 9 stickers, got \(n)."
        case .colorCountMismatch(let c, let n):
            return "Expected 9 \(c.displayName) stickers, found \(n)."
        case .duplicateCenter(let c):
            return "Two faces have the same \(c.displayName) center."
        case .missingCenterColor(let c):
            return "No face has a \(c.displayName) center."
        }
    }
}

/// Structural validation of a scanned cube state.
///
/// Checks that each face has 9 stickers, each color appears exactly 9 times
/// across the cube, and that the six centers cover all six colors.
///
/// Full permutation+orientation parity checks are not performed here — the
/// solver will reject unsolvable scans naturally.
public enum CubeValidator {
    public static func validate(_ cube: CubeState) -> Result<Void, CubeValidationError> {
        guard cube.faces.count == 6 else {
            return .failure(.wrongFaceCount(got: cube.faces.count))
        }
        for face in FaceKind.allCases {
            let count = cube[face].stickers.count
            guard count == 9 else {
                return .failure(.wrongStickerCount(face: face, got: count))
            }
        }
        // Color counts across all 54 stickers.
        var counts: [StickerColor: Int] = [:]
        for face in cube.faces {
            for s in face.stickers { counts[s, default: 0] += 1 }
        }
        for color in StickerColor.allCases {
            let got = counts[color] ?? 0
            guard got == 9 else {
                return .failure(.colorCountMismatch(color: color, got: got))
            }
        }
        // Centers must cover all six colors uniquely.
        let centers = cube.faces.map(\.center)
        let centerSet = Set(centers)
        guard centerSet.count == 6 else {
            let dup = centers.first { c in centers.filter { $0 == c }.count > 1 }!
            return .failure(.duplicateCenter(dup))
        }
        for color in StickerColor.allCases {
            guard centerSet.contains(color) else {
                return .failure(.missingCenterColor(color))
            }
        }
        return .success(())
    }
}
