import Foundation

/// A quarter- or half-turn on one face, in WCA notation.
public struct Move: Codable, Hashable, CustomStringConvertible {
    public enum Direction: Int, Codable { case cw = 1, ccw = -1, double = 2 }

    public let face: FaceKind
    public let direction: Direction

    public init(_ face: FaceKind, _ direction: Direction) {
        self.face = face
        self.direction = direction
    }

    public var inverse: Move {
        switch direction {
        case .cw:     return Move(face, .ccw)
        case .ccw:    return Move(face, .cw)
        case .double: return Move(face, .double)
        }
    }

    public var description: String {
        switch direction {
        case .cw:     return face.letter
        case .ccw:    return "\(face.letter)'"
        case .double: return "\(face.letter)2"
        }
    }

    /// Parse a space-separated algorithm string such as `"R U R' U'"`.
    public static func parseSequence(_ s: String) -> [Move] {
        s.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" })
            .compactMap(Move.parseToken)
    }

    public static func parseToken(_ token: Substring) -> Move? {
        guard let first = token.first,
              let face = FaceKind.allCases.first(where: { $0.letter == String(first) })
        else { return nil }
        let rest = token.dropFirst()
        switch rest {
        case "":              return Move(face, .cw)
        case "'", "’":        return Move(face, .ccw)
        case "2":             return Move(face, .double)
        default:              return nil
        }
    }
}

public extension Array where Element == Move {
    var notation: String { map(\.description).joined(separator: " ") }

    /// Inverse algorithm: reverse order and invert each move.
    var inverse: [Move] { reversed().map(\.inverse) }
}
