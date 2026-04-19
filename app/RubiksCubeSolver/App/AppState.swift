import AVFoundation
import Foundation
import SwiftUI

/// Top-level UI state. Owns the camera session, the Claude client, and the
/// route through onboarding → scan → method-pick → guide.
@MainActor
final class AppState: ObservableObject {
    enum Route: Equatable {
        case onboarding
        case scan
        case pickMethod(cube: CubeState)
        case guide(cube: CubeState, method: SolveMethod)
    }

    @Published var route: Route = .onboarding
    @Published var cameraAuthorized: Bool
    @Published var hasAPIKey: Bool

    let camera: CameraManager
    let keychain: KeychainStore
    let classifier: StickerClassifier
    let prescriptiveGuide: PrescriptiveGuide

    init() {
        let keychain = KeychainStore()
        let client = ClaudeClient(config: .init(
            apiKeyProvider: { keychain.load() }
        ))
        self.keychain = keychain
        self.classifier = StickerClassifier(client: client)
        self.prescriptiveGuide = PrescriptiveGuide(client: client)
        self.camera = CameraManager()
        self.hasAPIKey = keychain.load() != nil
        self.cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    func requestCameraPermission() async {
        await camera.requestAuthorization()
        cameraAuthorized = camera.authorizationStatus == .authorized
    }

    func saveAPIKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if keychain.save(trimmed) { hasAPIKey = true }
    }

    func removeAPIKey() {
        keychain.delete()
        hasAPIKey = false
    }

    func beginScan() {
        route = .scan
    }

    func didConfirmScan(cube: CubeState) {
        route = .pickMethod(cube: cube)
    }

    func didPickMethod(_ method: SolveMethod, cube: CubeState) {
        route = .guide(cube: cube, method: method)
    }

    func restart() {
        route = .onboarding
    }
}
