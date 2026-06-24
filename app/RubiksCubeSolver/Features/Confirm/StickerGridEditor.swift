import SwiftUI

/// Lets the user inspect all six scanned faces and tap any sticker to change
/// its color. Blocks the "Continue" button if validation fails (e.g., wrong
/// color counts or duplicate centers).
struct StickerGridEditor: View {
    @State var cube: CubeState
    @State private var selectedFace: FaceKind = .U
    @State private var pickerColor: StickerColor?
    @State private var message: String?

    let validationMessage: String?
    let onContinue: (CubeState) -> Void
    let onRescanFace: (FaceKind) -> Void

    init(initialCube: CubeState,
         validationMessage: String?,
         onContinue: @escaping (CubeState) -> Void,
         onRescanFace: @escaping (FaceKind) -> Void) {
        self._cube = State(initialValue: initialCube)
        self.validationMessage = validationMessage
        self.onContinue = onContinue
        self.onRescanFace = onRescanFace
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Check the scan")
                .font(.title2.weight(.bold))
            Text("Tap any sticker to correct a misread color. The center sticker of each face should match that face's known color.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Face selector
            Picker("Face", selection: $selectedFace) {
                ForEach(FaceKind.allCases, id: \.self) { kind in
                    Text(kind.letter).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // 3x3 editable grid
            VStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { col in
                            stickerButton(row: row, col: col)
                        }
                    }
                }
            }
            .padding(16)
            .background(.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))

            // Color palette for the picker menu
            HStack(spacing: 10) {
                ForEach(StickerColor.allCases, id: \.self) { color in
                    Circle()
                        .fill(swatchColor(color))
                        .frame(width: 30, height: 30)
                        .overlay(Circle().stroke(.black.opacity(0.15), lineWidth: 1))
                        .onTapGesture { pickerColor = color; applyPending() }
                        .overlay(alignment: .bottom) {
                            if pickerColor == color {
                                Circle().fill(.black).frame(width: 6, height: 6).offset(y: 8)
                            }
                        }
                }
            }

            Button("Re-scan this face") { onRescanFace(selectedFace) }
                .font(.subheadline)
                .buttonStyle(.bordered)

            if let message = validationMessage ?? message {
                Text(message)
                    .font(.footnote).foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            Button {
                switch CubeValidator.validate(cube) {
                case .success:   onContinue(cube)
                case .failure(let err): message = err.localizedDescription
                }
            } label: {
                Label("Continue to solve", systemImage: "arrow.right.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    @State private var pendingIndex: Int?

    private func stickerButton(row: Int, col: Int) -> some View {
        let color = cube[selectedFace][row, col]
        return Button {
            pendingIndex = row * 3 + col
            applyPending()
        } label: {
            RoundedRectangle(cornerRadius: 8)
                .fill(swatchColor(color))
                .frame(width: 78, height: 78)
                .overlay {
                    if row == 1 && col == 1 {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(.black.opacity(0.15), lineWidth: 1))
        }
        .disabled(row == 1 && col == 1)  // centers are fixed; don't let the user break them
    }

    private func applyPending() {
        guard let index = pendingIndex, let color = pickerColor else { return }
        var face = cube[selectedFace]
        face.stickers[index] = color
        cube[selectedFace] = face
        pendingIndex = nil
    }

    private func swatchColor(_ c: StickerColor) -> Color {
        switch c {
        case .white:  return Color(white: 0.95)
        case .yellow: return .yellow
        case .red:    return .red
        case .orange: return .orange
        case .blue:   return .blue
        case .green:  return .green
        }
    }
}
