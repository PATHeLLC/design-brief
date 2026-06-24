import XCTest
@testable import RubiksCubeSolver

/// Solver correctness tests, scoped to shallow scrambles. The IDDFS search
/// is intentionally simple (no pattern DBs) so deeper scrambles would time
/// out — that's by design for this scaffold, see `SearchEngine.swift`.
final class SolverTests: XCTestCase {
    func testBeginnerSolvesSolved() throws {
        let steps = try BeginnerSolver().solve(.solved)
        XCTAssertEqual(steps.flatMap(\.moves).count, 0)
    }

    func testKociembaSolvesSolved() throws {
        let steps = try KociembaSolver().solve(.solved)
        XCTAssertEqual(steps.flatMap(\.moves).count, 0)
    }

    func testKociembaSolvesSingleMove() throws {
        for face in FaceKind.allCases {
            var cube = CubeState.solved
            let scramble = Move(face, .cw)
            cube.apply(scramble)
            let plan = try KociembaSolver().solve(cube)
            let all = plan.flatMap(\.moves)
            cube.apply(all)
            XCTAssertTrue(cube.isSolved, "failed to solve single \(scramble)")
        }
    }

    func testKociembaSolvesTwoMoveScramble() throws {
        var cube = CubeState.solved
        let scramble = Move.parseSequence("R U")
        cube.apply(scramble)
        let plan = try KociembaSolver().solve(cube)
        cube.apply(plan.flatMap(\.moves))
        XCTAssertTrue(cube.isSolved)
    }

    func testBeginnerSolvesTrivialCrossOnlyScramble() throws {
        // Scramble that only affects the top layer so the F2L / OLL / PLL
        // stages have little work to do.
        var cube = CubeState.solved
        cube.apply(Move.parseSequence("U"))
        let plan = try BeginnerSolver().solve(cube)
        cube.apply(plan.flatMap(\.moves))
        XCTAssertTrue(cube.isSolved)
    }
}
