import AVFoundation
import CoreImage
import SwiftUI

public enum CameraPosition: String, Codable, CaseIterable {
    case back, front

    public var avPosition: AVCaptureDevice.Position {
        switch self {
        case .back:  return .back
        case .front: return .front
        }
    }

    public var displayName: String {
        switch self {
        case .back:  return "Rear camera"
        case .front: return "Front camera (mirror mode)"
        }
    }
}

/// Wraps an `AVCaptureSession` with runtime switching between front and rear
/// cameras, live preview, and a throttled frame stream for classification.
@MainActor
public final class CameraManager: NSObject, ObservableObject {
    @Published public private(set) var position: CameraPosition = .back
    @Published public private(set) var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published public private(set) var isRunning = false

    public let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "CameraManager.session")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoQueue = DispatchQueue(label: "CameraManager.video")

    private var frameSink: ((CVPixelBuffer) -> Void)?
    private var pendingCapture: CheckedContinuation<Data, Error>?

    public override init() {
        super.init()
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    /// Attach a throttled handler that receives one `CVPixelBuffer` at a time
    /// (see `FrameSampler`). Pass `nil` to disable.
    public func setFrameHandler(_ handler: ((CVPixelBuffer) -> Void)?) {
        self.frameSink = handler
    }

    public func requestAuthorization() async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            self.authorizationStatus = granted ? .authorized : .denied
        }
    }

    public func start() {
        guard authorizationStatus == .authorized else { return }
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.inputs.isEmpty {
                self.configureSession(for: .back)
            }
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async { self.isRunning = true }
            }
        }
    }

    public func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async { self.isRunning = false }
            }
        }
    }

    public func toggle() {
        switchTo(position == .back ? .front : .back)
    }

    public func switchTo(_ new: CameraPosition) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.configureSession(for: new)
        }
        self.position = new
    }

    /// Capture a still JPEG frame. Returns un-mirrored image data even when
    /// the front camera is in use, so the color classifier receives the cube
    /// with stickers in their true physical arrangement.
    public func captureStill() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CameraError.sessionUnavailable)
                    return
                }
                DispatchQueue.main.async {
                    self.pendingCapture = continuation
                    let settings = AVCapturePhotoSettings()
                    self.photoOutput.capturePhoto(with: settings, delegate: self)
                }
            }
        }
    }

    // MARK: - Session configuration

    private func configureSession(for position: CameraPosition) {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        // Reset inputs so we can switch cameras mid-session.
        for input in session.inputs { session.removeInput(input) }

        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: position.avPosition
        )
        guard let device = discovery.devices.first,
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return
        }
        session.addInput(input)

        if session.outputs.isEmpty {
            videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
            if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
        }

        // Un-mirror the frames we deliver to the classifier. The preview
        // layer handles its own mirroring for UX.
        for connection in videoOutput.connections {
            connection.videoOrientation = .portrait
            connection.isVideoMirrored = false
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    public nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        Task { @MainActor in
            self.frameSink?(pixelBuffer)
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    public nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task { @MainActor in
            guard let continuation = self.pendingCapture else { return }
            self.pendingCapture = nil
            if let error {
                continuation.resume(throwing: error); return
            }
            guard let data = photo.fileDataRepresentation() else {
                continuation.resume(throwing: CameraError.noImageData); return
            }
            continuation.resume(returning: data)
        }
    }
}

public enum CameraError: Error, LocalizedError {
    case sessionUnavailable
    case noImageData
    case notAuthorized

    public var errorDescription: String? {
        switch self {
        case .sessionUnavailable: return "Camera session is not available."
        case .noImageData:        return "Camera did not return image data."
        case .notAuthorized:      return "Camera access has not been granted."
        }
    }
}
