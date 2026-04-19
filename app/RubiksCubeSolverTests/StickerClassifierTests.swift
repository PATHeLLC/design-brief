import XCTest
@testable import RubiksCubeSolver

/// Tests `StickerClassifier.parseColors` against fixture Claude responses.
/// Does not hit the network.
final class StickerClassifierTests: XCTestCase {
    func testParsesValidToolUseBlock() throws {
        let json = """
        {
          "content": [
            {
              "type": "tool_use",
              "name": "record_face",
              "input": {
                "colors": ["W","W","W","W","W","W","W","W","W"]
              }
            }
          ]
        }
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(ClaudeClient.Response.self, from: json)
        let colors = try StickerClassifier.parseColors(from: response)
        XCTAssertEqual(colors, Array(repeating: StickerColor.white, count: 9))
    }

    func testRejectsMissingToolUse() {
        let json = """
        {
          "content": [{"type": "text", "text": "I cannot help with that"}]
        }
        """.data(using: .utf8)!
        let response = try! JSONDecoder().decode(ClaudeClient.Response.self, from: json)
        XCTAssertThrowsError(try StickerClassifier.parseColors(from: response))
    }

    func testRejectsWrongLengthGrid() {
        let json = """
        {
          "content": [
            {
              "type": "tool_use",
              "name": "record_face",
              "input": {"colors": ["W","W","W"]}
            }
          ]
        }
        """.data(using: .utf8)!
        let response = try! JSONDecoder().decode(ClaudeClient.Response.self, from: json)
        XCTAssertThrowsError(try StickerClassifier.parseColors(from: response))
    }

    func testRejectsUnknownColorToken() {
        let json = """
        {
          "content": [
            {
              "type": "tool_use",
              "name": "record_face",
              "input": {"colors": ["W","W","W","W","W","W","W","W","Z"]}
            }
          ]
        }
        """.data(using: .utf8)!
        let response = try! JSONDecoder().decode(ClaudeClient.Response.self, from: json)
        XCTAssertThrowsError(try StickerClassifier.parseColors(from: response))
    }
}
