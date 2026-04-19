import Foundation

public protocol Solver {
    /// Human-readable name shown in the method picker.
    var displayName: String { get }

    /// Solve the given cube, returning an ordered list of stages.
    func solve(_ cube: CubeState) throws -> [SolveStep]
}

public enum SolveMethod: String, Codable, CaseIterable, Identifiable {
    case beginner
    case kociemba

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .beginner: return "Teach me"
        case .kociemba: return "Solve fast"
        }
    }

    public var subtitle: String {
        switch self {
        case .beginner:
            return "Layer-by-layer with named stages — more moves, easier to learn."
        case .kociemba:
            return "Near-optimal solution in ~20 moves — fewer moves, less teaching."
        }
    }

    public func makeSolver() -> Solver {
        switch self {
        case .beginner: return BeginnerSolver()
        case .kociemba: return KociembaSolver()
        }
    }
}
