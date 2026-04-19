import SwiftUI

struct GuideView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var solve: SolveViewModel
    @StateObject private var narrator = VoiceNarrator()
    @State private var isComputing = true

    init(cube: CubeState, method: SolveMethod, guide: PrescriptiveGuide) {
        _solve = StateObject(wrappedValue: SolveViewModel(
            cube: cube, method: method, guide: guide
        ))
    }

    var body: some View {
        ZStack {
            CameraPreview(camera: appState.camera).ignoresSafeArea()

            if isComputing {
                computingOverlay
            } else if solve.isComplete {
                doneOverlay
            } else if let step = solve.currentStep, let move = solve.currentMove {
                StepOverlayView(
                    step: step,
                    move: move,
                    stepsCompleted: movesBeforeCurrent,
                    totalMoves: solve.totalMoves,
                    sentence: solve.narration?.sentence,
                    rationale: solve.narration?.rationale,
                    usingFrontCamera: appState.camera.position == .front
                )
                VStack { Spacer(); controls }
                    .padding(.bottom, 16)
            }

            VStack {
                HStack {
                    CameraToggle(camera: appState.camera)
                    Spacer()
                    Button {
                        narrator.enabled.toggle()
                    } label: {
                        Image(systemName: narrator.enabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .foregroundStyle(.white)
                }
                .padding()
                Spacer()
            }
        }
        .task { await runSolve() }
        .onChange(of: solve.stepIndex) { _, _ in Task { await refreshForCurrent() } }
        .onChange(of: solve.moveIndexInStep) { _, _ in Task { await refreshForCurrent() } }
        .onAppear { appState.camera.start() }
        .onDisappear {
            narrator.stop()
            appState.camera.stop()
        }
        .alert("Solver error", isPresented: Binding(
            get: { solve.errorMessage != nil },
            set: { if !$0 { solve.errorMessage = nil } }
        )) {
            Button("Back") { appState.restart() }
        } message: {
            Text(solve.errorMessage ?? "")
        }
    }

    private var computingOverlay: some View {
        VStack(spacing: 16) {
            ProgressView().tint(.white).scaleEffect(1.4)
            Text("Computing your solve…")
                .foregroundStyle(.white)
                .font(.headline)
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var doneOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80)).foregroundStyle(.green)
            Text("Cube solved!")
                .font(.title.weight(.bold)).foregroundStyle(.white)
            Button("Scan another cube") { appState.restart() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Button {
                Task { await refreshForCurrent() }
            } label: {
                Label("Repeat", systemImage: "arrow.counterclockwise")
                    .padding(.vertical, 10).padding(.horizontal, 14)
                    .background(.ultraThinMaterial, in: Capsule())
            }.foregroundStyle(.white)

            Button {
                solve.confirmMoveDone()
            } label: {
                Label("I did it", systemImage: "checkmark")
                    .font(.headline)
                    .frame(minWidth: 160)
                    .padding(.vertical, 14)
                    .background(.tint, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
    }

    private var movesBeforeCurrent: Int {
        var n = solve.moveIndexInStep
        for i in 0..<solve.stepIndex { n += solve.plan[i].moves.count }
        return n
    }

    private func runSolve() async {
        isComputing = true
        await solve.computePlan()
        isComputing = false
        await refreshForCurrent()
    }

    private func refreshForCurrent() async {
        await solve.refreshNarration(usingFrontCamera: appState.camera.position == .front)
        if let sentence = solve.narration?.sentence {
            narrator.speak(sentence)
        }
    }
}
