import XCTest
@testable import RubiksCubeSolver

final class CubeStateTests: XCTestCase {
    func testSolvedCubeIsSolved() {
        XCTAssertTrue(CubeState.solved.isSolved)
    }

    func testSingleMoveAndInverseReturnsSolved() {
        for face in FaceKind.allCases {
            for dir in [Move.Direction.cw, .ccw, .double] {
                var cube = CubeState.solved
                let move = Move(face, dir)
                cube.apply(move)
                XCTAssertFalse(cube.isSolved, "after \(move) cube should not be solved")
                cube.apply(move.inverse)
                XCTAssertTrue(cube.isSolved, "after \(move) then \(move.inverse) cube should be solved")
            }
        }
    }

    func testFourQuarterTurnsIsIdentity() {
        for face in FaceKind.allCases {
            var cube = CubeState.solved
            let move = Move(face, .cw)
            for _ in 0..<4 { cube.apply(move) }
            XCTAssertTrue(cube.isSolved, "four \(move) turns should be identity")
        }
    }

    func testScrambleAndInverseReturnsSolved() {
        let scramble = Move.parseSequence("R U R' U' R U R' U' F B L D'")
        var cube = CubeState.solved
        cube.apply(scramble)
        XCTAssertFalse(cube.isSolved)
        cube.apply(scramble.inverse)
        XCTAssertTrue(cube.isSolved, "scramble + inverse should restore solved")
    }

    func testCentersNeverMove() {
        let scramble = Move.parseSequence("R U R' F L B D U' F2 B2")
        var cube = CubeState.solved
        cube.apply(scramble)
        for face in FaceKind.allCases {
            XCTAssertEqual(cube[face].center, face.conventionalColor,
                           "\(face.letter) center drifted")
        }
    }

    func testDoubleMoveIsTwoQuarters() {
        var a = CubeState.solved
        a.apply(Move(.R, .double))
        var b = CubeState.solved
        b.apply(Move(.R, .cw))
        b.apply(Move(.R, .cw))
        XCTAssertEqual(a, b)
    }
}
