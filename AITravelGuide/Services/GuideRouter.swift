import Foundation

/// Which engine generates the guide's text (narration + chat).
enum GuideBackend: Equatable {
    /// Anthropic Claude API — richest output, best at real place names & history.
    /// Requires a user-provided API key (Settings → Claude API Key).
    case claude
    /// Apple Foundation Models — Apple's on-device LLM. Free, offline, private,
    /// no key. Only on iOS 26+ Apple-Intelligence-capable hardware.
    case onDevice
    /// Bundled template responses. Always available (old devices, EU, no key).
    case canned
}

/// The single decision point for which backend generates guide text.
///
/// Every generation site in the app (chat, per-stop chat, spoken narration)
/// routes through `selectBackend()` — so changing the app's whole AI behavior
/// is a one-line edit here, not a hunt across five files.
///
/// Default priority: **Claude (if key) → on-device Apple model → canned**.
/// Claude wins when a key exists because it is materially better at accurate,
/// specific place and history content — the core value of this app.
///
/// To prefer free/offline/private generation over Claude, swap the first two
/// `if` lines below.
@MainActor
enum GuideRouter {
    static func selectBackend() -> GuideBackend {
        if APIKeyManager.shared.hasAPIKey { return .claude }
        if OnDeviceGuideService.isAvailable { return .onDevice }
        return .canned
    }
}
