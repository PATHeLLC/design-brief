import Foundation

/// Converts an upcoming move into a prescriptive, user-relative instruction
/// ("rotate the face on your right clockwise — the blue sticker on top
/// should end up facing you") via Claude Haiku.
///
/// The call is kept small and fast so voice narration lands within a second
/// of the previous move completing.
public struct PrescriptiveGuide {
    public let client: ClaudeClient
    public let model: String

    public init(client: ClaudeClient, model: String = "claude-haiku-4-5-20251001") {
        self.client = client
        self.model = model
    }

    /// Describes the user's current cube orientation, passed to the model so
    /// its phrasing is correct relative to what the user sees.
    public struct Orientation: Codable, Hashable {
        public var topColor: StickerColor
        public var frontColor: StickerColor
        public var usingFrontCamera: Bool  // mirror mode — left/right are flipped

        public init(topColor: StickerColor, frontColor: StickerColor,
                    usingFrontCamera: Bool) {
            self.topColor = topColor
            self.frontColor = frontColor
            self.usingFrontCamera = usingFrontCamera
        }
    }

    public struct Narration: Codable, Hashable {
        public var sentence: String
        public var rationale: String?
    }

    /// Ask the model to phrase `move` in user-relative terms. Returns a
    /// short spoken sentence plus optional pedagogical rationale (shown
    /// under the step).
    public func narrate(move: Move, stage: String,
                        orientation: Orientation) async throws -> Narration {
        let tool = ClaudeClient.Tool(
            name: "speak_move",
            description: "Emit a single spoken instruction for the user's next move, phrased from their point of view.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "sentence": .object([
                        "type": .string("string"),
                        "description": .string("Short (max 20 words), spoken-aloud style instruction. Use 'the face on your right/left/top/bottom/front/back' rather than WCA letters."),
                    ]),
                    "rationale": .object([
                        "type": .string("string"),
                        "description": .string("Optional one-sentence reason this move advances the current stage. Skip for the Fast solve method."),
                    ]),
                ]),
                "required": .array([.string("sentence")]),
            ])
        )

        let system = """
        You are a Rubik's cube coach. The user is holding a cube with
        \(orientation.topColor.displayName) on top and
        \(orientation.frontColor.displayName) facing them. \
        \(orientation.usingFrontCamera ? "They are viewing themselves through the front camera, so 'left' and 'right' in the camera feed are flipped — always describe directions from the user's own perspective, not the camera's." : "They are using the rear camera.")

        Speak each instruction as a concise, prescriptive sentence that a
        beginner can follow without knowing WCA notation. Always give the
        cube-relative direction ('the face on your right', 'the top layer',
        etc.) plus the turn ('clockwise', 'counter-clockwise', or 'twice').

        You MUST respond by calling the speak_move tool. Do not produce free
        text.
        """

        let user = """
        Stage: \(stage)
        Next move in WCA notation: \(move.description)

        Translate this move into a single prescriptive sentence for the
        user. If the stage is pedagogical (not 'Fast solve'), add a short
        rationale.
        """

        let request = ClaudeClient.Request(
            model: model,
            maxTokens: 200,
            system: [ClaudeClient.SystemBlock(
                text: system,
                cacheControl: ClaudeClient.CacheControl()
            )],
            messages: [
                ClaudeClient.Message(role: "user", content: [.text(user)]),
            ],
            tools: [tool],
            toolChoice: ClaudeClient.ToolChoice(type: "tool", name: "speak_move"),
            temperature: 0.2
        )

        let response = try await client.send(request)
        guard let toolUse = response.content.first(where: { $0.type == "tool_use" }),
              let input = toolUse.input,
              let sentence = input["sentence"]?.stringValue
        else {
            // Fallback phrasing if the model misbehaves — keeps the app moving.
            return Narration(sentence: Self.fallbackPhrase(for: move),
                             rationale: nil)
        }
        return Narration(
            sentence: sentence,
            rationale: input["rationale"]?.stringValue
        )
    }

    /// Deterministic fallback phrasing for offline / error cases. Not as
    /// smooth as the model, but always correct.
    static func fallbackPhrase(for move: Move) -> String {
        let faceWord: String = {
            switch move.face {
            case .U: return "top"
            case .D: return "bottom"
            case .L: return "left"
            case .R: return "right"
            case .F: return "front"
            case .B: return "back"
            }
        }()
        let turnWord: String = {
            switch move.direction {
            case .cw:     return "clockwise"
            case .ccw:    return "counter-clockwise"
            case .double: return "180 degrees"
            }
        }()
        return "Rotate the \(faceWord) face \(turnWord)."
    }
}
