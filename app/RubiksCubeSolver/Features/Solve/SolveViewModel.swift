import Foundation
import SwiftUI

/// Orchestrates the guided solve: holds the step plan, tracks progress, asks
/// `PrescriptiveGuide` for the next user-relative sentence, and applies moves
/// to a running `CubeState` mirror.
@MainActor
final class SolveViewModel: ObservableObject {
    @Published var plan: [SolveStep] = []
    @Published var stepIndex: Int = 0
    @Published var moveIndexInStep: Int = 0
    @Published var narration: PrescriptiveGuide.Narration?
    @Published var isFetchingNarration: Bool = false
    @Published var errorMessage: String?
    @Published private(set) var runningState: CubeState

    private let startingCube: CubeState
    private let method: SolveMethod
    private let guide: PrescriptiveGuide
    let orientation: OrientationEstimator

    init(cube: CubeState, method: SolveMethod, guide: PrescriptiveGuide) {
        self.startingCube = cube
        self.runningState = cube
        self.method = method
        self.guide = guide
        self.orientation = OrientationEstimator(cube: cube)
    }

    var totalMoves: Int { plan.reduce(0) { $0 + $1.moves.count } }

    var currentStep: SolveStep? {
        guard stepIndex < plan.count else { return nil }
        return plan[stepIndex]
    }

    var currentMove: Move? {
        guard let step = currentStep, moveIndexInStep < step.moves.count else {
            return nil
        }
        return step.moves[moveIndexInStep]
    }

    var isComplete: Bool {
        stepIndex >= plan.count
    }

    /// Run the solver on a background thread (the IDDFS search can be slow).
    func computePlan() async {
        let solver = method.makeSolver()
        let cube = startingCube
        do {
            let steps = try await Task.detached(priority: .userInitiated) {
                try solver.solve(cube)
            }.value
            self.plan = steps
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    /// Ask Claude to phrase the current move in user-relative terms.
    func refreshNarration(usingFrontCamera: Bool) async {
        guard let move = currentMove, let step = currentStep else {
            narration = nil
            return
        }
        isFetchingNarration = true
        defer { isFetchingNarration = false }
        let orient = orientation.orientation(
            facingFace: .F,  // assume front-facing; real live app feeds observed center
            observedTopColor: runningState[.U].center,
            usingFrontCamera: usingFrontCamera
        )
        do {
            narration = try await guide.narrate(
                move: move, stage: step.stage, orientation: orient
            )
        } catch {
            narration = PrescriptiveGuide.Narration(
                sentence: PrescriptiveGuide.fallbackPhrase(for: move),
                rationale: nil
            )
        }
    }

    /// Mark the current move as done: apply it to the running state and
    /// advance the pointer.
    func confirmMoveDone() {
        guard let move = currentMove else { return }
        runningState.apply(move)
        moveIndexInStep += 1
        if let step = currentStep, moveIndexInStep >= step.moves.count {
            stepIndex += 1
            moveIndexInStep = 0
        }
        narration = nil  // force refresh on next screen tick
    }
}
