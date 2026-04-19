import XCTest
@testable import RubiksCubeSolver

final class MoveTests: XCTestCase {
    func testParseBasicTokens() {
        XCTAssertEqual(Move.parseToken("R"), Move(.R, .cw))
        XCTAssertEqual(Move.parseToken("R'"), Move(.R, .ccw))
        XCTAssertEqual(Move.parseToken("R2"), Move(.R, .double))
        XCTAssertEqual(Move.parseToken("U’"), Move(.U, .ccw))  // curly apostrophe
    }

    func testRoundTripNotation() {
        let seq = "R U R' U' F2 B' L D"
        let parsed = Move.parseSequence(seq)
        XCTAssertEqual(parsed.notation, seq)
    }

    func testInverseReverses() {
        let seq = Move.parseSequence("R U F' B2")
        XCTAssertEqual(seq.inverse.notation, "B2 F U' R'")
    }
}
