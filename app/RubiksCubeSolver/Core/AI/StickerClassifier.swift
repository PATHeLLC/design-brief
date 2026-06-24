import Foundation

/// Classifies the 9 stickers of a single cube face using Claude's vision API.
///
/// The request forces structured output via a `record_face` tool whose schema
/// requires a 9-element array of color enums in row-major order. This keeps
/// parsing deterministic — we never need to scrape free-form text.
public struct StickerClassifier {
    public let client: ClaudeClient
    public let model: String

    public init(client: ClaudeClient, model: String = "claude-sonnet-4-6") {
        self.client = client
        self.model = model
    }

    public enum ClassifierError: Error, LocalizedError {
        case noToolUseReturned
        case malformedGrid(String)

        public var errorDescription: String? {
            switch self {
            case .noToolUseReturned:
                return "Claude did not call the record_face tool."
            case .malformedGrid(let s):
                return "record_face returned a malformed grid: \(s)"
            }
        }
    }

    /// Send a JPEG image of a single face and return the 9 classified stickers
    /// in row-major order (top-left → bottom-right as viewed facing the
    /// camera).
    public func classify(faceJPEG: Data, faceLabel: FaceKind) async throws -> [StickerColor] {
        let base64 = faceJPEG.base64EncodedString()
        let tool = ClaudeClient.Tool(
            name: "record_face",
            description: "Record the 9 sticker colors on a Rubik's cube face, row-major from top-left.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "colors": .object([
                        "type": .string("array"),
                        "minItems": .number(9),
                        "maxItems": .number(9),
                        "items": .object([
                            "type": .string("string"),
                            "enum": .array([
                                .string("W"), .string("Y"), .string("R"),
                                .string("O"), .string("B"), .string("G"),
                            ]),
                            "description": .string("Single-letter color: W=white Y=yellow R=red O=orange B=blue G=green."),
                        ]),
                    ]),
                ]),
                "required": .array([.string("colors")]),
            ])
        )

        let system = """
        You are a computer-vision assistant for a Rubik's cube solver. The
        user will show you a photo of one face of a 3x3 Rubik's cube. Look
        carefully at each of the nine stickers and decide which of the six
        cube colors it is: white, yellow, red, orange, blue, or green.
        Return the nine colors in row-major order — top row left to right,
        then middle row, then bottom row, as viewed in the photo — by
        calling the record_face tool. Do not respond with text.

        Color disambiguation tips:
        - Red is darker and more saturated than orange; orange skews yellow.
        - White often looks slightly blue-grey; yellow has a warm tint.
        - Blue is deeper than the sky; green is a bright grass green.
        """

        let request = ClaudeClient.Request(
            model: model,
            maxTokens: 256,
            system: [ClaudeClient.SystemBlock(
                text: system,
                cacheControl: ClaudeClient.CacheControl()
            )],
            messages: [
                ClaudeClient.Message(role: "user", content: [
                    .image(mediaType: "image/jpeg", base64: base64),
                    .text("This is the \(faceLabel.letter) face. Return the nine colors via record_face."),
                ]),
            ],
            tools: [tool],
            toolChoice: ClaudeClient.ToolChoice(type: "tool", name: "record_face"),
            temperature: 0.0
        )

        let response = try await client.send(request)
        return try Self.parseColors(from: response)
    }

    /// Extract the `colors` array from a tool_use block, validate it, and
    /// map raw letters to `StickerColor`.
    static func parseColors(from response: ClaudeClient.Response) throws -> [StickerColor] {
        guard let toolUse = response.content.first(where: { $0.type == "tool_use" }),
              let input = toolUse.input,
              let colorsRaw = input["colors"]?.arrayValue
        else {
            throw ClassifierError.noToolUseReturned
        }
        guard colorsRaw.count == 9 else {
            throw ClassifierError.malformedGrid("expected 9 entries, got \(colorsRaw.count)")
        }
        var out: [StickerColor] = []
        out.reserveCapacity(9)
        for v in colorsRaw {
            guard let s = v.stringValue, let color = StickerColor(rawValue: s) else {
                throw ClassifierError.malformedGrid("invalid color token: \(v)")
            }
            out.append(color)
        }
        return out
    }
}
