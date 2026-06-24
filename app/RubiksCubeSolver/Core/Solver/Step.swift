import Foundation

/// One prescriptive step in the guided solve.
///
/// A step groups a sequence of moves under a human-readable stage label. The
/// UI shows the stage label + `rationale` text and narrates each move
/// individually, translating it to user-relative phrasing via
/// `PrescriptiveGuide`.
public struct SolveStep: Codable, Hashable, Identifiable {
    public var id: UUID
    public let stage: String           // e.g. "White Cross", "OLL", "Phase 1"
    public let moves: [Move]
    public let rationale: String       // why this step matters pedagogically

    public init(id: UUID = UUID(), stage: String, moves: [Move], rationale: String) {
        self.id = id
        self.stage = stage
        self.moves = moves
        self.rationale = rationale
    }
}

/// Errors a solver can surface when the cube state is unsolvable or the
/// algorithm gives up under its depth cap.
public enum SolverError: Error, LocalizedError, Equatable {
    case depthCapExceeded(stage: String)
    case unsolvable(reason: String)

    public var errorDescription: String? {
        switch self {
        case .depthCapExceeded(let s):
            return "Couldn't find a solution for stage '\(s)' within the depth limit. Try re-scanning — a misread sticker can make the cube appear unsolvable."
        case .unsolvable(let r):
            return "Cube is unsolvable: \(r)"
        }
    }
}
