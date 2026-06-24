import Foundation

/// The six sticker colors of a standard Rubik's cube.
///
/// Raw value matches the single-letter color code used in Claude prompts and
/// in `StickerClassifier`'s JSON responses (`W Y R O B G`).
public enum StickerColor: String, Codable, CaseIterable, Hashable {
    case white  = "W"
    case yellow = "Y"
    case red    = "R"
    case orange = "O"
    case blue   = "B"
    case green  = "G"

    public var displayName: String {
        switch self {
        case .white:  return "white"
        case .yellow: return "yellow"
        case .red:    return "red"
        case .orange: return "orange"
        case .blue:   return "blue"
        case .green:  return "green"
        }
    }

    public var opposite: StickerColor {
        switch self {
        case .white:  return .yellow
        case .yellow: return .white
        case .red:    return .orange
        case .orange: return .red
        case .blue:   return .green
        case .green:  return .blue
        }
    }
}

/// The six faces of a cube, in WCA notation.
public enum FaceKind: Int, Codable, CaseIterable, Hashable {
    case U = 0  // Up (white by convention)
    case R = 1  // Right (red)
    case F = 2  // Front (green)
    case D = 3  // Down (yellow)
    case L = 4  // Left (orange)
    case B = 5  // Back (blue)

    /// Conventional center color for a Western-scheme cube. Used only as a
    /// starting hint in `OrientationEstimator`; the cube state itself does
    /// not assume this scheme.
    public var conventionalColor: StickerColor {
        switch self {
        case .U: return .white
        case .R: return .red
        case .F: return .green
        case .D: return .yellow
        case .L: return .orange
        case .B: return .blue
        }
    }

    public var letter: String {
        String(describing: self)
    }
}

/// A single cube face: nine stickers in row-major order, where index 0 is the
/// top-left as viewed with the face toward the camera, and index 4 is always
/// the fixed center.
public struct Face: Codable, Hashable {
    public var stickers: [StickerColor]  // count == 9

    public init(stickers: [StickerColor]) {
        precondition(stickers.count == 9, "A face has exactly 9 stickers")
        self.stickers = stickers
    }

    public init(uniform color: StickerColor) {
        self.stickers = Array(repeating: color, count: 9)
    }

    public var center: StickerColor { stickers[4] }

    public subscript(row: Int, col: Int) -> StickerColor {
        get { stickers[row * 3 + col] }
        set { stickers[row * 3 + col] = newValue }
    }

    /// Rotates this face's stickers 90° clockwise in-place. Does not mutate
    /// neighboring face edges — callers handle that.
    public mutating func rotateClockwise() {
        let s = stickers
        stickers = [
            s[6], s[3], s[0],
            s[7], s[4], s[1],
            s[8], s[5], s[2],
        ]
    }

    public mutating func rotateCounterClockwise() {
        rotateClockwise(); rotateClockwise(); rotateClockwise()
    }

    public mutating func rotate180() {
        rotateClockwise(); rotateClockwise()
    }
}
