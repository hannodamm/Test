import Foundation

/// Centralizes the UserDefaults keys and supported-value catalogs shared between
/// SettingsView (via @AppStorage) and the services that read the same prefs via
/// `UserDefaults.standard`. Changing a key here triggers a compile error at
/// every call site rather than a silent divergence.
enum GuidePreferences {
    enum Key {
        static let language = "preferredLanguage"
        static let isKidFriendly = "isKidFriendly"
        static let personaId = "preferredPersonaId"
        static let tourDurationMinutes = "preferredTourDurationMinutes"
        static let tourRadiusMeters = "preferredTourRadiusMeters"
    }

    struct Language: Identifiable, Hashable {
        let id: String          // ISO 639-1 code stored in UserDefaults
        let displayName: String // UI label
        let speechCode: String  // BCP-47 locale for AVSpeechSynthesisVoice
        let nativeName: String  // Used inside Claude system prompts
    }

    static let supportedLanguages: [Language] = [
        .init(id: "en", displayName: "English",  speechCode: "en-US", nativeName: "English"),
        .init(id: "de", displayName: "Deutsch",  speechCode: "de-DE", nativeName: "German"),
        .init(id: "it", displayName: "Italiano", speechCode: "it-IT", nativeName: "Italian"),
        .init(id: "fr", displayName: "Français", speechCode: "fr-FR", nativeName: "French"),
        .init(id: "es", displayName: "Español",  speechCode: "es-ES", nativeName: "Spanish")
    ]

    static func language(for id: String) -> Language {
        supportedLanguages.first(where: { $0.id == id }) ?? supportedLanguages[0]
    }

    static var currentLanguage: Language {
        let id = UserDefaults.standard.string(forKey: Key.language) ?? "en"
        return language(for: id)
    }

    static var isKidFriendly: Bool {
        UserDefaults.standard.bool(forKey: Key.isKidFriendly)
    }

    // MARK: - Tour duration & radius

    enum TourDuration: Int, CaseIterable, Identifiable {
        case quick = 60
        case half = 180
        case full = 360

        var id: Int { rawValue }
        var displayName: String {
            switch self {
            case .quick: return "Quick (1 hr)"
            case .half: return "Half day (3 hrs)"
            case .full: return "Full day (6 hrs)"
            }
        }
        var shortLabel: String {
            switch self {
            case .quick: return "1 hour"
            case .half: return "3 hours"
            case .full: return "6 hours"
            }
        }
        var stopCount: ClosedRange<Int> {
            switch self {
            case .quick: return 3...4
            case .half: return 5...7
            case .full: return 8...10
            }
        }
    }

    static var currentDuration: TourDuration {
        let stored = UserDefaults.standard.integer(forKey: Key.tourDurationMinutes)
        return TourDuration(rawValue: stored) ?? .half
    }

    /// Default tour radius in meters. Clamped to [500, 5000].
    static var currentRadiusMeters: Double {
        let stored = UserDefaults.standard.double(forKey: Key.tourRadiusMeters)
        guard stored > 0 else { return 1500 }
        return min(5000, max(500, stored))
    }

    static var radiusDisplayString: String {
        let m = currentRadiusMeters
        if m < 1000 { return String(format: "%.0f m", m) }
        return String(format: "%.1f km", m / 1000)
    }

    /// System-prompt fragment expressing language + tone directives. Empty when
    /// language is English and kid-friendly is off, so existing prompts are
    /// unaffected until the user opts into a change.
    static var systemPromptModifier: String {
        var parts: [String] = []
        let lang = currentLanguage
        if lang.id != "en" {
            parts.append("Respond in \(lang.nativeName). All narration, facts, and answers must be written in \(lang.nativeName).")
        }
        if isKidFriendly {
            parts.append("Use a fun, exciting, kid-friendly tone suitable for an 11-to-13-year-old. Prefer simpler vocabulary; lean into amazing stories, surprising facts, and vivid imagery.")
        }
        return parts.joined(separator: " ")
    }

    // MARK: - Persona catalog

    /// Reserved ID meaning "let the tour generator or tour template pick a persona."
    static let autoPersonaId = "auto"

    struct PersonaOption: Identifiable, Hashable {
        let id: String
        let displayName: String
        let description: String
        let persona: GuidePersona
    }

    static let personaCatalog: [PersonaOption] = [
        .init(
            id: "marco",
            displayName: "Marco",
            description: "Charming Italian local, warm and curious",
            persona: GuidePersona(
                name: "Marco",
                tagline: "your charming local guide",
                voiceStyle: "warm, witty, a little theatrical, like a friend who lives two streets over",
                greeting: "Ciao, amico — shall we walk?",
                signoff: "A presto — come find me again tomorrow!"
            )
        ),
        .init(
            id: "sofia",
            displayName: "Sofia",
            description: "Art-loving Milanese, dreamy storyteller",
            persona: GuidePersona(
                name: "Sofia",
                tagline: "art historian with a thousand stories",
                voiceStyle: "elegant, evocative, rich in sensory detail",
                greeting: "Buongiorno — I can't wait to show you what this city remembers.",
                signoff: "Arrivederci — may the light stay with you."
            )
        ),
        .init(
            id: "professor",
            displayName: "The Professor",
            description: "Scholarly, precise, loves deep dives",
            persona: GuidePersona(
                name: "Professor Keller",
                tagline: "historian and lifelong city walker",
                voiceStyle: "measured, erudite, dry humor, rich with dates and context",
                greeting: "Ah — right on time. Let's begin where the story truly starts.",
                signoff: "Until next time — and do read up on what we saw."
            )
        ),
        .init(
            id: "witty-local",
            displayName: "Hannah",
            description: "Dry, knowing, opinionated favorites",
            persona: GuidePersona(
                name: "Hannah",
                tagline: "opinionated local, cynic with a soft spot",
                voiceStyle: "dry, deadpan, sharp, willing to call out tourist traps",
                greeting: "Alright — no tourist nonsense. Let's see the real place.",
                signoff: "Go eat dinner somewhere the menu isn't in four languages. Trust me."
            )
        ),
        .init(
            id: "bavarian",
            displayName: "Klaus",
            description: "Hearty Bavarian, loves beer halls and trails",
            persona: GuidePersona(
                name: "Klaus",
                tagline: "third-generation Münchner",
                voiceStyle: "hearty, direct, deeply fond of tradition, quick with a beer recommendation",
                greeting: "Servus! Come on — the city is prettier than the postcards.",
                signoff: "Pfiat di — and prost, wherever you end up tonight."
            )
        )
    ]

    static var selectedPersona: GuidePersona? {
        let id = UserDefaults.standard.string(forKey: Key.personaId) ?? autoPersonaId
        if id == autoPersonaId { return nil }
        return personaCatalog.first(where: { $0.id == id })?.persona
    }

    /// System-prompt fragment injecting the selected persona. Empty when the
    /// user has left the preference on "auto."
    static var personaPromptModifier: String {
        guard let persona = selectedPersona else { return "" }
        return "Speak in character as \(persona.name) — \(persona.tagline). Your voice style: \(persona.voiceStyle)."
    }
}
