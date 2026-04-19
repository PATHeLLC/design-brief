import SwiftUI

/// Single-face capture screen: live preview, lock-on overlay, manual shutter,
/// front/rear toggle.
struct FaceCaptureView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var scan: ScanViewModel
    @State private var isShooting = false

    var face: FaceKind

    var body: some View {
        ZStack {
            CameraPreview(camera: appState.camera)
                .ignoresSafeArea()

            // Guidance overlay
            VStack {
                HStack {
                    CameraToggle(camera: appState.camera)
                    Spacer()
                    Text("Face \(face.letter) — \(faceInstruction(for: face))")
                        .font(.callout.weight(.medium))
                        .padding(.vertical, 8).padding(.horizontal, 14)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .padding()
                Spacer()
                // 3x3 frame target
                FaceReticle()
                    .frame(width: 280, height: 280)
                Spacer()
                captureControls
            }
        }
        .alert("Couldn't classify face", isPresented: Binding(
            get: { scan.errorMessage != nil },
            set: { if !$0 { scan.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { scan.errorMessage = nil }
        } message: {
            Text(scan.errorMessage ?? "")
        }
    }

    private var captureControls: some View {
        HStack(spacing: 32) {
            Button("Skip") { scan.advance() }
                .foregroundStyle(.white)
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())

            Button {
                Task { await capture() }
            } label: {
                ZStack {
                    Circle().fill(.white).frame(width: 72, height: 72)
                    Circle().stroke(.white.opacity(0.6), lineWidth: 4).frame(width: 82, height: 82)
                    if scan.isClassifying {
                        ProgressView().tint(.black)
                    }
                }
            }
            .disabled(isShooting || scan.isClassifying)

            Spacer().frame(width: 64)
        }
        .padding(.bottom, 40)
    }

    private func capture() async {
        isShooting = true
        defer { isShooting = false }
        do {
            let data = try await appState.camera.captureStill()
            await scan.ingest(jpeg: data)
        } catch {
            scan.errorMessage = error.localizedDescription
        }
    }

    private func faceInstruction(for face: FaceKind) -> String {
        switch face {
        case .U: return "point the top (white) face at the camera"
        case .R: return "point the right (red) face at the camera"
        case .F: return "point the front (green) face at the camera"
        case .D: return "point the bottom (yellow) face at the camera"
        case .L: return "point the left (orange) face at the camera"
        case .B: return "point the back (blue) face at the camera"
        }
    }
}

/// Decorative 3x3 alignment grid drawn on top of the live camera feed.
struct FaceReticle: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            Path { p in
                p.addRect(CGRect(origin: .zero, size: geo.size))
                for i in 1...2 {
                    let x = w * CGFloat(i) / 3
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: h))
                    let y = h * CGFloat(i) / 3
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: w, y: y))
                }
            }
            .stroke(.white.opacity(0.8), lineWidth: 2)
        }
    }
}
