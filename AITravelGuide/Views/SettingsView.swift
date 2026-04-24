import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var tourStorageService: TourStorageService
    @EnvironmentObject var speechService: SpeechService

    @State private var apiKeyInput: String = ""
    @State private var hasKey: Bool = APIKeyManager.shared.hasAPIKey
    @State private var showKey: Bool = false
    @State private var showSavedAlert: Bool = false
    @State private var showKeyFormatError: Bool = false

    @State private var openAIKeyInput: String = ""
    @State private var hasOpenAIKey: Bool = APIKeyManager.shared.hasOpenAIKey
    @State private var showOpenAIKey: Bool = false
    @State private var showOpenAISavedAlert: Bool = false
    @State private var showOpenAIKeyFormatError: Bool = false

    @AppStorage("voiceEnabled") private var voiceEnabled = true
    @AppStorage("speechRateIndex") private var speechRateIndex = 1 // 0=slow, 1=normal, 2=fast
    @AppStorage(GuidePreferences.Key.language) private var preferredLanguage: String = "en"
    @AppStorage(GuidePreferences.Key.isKidFriendly) private var isKidFriendly: Bool = false
    @AppStorage(GuidePreferences.Key.tourDurationMinutes) private var tourDurationMinutes: Int = GuidePreferences.TourDuration.half.rawValue
    @AppStorage(GuidePreferences.Key.tourRadiusMeters) private var tourRadiusMeters: Double = 1500
    @AppStorage(GuidePreferences.Key.personaId) private var personaId: String = GuidePreferences.autoPersonaId

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

                Section {
                    openAIKeySection
                } header: {
                    Text("OpenAI API Key")
                } footer: {
                    Text("Used for natural-sounding voice narration. Get a key at platform.openai.com")
                }

                Section {
                    Picker("Language", selection: $preferredLanguage) {
                        ForEach(GuidePreferences.supportedLanguages) { language in
                            Text(language.displayName).tag(language.id)
                        }
                    }
                    .onChange(of: preferredLanguage) { _, _ in
                        speechService.clearVoiceCache()
                    }

                    Toggle("Kid-Friendly Tone", isOn: $isKidFriendly)
                } header: {
                    Text("Guide Style")
                } footer: {
                    Text("Language affects both narration voice and AI responses. Kid-friendly tone is great for ages 11 to 13 — simpler words, more vivid stories.")
                }

                Section {
                    Picker("Duration", selection: $tourDurationMinutes) {
                        ForEach(GuidePreferences.TourDuration.allCases) { option in
                            Text(option.displayName).tag(option.rawValue)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Radius")
                            Spacer()
                            Text(radiusDisplay)
                                .foregroundStyle(.secondary)
                                .font(.subheadline.monospacedDigit())
                        }
                        Slider(value: $tourRadiusMeters, in: 500...5000, step: 100)
                    }
                } header: {
                    Text("Tour Defaults")
                } footer: {
                    Text("Used when you generate an AI tour. Curated city tours use their own fixed routes.")
                }

                Section {
                    Picker("Persona", selection: $personaId) {
                        Text("Auto — let the tour decide").tag(GuidePreferences.autoPersonaId)
                        ForEach(GuidePreferences.personaCatalog) { option in
                            Text(option.displayName).tag(option.id)
                        }
                    }
                    if personaId != GuidePreferences.autoPersonaId,
                       let option = GuidePreferences.personaCatalog.first(where: { $0.id == personaId }) {
                        Text(option.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Guide Persona")
                } footer: {
                    Text("Auto uses the voice picked by the tour generator or curated template. A specific persona overrides that across all tours and chat.")
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
                            if speechService.isSpeaking || speechService.isPaused {
                                speechService.stop()
                            } else {
                                speechService.speak("Hello! I'm your AI travel guide. Let me show you around.")
                            }
                        } label: {
                            Label(
                                speechService.isSpeaking || speechService.isPaused ? "Stop Preview" : "Preview Voice",
                                systemImage: speechService.isSpeaking || speechService.isPaused ? "stop.circle.fill" : "play.circle"
                            )
                        }
                        .tint(speechService.isSpeaking || speechService.isPaused ? .red : .accentColor)
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
                    LabeledContent("AI Model", value: "Claude Sonnet 4.6")
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
            .alert("OpenAI Key Saved", isPresented: $showOpenAISavedAlert) {
                Button("OK") {}
            } message: {
                Text("Your OpenAI API key has been saved. Natural voice narration is now enabled.")
            }
            .alert("Invalid OpenAI Key", isPresented: $showOpenAIKeyFormatError) {
                Button("OK") {}
            } message: {
                Text("OpenAI API keys start with \"sk-\". Please check your key and try again.")
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

    // MARK: - OpenAI Key Section

    @ViewBuilder
    private var openAIKeySection: some View {
        if hasOpenAIKey {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("OpenAI key configured")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Remove", role: .destructive) {
                    APIKeyManager.shared.openAIAPIKey = nil
                    hasOpenAIKey = false
                    openAIKeyInput = ""
                }
                .font(.subheadline)
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if showOpenAIKey {
                        TextField("sk-...", text: $openAIKeyInput)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    } else {
                        SecureField("sk-...", text: $openAIKeyInput)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                            .textInputAutocapitalization(.never)
                    }
                    Button {
                        showOpenAIKey.toggle()
                    } label: {
                        Image(systemName: showOpenAIKey ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    let trimmed = openAIKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    guard trimmed.hasPrefix("sk-") else {
                        showOpenAIKeyFormatError = true
                        return
                    }
                    APIKeyManager.shared.openAIAPIKey = trimmed
                    hasOpenAIKey = true
                    showOpenAISavedAlert = true
                } label: {
                    Text("Save API Key")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(openAIKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    // MARK: - AI Features Status

    private var aiFeaturesStatus: some View {
        Group {
            featureRow("AI Chat Responses", enabled: hasKey)
            featureRow("AI Tour Generation", enabled: hasKey)
            featureRow("Tour Stop Narration", enabled: hasKey)
            featureRow("Natural Voice (OpenAI TTS)", enabled: hasOpenAIKey)
            featureRow("Voice Guide", enabled: voiceEnabled)
            featureRow("Walking Directions", enabled: true)
            featureRow("Offline Template Responses", enabled: true)
            featureRow("MapKit POI Search", enabled: true)
        }
    }

    private var radiusDisplay: String {
        if tourRadiusMeters < 1000 {
            return String(format: "%.0f m", tourRadiusMeters)
        }
        return String(format: "%.1f km", tourRadiusMeters / 1000)
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
