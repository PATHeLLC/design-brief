import Foundation

/// Teach-friendly solver. Decomposes the solve into four pedagogical stages
/// and finds moves for each independently.
///
/// Scaffold caveat: each stage uses plain IDDFS (`SearchEngine`). Real
/// beginner-method implementations use explicit case tables (F2L 41 cases,
/// OLL 57, PLL 21) which run in constant time. IDDFS is slower but doesn't
/// require encoding those tables — fine for teaching simple scrambles.
public struct BeginnerSolver: Solver {
    public let displayName = "Beginner"
    public init() {}

    public func solve(_ cube: CubeState) throws -> [SolveStep] {
        var state = cube
        var steps: [SolveStep] = []

        let downColor = state[.D].center
        let upColor = state[.U].center

        // Stage 1: White (down) cross.
        let cross = try SearchEngine.search(
            start: state, maxDepth: 8, stageLabel: "Bottom cross"
        ) { isCrossSolved($0, downColor: downColor) }
        state.apply(cross)
        steps.append(SolveStep(
            stage: "Bottom cross",
            moves: cross,
            rationale: "Line up the four edges of the \(downColor.displayName) face so each edge also matches its side-center color. This is the foundation of the solve."
        ))

        // Stage 2: First two layers (bottom + middle).
        let f2l = try SearchEngine.search(
            start: state, maxDepth: 14, stageLabel: "First two layers"
        ) { isF2LSolved($0, downColor: downColor) }
        state.apply(f2l)
        steps.append(SolveStep(
            stage: "First two layers",
            moves: f2l,
            rationale: "Insert each corner-edge pair to finish the bottom and middle layers. After this, only the top layer remains."
        ))

        // Stage 3: Orient Last Layer — all top stickers match up-center color.
        let oll = try SearchEngine.search(
            start: state, maxDepth: 12, stageLabel: "Orient last layer"
        ) { isOLLSolved($0, upColor: upColor) }
        state.apply(oll)
        steps.append(SolveStep(
            stage: "Orient last layer",
            moves: oll,
            rationale: "Flip and rotate the top pieces so the entire top face shows \(upColor.displayName). Pieces may still be in the wrong slots — that's the next stage."
        ))

        // Stage 4: Permute Last Layer — full solve.
        let pll = try SearchEngine.search(
            start: state, maxDepth: 14, stageLabel: "Permute last layer"
        ) { $0.isSolved }
        state.apply(pll)
        steps.append(SolveStep(
            stage: "Permute last layer",
            moves: pll,
            rationale: "Swap the top-layer pieces into their correct positions. Done!"
        ))

        return steps.filter { !$0.moves.isEmpty }
    }

    // MARK: - Stage goal predicates

    /// Cross done: the four edges of the D face are the correct color AND
    /// the side sticker on each of those edges matches the neighboring
    /// center.
    private func isCrossSolved(_ c: CubeState, downColor: StickerColor) -> Bool {
        // Edge positions on D: indices 1,3,5,7 in row-major order.
        // 1 -> F side, 3 -> L side, 5 -> R side, 7 -> B side.
        guard c[.D].stickers[1] == downColor,
              c[.D].stickers[3] == downColor,
              c[.D].stickers[5] == downColor,
              c[.D].stickers[7] == downColor
        else { return false }
        // The side stickers on each edge come from F7, L7, R7, B7.
        return c[.F].stickers[7] == c[.F].center
            && c[.L].stickers[7] == c[.L].center
            && c[.R].stickers[7] == c[.R].center
            && c[.B].stickers[7] == c[.B].center
    }

    /// F2L done: the entire D face shows the down-color, and the bottom two
    /// rows of each side face match that side's center.
    private func isF2LSolved(_ c: CubeState, downColor: StickerColor) -> Bool {
        guard c[.D].stickers.allSatisfy({ $0 == downColor }) else { return false }
        for side in [FaceKind.F, .R, .B, .L] {
            let face = c[side]
            let center = face.center
            // Rows 1 and 2 (indices 3..8) must all match center.
            for i in 3...8 where face.stickers[i] != center { return false }
        }
        return true
    }

    /// OLL done: all nine stickers on the U face are the up-color.
    private func isOLLSolved(_ c: CubeState, upColor: StickerColor) -> Bool {
        c[.U].stickers.allSatisfy { $0 == upColor }
    }
}
