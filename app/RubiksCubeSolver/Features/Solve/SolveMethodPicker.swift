import SwiftUI

struct SolveMethodPicker: View {
    @State private var method: SolveMethod = .beginner
    let onPick: (SolveMethod) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("How should I guide you?")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            Text("You can change this later in Settings.")
                .font(.footnote).foregroundStyle(.secondary)

            ForEach(SolveMethod.allCases) { m in
                Button {
                    method = m
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: method == m
                              ? "largecircle.fill.circle"
                              : "circle")
                            .foregroundStyle(.tint)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(m.displayName).font(.headline)
                            Text(m.subtitle).font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.background, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(method == m ? Color.accentColor : .secondary.opacity(0.3),
                                lineWidth: method == m ? 2 : 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)

            Spacer()

            Button("Start solving") { onPick(method) }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.bottom)
        }
    }
}
