import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var apiKeyDraft: String = ""
    @State private var showKeySaved = false

    var body: some View {
        Form {
            Section("Anthropic API key") {
                SecureField("sk-ant-api03-…", text: $apiKeyDraft)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                HStack {
                    Button("Save") {
                        appState.saveAPIKey(apiKeyDraft)
                        showKeySaved = true
                    }
                    .disabled(apiKeyDraft.isEmpty)
                    Spacer()
                    if appState.hasAPIKey {
                        Button("Remove", role: .destructive) {
                            appState.removeAPIKey()
                            apiKeyDraft = ""
                        }
                    }
                }
                Text("Your key is stored in the iOS Keychain and only sent to api.anthropic.com.")
                    .font(.footnote).foregroundStyle(.secondary)
            }

            Section("About") {
                LabeledContent("Version", value: "0.1.0")
                Link("Anthropic console",
                     destination: URL(string: "https://console.anthropic.com/")!)
            }
        }
        .navigationTitle("Settings")
        .alert("Key saved", isPresented: $showKeySaved) {
            Button("OK") {}
        }
    }
}
