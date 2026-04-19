import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var apiKey: String = ""
    @State private var showKeyField = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "cube.transparent.fill")
                .resizable().scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(.tint)

            Text("Cube Solver")
                .font(.largeTitle.weight(.bold))

            Text("Scan your cube with the camera and follow the step-by-step guide. Works with both front and rear cameras.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 36)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task { await appState.requestCameraPermission() }
                } label: {
                    Label(cameraButtonLabel, systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(appState.cameraAuthorized)

                if showKeyField {
                    SecureField("sk-ant-api03-…", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button("Save key") { appState.saveAPIKey(apiKey) }
                        .buttonStyle(.bordered)
                        .disabled(apiKey.isEmpty)
                } else {
                    Button(appState.hasAPIKey
                           ? "API key saved • change"
                           : "Add Anthropic API key") {
                        showKeyField = true
                        apiKey = ""
                    }
                    .buttonStyle(.bordered)
                }

                Button("Start scanning") {
                    appState.beginScan()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(!appState.cameraAuthorized || !appState.hasAPIKey)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
    }

    private var cameraButtonLabel: String {
        appState.cameraAuthorized ? "Camera access granted" : "Grant camera access"
    }
}
