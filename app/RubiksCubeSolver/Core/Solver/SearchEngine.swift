import Foundation

/// Shared iterative-deepening DFS search used by both solvers.
///
/// A real shipped cube solver uses Kociemba's two-phase algorithm with
/// precomputed pruning tables (megabytes of pattern data). This scaffold
/// instead uses plain IDDFS with standard last-face move pruning. That is
/// correct but slow: fine for trivial/shallow scrambles and for unit tests,
/// and honest about its limits for hard scrambles (surfaces
/// `SolverError.depthCapExceeded` rather than silently failing).
///
/// Swap this engine for a pattern-DB-backed implementation to reach
/// production-grade solve times.
enum SearchEngine {
    /// Find a move sequence that transforms `start` into a state where
    /// `isGoal(state)` returns true.
    ///
    /// - Parameters:
    ///   - start: Starting cube state.
    ///   - maxDepth: Upper bound on the solution length (inclusive).
    ///   - isGoal: Goal predicate. The search returns `[]` if already met.
    ///   - allowedFaces: Restrict the move set (e.g. last-layer-only stages).
    ///   - stageLabel: Used in the thrown error if we exceed `maxDepth`.
    static func search(
        start: CubeState,
        maxDepth: Int,
        allowedFaces: [FaceKind] = FaceKind.allCases,
        stageLabel: String,
        isGoal: (CubeState) -> Bool
    ) throws -> [Move] {
        if isGoal(start) { return [] }
        var path: [Move] = []
        for depth in 1...maxDepth {
            var state = start
            if dfs(&state, depth: depth, path: &path, lastFace: nil,
                   allowedFaces: allowedFaces, isGoal: isGoal) {
                return path
            }
        }
        throw SolverError.depthCapExceeded(stage: stageLabel)
    }

    private static func dfs(
        _ state: inout CubeState,
        depth: Int,
        path: inout [Move],
        lastFace: FaceKind?,
        allowedFaces: [FaceKind],
        isGoal: (CubeState) -> Bool
    ) -> Bool {
        if depth == 0 { return isGoal(state) }
        for face in allowedFaces {
            if face == lastFace { continue }  // no two moves on the same face in a row
            if let last = lastFace, face.rawValue % 3 == last.rawValue % 3,
               face.rawValue > last.rawValue { continue }
            // ^ canonicalize axis pairs (U<->D, R<->L, F<->B): if we just
            //   moved the "low" face of a parallel pair, don't also move the
            //   "high" face — those two moves commute so we only count one
            //   ordering.
            for dir in [Move.Direction.cw, .ccw, .double] {
                let move = Move(face, dir)
                state.apply(move)
                path.append(move)
                if dfs(&state, depth: depth - 1, path: &path,
                       lastFace: face, allowedFaces: allowedFaces,
                       isGoal: isGoal) {
                    return true
                }
                path.removeLast()
                state.apply(move.inverse)
            }
        }
        return false
    }
}
