import SwiftUI

/// Lightweight AR-style overlay: draws a direction arrow and face label on
/// top of the camera feed, plus a progress bar.
struct StepOverlayView: View {
    let step: SolveStep
    let move: Move
    let stepsCompleted: Int
    let totalMoves: Int
    let sentence: String?
    let rationale: String?
    let usingFrontCamera: Bool

    var body: some View {
        VStack {
            header
            Spacer()
            arrow
            Spacer()
            narrationCard
        }
        .padding()
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(step.stage.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.8))
            ProgressView(value: Double(stepsCompleted), total: Double(max(totalMoves, 1)))
                .tint(.white)
                .frame(maxWidth: 280)
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var arrow: some View {
        VStack(spacing: 8) {
            Image(systemName: arrowSymbol(for: move))
                .font(.system(size: 120, weight: .bold))
                .foregroundStyle(.white)
                .shadow(radius: 8)
            Text(move.description)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
        }
    }

    private var narrationCard: some View {
        VStack(spacing: 8) {
            if let sentence {
                Text(sentence)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            } else {
                Text("Preparing instruction…")
                    .foregroundStyle(.white.opacity(0.7))
            }
            if let rationale {
                Text(rationale)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func arrowSymbol(for move: Move) -> String {
        // Mirror mode flips left/right from the user's perspective — so if
        // we're using the front camera, flip horizontal arrows.
        let flipHoriz = usingFrontCamera
        switch move.direction {
        case .cw:
            switch move.face {
            case .U: return "arrow.clockwise.circle.fill"
            case .D: return "arrow.counterclockwise.circle.fill"
            case .R: return flipHoriz ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
            case .L: return flipHoriz ? "arrow.down.circle.fill" : "arrow.up.circle.fill"
            case .F: return "arrow.clockwise.circle.fill"
            case .B: return "arrow.counterclockwise.circle.fill"
            }
        case .ccw:
            switch move.face {
            case .U: return "arrow.counterclockwise.circle.fill"
            case .D: return "arrow.clockwise.circle.fill"
            case .R: return flipHoriz ? "arrow.down.circle.fill" : "arrow.up.circle.fill"
            case .L: return flipHoriz ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
            case .F: return "arrow.counterclockwise.circle.fill"
            case .B: return "arrow.clockwise.circle.fill"
            }
        case .double:
            return "arrow.2.circlepath.circle.fill"
        }
    }
}
