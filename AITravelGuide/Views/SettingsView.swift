import SwiftUI

struct SettingsView: View {
    @State private var apiKeyInput: String = ""
    @State private var hasKey: Bool = APIKeyManager.shared.hasAPIKey
    @State private var showKey: Bool = false
    @State private var showSavedAlert: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    apiKeySection
                } header: {
                    Text("Claude API Key")
                } footer: {
                    Text("Your API key is stored securely in the iOS Keychain and never leaves your device except to authenticate with the Anthropic API. Get a key at console.anthropic.com.")
                }

                Section("AI Features") {
                    aiFeaturesStatus
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("AI Model", value: "Claude Sonnet 4.5")
                    LabeledContent("Map Data", value: "Apple MapKit")
                }
            }
            .navigationTitle("Settings")
            .alert("API Key Saved", isPresented: $showSavedAlert) {
                Button("OK") {}
            } message: {
                Text("Your Claude API key has been saved. AI-powered responses are now enabled.")
            }
        }
    }

    // MARK: - API Key Section

    @ViewBuilder
    private var apiKeySection: some View {
        if hasKey {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("API key configured")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Remove", role: .destructive) {
                    APIKeyManager.shared.claudeAPIKey = nil
                    hasKey = false
                    apiKeyInput = ""
                }
                .font(.subheadline)
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if showKey {
                        TextField("sk-ant-...", text: $apiKeyInput)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    } else {
                        SecureField("sk-ant-...", text: $apiKeyInput)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                            .textInputAutocapitalization(.never)
                    }
                    Button {
                        showKey.toggle()
                    } label: {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    APIKeyManager.shared.claudeAPIKey = trimmed
                    hasKey = true
                    showSavedAlert = true
                } label: {
                    Text("Save API Key")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    // MARK: - AI Features Status

    private var aiFeaturesStatus: some View {
        Group {
            featureRow("AI Chat Responses", enabled: hasKey)
            featureRow("Tour Stop Narration", enabled: hasKey)
            featureRow("POI Descriptions", enabled: hasKey)
            featureRow("Offline Template Responses", enabled: true)
            featureRow("MapKit POI Search", enabled: true)
            featureRow("Tour Route Generation", enabled: true)
        }
    }

    private func featureRow(_ name: String, enabled: Bool) -> some View {
        HStack {
            Text(name)
            Spacer()
            Image(systemName: enabled ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(enabled ? .green : .secondary)
        }
    }
}
