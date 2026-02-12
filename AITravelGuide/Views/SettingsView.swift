import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var tourStorageService: TourStorageService
    @EnvironmentObject var speechService: SpeechService

    @State private var apiKeyInput: String = ""
    @State private var hasKey: Bool = APIKeyManager.shared.hasAPIKey
    @State private var showKey: Bool = false
    @State private var showSavedAlert: Bool = false
    @State private var showKeyFormatError: Bool = false

    @AppStorage("voiceEnabled") private var voiceEnabled = true
    @AppStorage("speechRateIndex") private var speechRateIndex = 1 // 0=slow, 1=normal, 2=fast

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

                Section("Voice Guide") {
                    Toggle("Voice Narration", isOn: $voiceEnabled)
                        .onChange(of: voiceEnabled) { _, newValue in
                            if !newValue { speechService.stop() }
                        }

                    if voiceEnabled {
                        Picker("Speech Speed", selection: $speechRateIndex) {
                            Text("Slow").tag(0)
                            Text("Normal").tag(1)
                            Text("Fast").tag(2)
                        }
                        .pickerStyle(.segmented)

                        Button {
                            if speechService.isSpeaking {
                                speechService.stop()
                            } else {
                                speechService.speak("Hello! I'm your AI travel guide. Let me show you around.")
                            }
                        } label: {
                            Label(
                                speechService.isSpeaking ? "Stop Preview" : "Preview Voice",
                                systemImage: speechService.isSpeaking ? "stop.circle.fill" : "play.circle"
                            )
                        }
                        .tint(speechService.isSpeaking ? .red : .accentColor)
                    }
                }

                Section("AI Features") {
                    aiFeaturesStatus
                }

                if !tourStorageService.savedTours.isEmpty {
                    Section("Saved Tours (\(tourStorageService.savedTours.count))") {
                        ForEach(tourStorageService.savedTours) { tour in
                            HStack {
                                Image(systemName: tour.category.systemImage)
                                    .foregroundStyle(.accent)
                                    .frame(width: 24)
                                VStack(alignment: .leading) {
                                    Text(tour.name)
                                        .font(.subheadline)
                                    Text("\(tour.locationName) - \(tour.formattedDistance)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if let rating = tour.rating {
                                    HStack(spacing: 1) {
                                        ForEach(1...5, id: \.self) { star in
                                            Image(systemName: star <= rating ? "star.fill" : "star")
                                                .font(.caption2)
                                                .foregroundStyle(.orange)
                                        }
                                    }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                tourStorageService.deleteTour(tourStorageService.savedTours[index])
                            }
                        }
                    }
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
            .alert("Invalid API Key", isPresented: $showKeyFormatError) {
                Button("OK") {}
            } message: {
                Text("Claude API keys start with \"sk-ant-\". Please check your key and try again.")
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
                    guard trimmed.hasPrefix("sk-ant-") else {
                        showKeyFormatError = true
                        return
                    }
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
            featureRow("AI Tour Generation", enabled: hasKey)
            featureRow("Tour Stop Narration", enabled: hasKey)
            featureRow("Voice Guide", enabled: voiceEnabled)
            featureRow("Walking Directions", enabled: true)
            featureRow("Offline Template Responses", enabled: true)
            featureRow("MapKit POI Search", enabled: true)
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
