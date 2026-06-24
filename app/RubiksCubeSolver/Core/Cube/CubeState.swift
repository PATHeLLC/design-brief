import Foundation

/// A full 3x3x3 cube represented as six faces of nine stickers each.
///
/// Face index order follows `FaceKind.rawValue`: U R F D L B. Within each
/// face, stickers are row-major starting from the top-left as viewed with
/// that face toward the camera.
public struct CubeState: Codable, Hashable {
    public var faces: [Face]  // count == 6, indexed by FaceKind.rawValue

    public init(faces: [Face]) {
        precondition(faces.count == 6, "A cube has exactly 6 faces")
        self.faces = faces
    }

    /// A cube with each face a solid block of its conventional color.
    public static var solved: CubeState {
        CubeState(faces: FaceKind.allCases.map { Face(uniform: $0.conventionalColor) })
    }

    public subscript(face: FaceKind) -> Face {
        get { faces[face.rawValue] }
        set { faces[face.rawValue] = newValue }
    }

    public var isSolved: Bool {
        faces.allSatisfy { face in face.stickers.allSatisfy { $0 == face.center } }
    }

    // MARK: - Move application

    public mutating func apply(_ move: Move) {
        let turns: Int = {
            switch move.direction {
            case .cw:     return 1
            case .ccw:    return 3
            case .double: return 2
            }
        }()
        for _ in 0..<turns { applyQuarter(face: move.face) }
    }

    public mutating func apply(_ moves: [Move]) {
        for m in moves { apply(m) }
    }

    public func applying(_ moves: [Move]) -> CubeState {
        var c = self; c.apply(moves); return c
    }

    /// Apply a single clockwise quarter-turn on `face`.
    private mutating func applyQuarter(face: FaceKind) {
        faces[face.rawValue].rotateClockwise()
        cycleEdge(face)
    }

    /// Cycle the four adjacent edge strips around `face` one step clockwise.
    ///
    /// Each entry is a triple of (adjacent face, sticker index in that face).
    /// The three indices describe the row/column that touches `face`, listed
    /// in the order they appear when walking the edge clockwise as seen from
    /// outside `face`.
    private mutating func cycleEdge(_ face: FaceKind) {
        let ring = Self.edgeRing[face]!
        // Snapshot the first ring's stickers.
        let first = ring[0]
        let saved = first.map { faces[$0.face.rawValue].stickers[$0.index] }
        // Shift ring[i] <- ring[i+1] for i in 0..<3
        for i in 0..<3 {
            let dst = ring[i]
            let src = ring[i + 1]
            for k in 0..<3 {
                faces[dst[k].face.rawValue].stickers[dst[k].index] =
                    faces[src[k].face.rawValue].stickers[src[k].index]
            }
        }
        // Last ring <- saved
        let last = ring[3]
        for k in 0..<3 {
            faces[last[k].face.rawValue].stickers[last[k].index] = saved[k]
        }
    }

    // MARK: - Edge-ring tables

    private struct Slot: Hashable { let face: FaceKind; let index: Int }

    /// For each face, the four adjacent 3-sticker strips in clockwise order
    /// (as seen from outside that face). Indices are row-major positions
    /// (0..8) on the adjacent face.
    ///
    /// These tables are the single source of truth for move semantics.
    /// Verified by `CubeStateTests.testScrambleAndInverseReturnsSolved`.
    private static let edgeRing: [FaceKind: [[Slot]]] = {
        typealias S = Slot
        // Helper: make a 3-slot strip on a face from three index positions.
        func strip(_ f: FaceKind, _ a: Int, _ b: Int, _ c: Int) -> [Slot] {
            [S(face: f, index: a), S(face: f, index: b), S(face: f, index: c)]
        }
        return [
            // U (white): clockwise around U from above is B -> R -> F -> L,
            // each contributing its top row (indices 0,1,2).
            .U: [
                strip(.B, 0, 1, 2),
                strip(.R, 0, 1, 2),
                strip(.F, 0, 1, 2),
                strip(.L, 0, 1, 2),
            ],
            // D (yellow): clockwise around D from below is F -> R -> B -> L,
            // each contributing its bottom row (indices 6,7,8).
            .D: [
                strip(.F, 6, 7, 8),
                strip(.R, 6, 7, 8),
                strip(.B, 6, 7, 8),
                strip(.L, 6, 7, 8),
            ],
            // R (red): clockwise around R from the right is U -> B -> D -> F.
            // U contributes its right column top-to-bottom (2,5,8).
            // B contributes its left column bottom-to-top (6,3,0).
            // D contributes its right column bottom-to-top (8,5,2).
            // F contributes its right column top-to-bottom (2,5,8).
            .R: [
                strip(.U, 2, 5, 8),
                strip(.B, 6, 3, 0),
                strip(.D, 8, 5, 2),
                strip(.F, 2, 5, 8),
            ],
            // L (orange): clockwise from the left is U -> F -> D -> B.
            // U left column top-to-bottom (0,3,6).
            // F left column top-to-bottom (0,3,6).
            // D left column bottom-to-top (6,3,0).
            // B right column bottom-to-top (8,5,2).
            .L: [
                strip(.U, 0, 3, 6),
                strip(.F, 0, 3, 6),
                strip(.D, 6, 3, 0),
                strip(.B, 8, 5, 2),
            ],
            // F (green): clockwise from the front is U -> R -> D -> L.
            // U bottom row left-to-right (6,7,8).
            // R left column top-to-bottom (0,3,6).
            // D top row right-to-left (2,1,0).
            // L right column bottom-to-top (8,5,2).
            .F: [
                strip(.U, 6, 7, 8),
                strip(.R, 0, 3, 6),
                strip(.D, 2, 1, 0),
                strip(.L, 8, 5, 2),
            ],
            // B (blue): clockwise from the back is U -> L -> D -> R.
            // U top row right-to-left (2,1,0).
            // L left column top-to-bottom (0,3,6).
            // D bottom row left-to-right (6,7,8).
            // R right column bottom-to-top (8,5,2).
            .B: [
                strip(.U, 2, 1, 0),
                strip(.L, 0, 3, 6),
                strip(.D, 6, 7, 8),
                strip(.R, 8, 5, 2),
            ],
        ]
    }()
}
