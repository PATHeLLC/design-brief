import SwiftUI

struct ScanFlowView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var scan: ScanViewModel

    init(classifier: StickerClassifier) {
        _scan = StateObject(wrappedValue: ScanViewModel(classifier: classifier))
    }

    var body: some View {
        Group {
            if let face = scan.currentFace {
                FaceCaptureView(scan: scan, face: face)
            } else if scan.isComplete, let cube = scan.buildCube() {
                // Validate and hand off to the confirmation step.
                confirmationView(cube: cube)
            } else {
                VStack(spacing: 16) {
                    Text("Some faces are missing or unreadable.")
                    Button("Start over") { reset() }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .onAppear { appState.camera.start() }
        .onDisappear { appState.camera.stop() }
    }

    private func confirmationView(cube: CubeState) -> some View {
        let validation = CubeValidator.validate(cube)
        return StickerGridEditor(
            initialCube: cube,
            validationMessage: (try? validation.get()) == nil
                ? validation.failureMessage : nil,
            onContinue: { finalCube in
                appState.didConfirmScan(cube: finalCube)
            },
            onRescanFace: { face in
                scan.overwrite(face: face, colors: [])
                scan.capturedFaces.removeValue(forKey: face)
                // Jump back to the earliest missing face.
                scan.currentIndex = ScanViewModel.captureOrder.firstIndex(of: face) ?? 0
            }
        )
    }

    private func reset() {
        scan.currentIndex = 0
        scan.capturedFaces.removeAll()
    }
}

private extension Result where Failure == CubeValidationError {
    var failureMessage: String? {
        switch self {
        case .success: return nil
        case .failure(let e): return e.localizedDescription
        }
    }
}
