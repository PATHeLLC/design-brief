import SwiftUI

struct CameraToggle: View {
    @ObservedObject var camera: CameraManager

    var body: some View {
        Button {
            camera.toggle()
        } label: {
            Label(camera.position.displayName,
                  systemImage: "arrow.triangle.2.circlepath.camera")
                .font(.subheadline.weight(.medium))
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .foregroundStyle(.white)
    }
}
