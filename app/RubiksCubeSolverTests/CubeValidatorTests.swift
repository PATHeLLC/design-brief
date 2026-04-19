import XCTest
@testable import RubiksCubeSolver

final class CubeValidatorTests: XCTestCase {
    func testSolvedCubePasses() {
        let res = CubeValidator.validate(.solved)
        if case .failure(let e) = res { XCTFail("unexpected failure: \(e)") }
    }

    func testScrambledCubePasses() {
        var cube = CubeState.solved
        cube.apply(Move.parseSequence("R U R' U' F B2 L D'"))
        if case .failure(let e) = CubeValidator.validate(cube) {
            XCTFail("scrambled but legal cube failed: \(e)")
        }
    }

    func testWrongColorCountFails() {
        var cube = CubeState.solved
        cube[.U].stickers[0] = .red  // now 10 red / 8 white
        let res = CubeValidator.validate(cube)
        guard case .failure(let err) = res else { return XCTFail("expected failure") }
        switch err {
        case .colorCountMismatch: break
        default: XCTFail("expected colorCountMismatch, got \(err)")
        }
    }

    func testDuplicateCenterFails() {
        var cube = CubeState.solved
        cube[.F].stickers[4] = .white  // two white centers
        // Also fix counts by swapping a sticker somewhere else, otherwise
        // we'd trip the color-count check first.
        cube[.U].stickers[0] = .green
        let res = CubeValidator.validate(cube)
        guard case .failure(let err) = res else { return XCTFail("expected failure") }
        switch err {
        case .duplicateCenter, .missingCenterColor, .colorCountMismatch: break
        default: XCTFail("unexpected error: \(err)")
        }
    }
}
