import Foundation

/// "Fast" solver — produces one compact move sequence.
///
/// Note: this is a scaffold. A real Kociemba two-phase solver relies on
/// pattern databases of corner and edge coordinates to prune search. Here we
/// run plain IDDFS via `SearchEngine`, capped at 22 moves — near God's
/// number for HTM (half-turn metric). In practice this finds solutions fast
/// for scrambles ≤6 moves and times out on harder ones. A future version
/// should swap in a pattern-DB-backed implementation behind the same
/// `Solver` protocol.
public struct KociembaSolver: Solver {
    public let displayName = "Fast"
    public init() {}

    public func solve(_ cube: CubeState) throws -> [SolveStep] {
        if cube.isSolved { return [] }
        let moves = try SearchEngine.search(
            start: cube,
            maxDepth: 22,
            stageLabel: "Fast solve"
        ) { $0.isSolved }
        return [SolveStep(
            stage: "Fast solve",
            moves: moves,
            rationale: "Direct search for a compact move sequence. No pedagogical stages — the app will narrate each move one at a time."
        )]
    }
}
