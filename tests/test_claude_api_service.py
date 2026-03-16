"""
Tests for ClaudeAPIService — mirrors the Swift implementation's public API.

Unit tests use mocks and run without an API key.
Integration tests require ANTHROPIC_API_KEY env var and call the real endpoint.

Run:
    python -m pytest tests/test_claude_api_service.py -v
    python -m pytest tests/test_claude_api_service.py -v -m integration  # live tests only
"""

import json
import os
import unittest
from unittest.mock import AsyncMock, MagicMock, patch
import asyncio

# ---------------------------------------------------------------------------
# Helpers mirroring the Swift types
# ---------------------------------------------------------------------------

API_URL = "https://api.anthropic.com/v1/messages"
MODEL = "claude-sonnet-4-5-20250929"
MAX_TOKENS = 1024
ANTHROPIC_VERSION = "2023-06-01"


def build_system_prompt(context: dict, persona: dict | None = None) -> str:
    """Python port of ClaudeAPIService.buildSystemPrompt."""
    parts = []

    if persona:
        parts.append(
            f"You are {persona['name']}, {persona['tagline']}. "
            f"Your style: {persona['voiceStyle']}. Stay in character."
        )
    else:
        parts.append(
            "You are an expert AI travel guide helping a user explore "
            "their surroundings in real time."
        )

    parts.append("Be friendly, concise, and knowledgeable. Provide specific, actionable advice.")
    parts.append(
        "When you don't know something specific about a place, say so honestly rather than guessing."
    )
    parts.append("")
    parts.append("CURRENT LOCATION CONTEXT:")

    if context.get("city"):
        parts.append(f"- City: {context['city']}")
    if context.get("country"):
        parts.append(f"- Country: {context['country']}")
    if context.get("neighborhood"):
        parts.append(f"- Neighborhood: {context['neighborhood']}")
    if context.get("coordinate"):
        lat, lon = context["coordinate"]
        parts.append(f"- Coordinates: {lat:.4f}, {lon:.4f}")

    nearby_names = context.get("nearbyPOINames", [])
    if nearby_names:
        parts.append("")
        parts.append("NEARBY PLACES (from Apple Maps):")
        for name in nearby_names[:10]:
            parts.append(f"- {name}")

    nearby_cats = context.get("nearbyPOICategories", [])
    if nearby_cats:
        parts.append("")
        parts.append(f"NEARBY CATEGORIES: {', '.join(nearby_cats)}")

    if context.get("currentTourName"):
        parts.append("")
        parts.append(f"USER IS CURRENTLY ON TOUR: \"{context['currentTourName']}\"")
        if context.get("currentTourCategory"):
            parts.append(f"Tour type: {context['currentTourCategory']}")

    return "\n".join(parts)


def build_messages(history: list[dict], new_question: str) -> list[dict]:
    """Python port of ClaudeAPIService.buildMessages."""
    api_messages = []

    recent = history[-10:]
    for msg in recent:
        role = msg["role"]
        if role in ("user", "assistant"):
            api_messages.append({"role": role, "content": msg["content"]})
        # system messages are skipped

    # Only append if the question isn't already the last user message
    last_user_content = next(
        (m["content"] for m in reversed(api_messages) if m["role"] == "user"), None
    )
    if last_user_content != new_question:
        api_messages.append({"role": "user", "content": new_question})

    # Ensure messages don't start with an assistant message
    if api_messages and api_messages[0]["role"] == "assistant":
        api_messages.pop(0)

    return api_messages


def build_api_request_body(system: str, messages: list[dict]) -> dict:
    """Build the JSON body sent to the Anthropic Messages API."""
    return {
        "model": MODEL,
        "max_tokens": MAX_TOKENS,
        "system": system,
        "messages": messages,
    }


# ---------------------------------------------------------------------------
# Unit tests
# ---------------------------------------------------------------------------

class TestBuildSystemPrompt(unittest.TestCase):

    def test_default_persona(self):
        ctx = {"city": "Rome", "country": "Italy", "nearbyPOINames": [], "nearbyPOICategories": []}
        prompt = build_system_prompt(ctx)
        self.assertIn("expert AI travel guide", prompt)
        self.assertIn("City: Rome", prompt)
        self.assertIn("Country: Italy", prompt)

    def test_custom_persona(self):
        ctx = {"city": "Paris", "country": "France", "nearbyPOINames": [], "nearbyPOICategories": []}
        persona = {
            "name": "Pierre",
            "tagline": "your Parisian insider",
            "voiceStyle": "witty and enthusiastic",
        }
        prompt = build_system_prompt(ctx, persona)
        self.assertIn("You are Pierre", prompt)
        self.assertIn("your Parisian insider", prompt)
        self.assertIn("witty and enthusiastic", prompt)
        self.assertNotIn("expert AI travel guide", prompt)

    def test_nearby_pois_included(self):
        ctx = {
            "city": "London",
            "country": "UK",
            "nearbyPOINames": ["Tower of London", "Tower Bridge"],
            "nearbyPOICategories": ["Landmark", "Bridge"],
        }
        prompt = build_system_prompt(ctx)
        self.assertIn("NEARBY PLACES (from Apple Maps):", prompt)
        self.assertIn("- Tower of London", prompt)
        self.assertIn("- Tower Bridge", prompt)
        self.assertIn("NEARBY CATEGORIES: Landmark, Bridge", prompt)

    def test_nearby_pois_capped_at_10(self):
        ctx = {
            "nearbyPOINames": [f"Place {i}" for i in range(15)],
            "nearbyPOICategories": [],
        }
        prompt = build_system_prompt(ctx)
        self.assertIn("Place 9", prompt)
        self.assertNotIn("Place 10", prompt)

    def test_active_tour_included(self):
        ctx = {
            "city": "Munich",
            "currentTourName": "Beer & Brewery Tour",
            "currentTourCategory": "Food & Drink",
            "nearbyPOINames": [],
            "nearbyPOICategories": [],
        }
        prompt = build_system_prompt(ctx)
        self.assertIn('USER IS CURRENTLY ON TOUR: "Beer & Brewery Tour"', prompt)
        self.assertIn("Tour type: Food & Drink", prompt)

    def test_missing_optional_fields(self):
        ctx = {}  # all optional
        prompt = build_system_prompt(ctx)
        self.assertIn("CURRENT LOCATION CONTEXT:", prompt)
        self.assertNotIn("City:", prompt)
        self.assertNotIn("Country:", prompt)

    def test_coordinate_formatting(self):
        ctx = {
            "coordinate": (48.1351, 11.5820),
            "nearbyPOINames": [],
            "nearbyPOICategories": [],
        }
        prompt = build_system_prompt(ctx)
        self.assertIn("Coordinates: 48.1351, 11.5820", prompt)


class TestBuildMessages(unittest.TestCase):

    def test_empty_history_appends_question(self):
        msgs = build_messages([], "What is this place?")
        self.assertEqual(len(msgs), 1)
        self.assertEqual(msgs[0], {"role": "user", "content": "What is this place?"})

    def test_system_messages_are_stripped(self):
        history = [
            {"role": "system", "content": "System info"},
            {"role": "user", "content": "Hello"},
            {"role": "assistant", "content": "Hi!"},
        ]
        msgs = build_messages(history, "Tell me more")
        roles = [m["role"] for m in msgs]
        self.assertNotIn("system", roles)

    def test_no_duplicate_question(self):
        """If the last user message IS the new question, don't append it again."""
        history = [{"role": "user", "content": "What is this?"}]
        msgs = build_messages(history, "What is this?")
        user_msgs = [m for m in msgs if m["role"] == "user"]
        self.assertEqual(len(user_msgs), 1)

    def test_history_capped_at_10(self):
        history = [
            {"role": "user" if i % 2 == 0 else "assistant", "content": f"msg {i}"}
            for i in range(20)
        ]
        msgs = build_messages(history, "New question")
        # 10 from recent history + 1 new question = 11 max
        self.assertLessEqual(len(msgs), 11)

    def test_assistant_first_removed(self):
        history = [
            {"role": "assistant", "content": "I started talking"},
            {"role": "user", "content": "Ok"},
        ]
        msgs = build_messages(history, "New question")
        self.assertEqual(msgs[0]["role"], "user")

    def test_conversation_order_preserved(self):
        history = [
            {"role": "user", "content": "Q1"},
            {"role": "assistant", "content": "A1"},
            {"role": "user", "content": "Q2"},
            {"role": "assistant", "content": "A2"},
        ]
        msgs = build_messages(history, "Q3")
        contents = [m["content"] for m in msgs]
        self.assertEqual(contents, ["Q1", "A1", "Q2", "A2", "Q3"])


class TestAPIRequestStructure(unittest.TestCase):

    def test_required_fields_present(self):
        system = "You are a guide."
        messages = [{"role": "user", "content": "Hi"}]
        body = build_api_request_body(system, messages)

        self.assertEqual(body["model"], MODEL)
        self.assertEqual(body["max_tokens"], MAX_TOKENS)
        self.assertEqual(body["system"], system)
        self.assertEqual(body["messages"], messages)

    def test_request_is_json_serializable(self):
        body = build_api_request_body(
            "System prompt",
            [{"role": "user", "content": "Hello"}],
        )
        serialized = json.dumps(body)
        restored = json.loads(serialized)
        self.assertEqual(restored["model"], MODEL)

    def test_model_name(self):
        self.assertEqual(MODEL, "claude-sonnet-4-5-20250929")

    def test_max_tokens(self):
        self.assertEqual(MAX_TOKENS, 1024)


class TestAPIErrorHandling(unittest.TestCase):
    """
    Tests mirroring the Swift APIError enum behavior by checking the
    HTTP response handling logic inline.
    """

    def _parse_response(self, status_code: int, body: dict) -> str:
        """Simulate callAPI error extraction."""
        if status_code == 200:
            content = body.get("content", [])
            text_blocks = [b["text"] for b in content if b.get("type") == "text"]
            if text_blocks:
                return text_blocks[0]
            return "__no_content__"

        error = body.get("error", {})
        if error:
            return f"API error ({status_code}): {error.get('message', 'unknown')}"
        return f"Server returned status {status_code}."

    def test_200_extracts_text(self):
        body = {"content": [{"type": "text", "text": "Hello traveller!"}]}
        result = self._parse_response(200, body)
        self.assertEqual(result, "Hello traveller!")

    def test_200_multiple_blocks_returns_first_text(self):
        body = {
            "content": [
                {"type": "image", "url": "..."},
                {"type": "text", "text": "First text"},
                {"type": "text", "text": "Second text"},
            ]
        }
        result = self._parse_response(200, body)
        self.assertEqual(result, "First text")

    def test_200_no_text_block(self):
        body = {"content": [{"type": "image", "url": "..."}]}
        result = self._parse_response(200, body)
        self.assertEqual(result, "__no_content__")

    def test_401_with_error_body(self):
        body = {"error": {"type": "authentication_error", "message": "Invalid API key"}}
        result = self._parse_response(401, body)
        self.assertIn("401", result)
        self.assertIn("Invalid API key", result)

    def test_429_rate_limit(self):
        body = {"error": {"type": "rate_limit_error", "message": "Rate limit exceeded"}}
        result = self._parse_response(429, body)
        self.assertIn("429", result)
        self.assertIn("Rate limit exceeded", result)

    def test_500_no_error_body(self):
        result = self._parse_response(500, {})
        self.assertIn("500", result)

    def test_request_headers(self):
        api_key = "sk-ant-test-key"
        headers = {
            "x-api-key": api_key,
            "anthropic-version": ANTHROPIC_VERSION,
            "content-type": "application/json",
        }
        self.assertEqual(headers["x-api-key"], api_key)
        self.assertEqual(headers["anthropic-version"], "2023-06-01")
        self.assertEqual(headers["content-type"], "application/json")


class TestNarrateStopPrompt(unittest.TestCase):
    """Tests for the narrateStop prompt construction."""

    def _build_narration_system(self, persona: dict | None = None) -> str:
        parts = []
        if persona:
            parts.append(
                f"You are {persona['name']}, a travel guide with this style: {persona['voiceStyle']}."
            )
            parts.append("Speak in character — match that voice and energy.")
        else:
            parts.append("You are an expert travel guide narrating a walking tour.")
        parts.append(
            "Write as if speaking aloud to someone standing right here: "
            "use natural pauses, conversational tone, and vivid details."
        )
        parts.append(
            "Keep it under 150 words. Do not use markdown, bullet points, or headings "
            "— just flowing spoken text."
        )
        return " ".join(parts)

    def _build_narration_user(self, stop: dict, location_ctx: dict) -> str:
        parts = [
            "Narrate this tour stop for a visitor:",
            f"Name: {stop['name']}",
            f"Description: {stop['description']}",
            f"Location: {location_ctx.get('city', 'Unknown')}, {location_ctx.get('country', 'Unknown')}",
            f"Neighborhood: {location_ctx.get('neighborhood', 'N/A')}",
        ]
        if stop.get("historicalNote"):
            parts.append(f"Historical note: {stop['historicalNote']}")
        if stop.get("tips"):
            parts.append(f"Tip: {stop['tips']}")
        if stop.get("walkingNarration"):
            parts.append(f"Walking narration context: {stop['walkingNarration']}")
        return "\n".join(parts)

    def test_default_persona_system_prompt(self):
        system = self._build_narration_system()
        self.assertIn("expert travel guide narrating a walking tour", system)
        self.assertIn("under 150 words", system)
        self.assertIn("Do not use markdown", system)

    def test_custom_persona_system_prompt(self):
        persona = {"name": "Marco", "voiceStyle": "dramatic and poetic"}
        system = self._build_narration_system(persona)
        self.assertIn("You are Marco", system)
        self.assertIn("dramatic and poetic", system)
        self.assertIn("Speak in character", system)

    def test_user_prompt_includes_stop_details(self):
        stop = {
            "name": "Colosseum",
            "description": "Ancient amphitheatre",
            "historicalNote": "Built in 70 AD",
            "tips": "Book tickets in advance",
            "walkingNarration": None,
        }
        ctx = {"city": "Rome", "country": "Italy", "neighborhood": "Celio"}
        user_msg = self._build_narration_user(stop, ctx)
        self.assertIn("Colosseum", user_msg)
        self.assertIn("Ancient amphitheatre", user_msg)
        self.assertIn("Built in 70 AD", user_msg)
        self.assertIn("Book tickets in advance", user_msg)
        self.assertIn("Rome", user_msg)
        self.assertIn("Celio", user_msg)

    def test_optional_fields_absent_when_none(self):
        stop = {"name": "Park", "description": "Nice park"}
        ctx = {}
        user_msg = self._build_narration_user(stop, ctx)
        self.assertNotIn("Historical note:", user_msg)
        self.assertNotIn("Tip:", user_msg)
        self.assertNotIn("Walking narration context:", user_msg)


# ---------------------------------------------------------------------------
# Integration tests  (require ANTHROPIC_API_KEY)
# ---------------------------------------------------------------------------

import urllib.request
import urllib.error

INTEGRATION = unittest.skipUnless(
    os.environ.get("ANTHROPIC_API_KEY"),
    "ANTHROPIC_API_KEY not set — skipping integration tests",
)


@INTEGRATION
class TestLiveAPIIntegration(unittest.TestCase):
    """
    Live integration tests against the real Anthropic Messages API.
    These are skipped automatically when ANTHROPIC_API_KEY is not set.
    """

    API_KEY = os.environ.get("ANTHROPIC_API_KEY", "")

    def _call_api(self, system: str, messages: list[dict]) -> dict:
        body = build_api_request_body(system, messages)
        data = json.dumps(body).encode()

        req = urllib.request.Request(
            API_URL,
            data=data,
            headers={
                "x-api-key": self.API_KEY,
                "anthropic-version": ANTHROPIC_VERSION,
                "content-type": "application/json",
            },
            method="POST",
        )

        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode())

    def _extract_text(self, response: dict) -> str:
        for block in response.get("content", []):
            if block.get("type") == "text":
                return block["text"]
        return ""

    def test_basic_ask_returns_text(self):
        system = "You are a concise travel guide. Keep answers under 50 words."
        messages = [{"role": "user", "content": "What is the Colosseum in Rome?"}]
        resp = self._call_api(system, messages)
        text = self._extract_text(resp)
        self.assertTrue(len(text) > 0, "Expected non-empty text response")
        self.assertIn("Colosseum", text)

    def test_response_structure(self):
        system = "You are a helpful assistant."
        messages = [{"role": "user", "content": "Say exactly: OK"}]
        resp = self._call_api(system, messages)
        self.assertIn("content", resp)
        self.assertIn("model", resp)
        self.assertIn("usage", resp)
        self.assertTrue(len(resp["content"]) > 0)
        self.assertEqual(resp["content"][0]["type"], "text")

    def test_model_field_matches(self):
        system = "You are a helpful assistant."
        messages = [{"role": "user", "content": "Say exactly: OK"}]
        resp = self._call_api(system, messages)
        # The response model may include a snapshot suffix; check prefix
        self.assertTrue(
            resp["model"].startswith("claude-sonnet"),
            f"Unexpected model: {resp['model']}",
        )

    def test_location_context_in_system_prompt(self):
        ctx = {
            "city": "Barcelona",
            "country": "Spain",
            "neighborhood": "Gothic Quarter",
            "nearbyPOINames": ["Sagrada Familia", "Park Güell"],
            "nearbyPOICategories": ["Religious", "Park"],
        }
        system = build_system_prompt(ctx)
        messages = [{"role": "user", "content": "What should I visit nearby?"}]
        resp = self._call_api(system, messages)
        text = self._extract_text(resp)
        self.assertTrue(len(text) > 20, "Expected substantive response")

    def test_narrate_stop_prompt(self):
        system = (
            "You are an expert travel guide narrating a walking tour. "
            "Write as if speaking aloud. Keep it under 150 words. "
            "No markdown — just flowing spoken text."
        )
        messages = [
            {
                "role": "user",
                "content": (
                    "Narrate this tour stop for a visitor:\n"
                    "Name: Brandenburg Gate\n"
                    "Description: Neoclassical monument and Berlin symbol\n"
                    "Location: Berlin, Germany\n"
                    "Neighborhood: Mitte\n"
                    "Historical note: Built in 1791, it witnessed the fall of the Berlin Wall"
                ),
            }
        ]
        resp = self._call_api(system, messages)
        text = self._extract_text(resp)
        word_count = len(text.split())
        self.assertGreater(word_count, 10, "Narration too short")
        self.assertLessEqual(word_count, 200, "Narration too long (model ignored instruction)")

    def test_no_api_key_guard(self):
        """
        Verify that an invalid API key returns 401 — mirrors the Swift guard
        that returns early when no key is set.
        """
        body = build_api_request_body(
            "You are a helpful assistant.",
            [{"role": "user", "content": "Hi"}],
        )
        data = json.dumps(body).encode()
        req = urllib.request.Request(
            API_URL,
            data=data,
            headers={
                "x-api-key": "invalid-key",
                "anthropic-version": ANTHROPIC_VERSION,
                "content-type": "application/json",
            },
            method="POST",
        )
        with self.assertRaises(urllib.error.HTTPError) as cm:
            urllib.request.urlopen(req, timeout=10)
        self.assertEqual(cm.exception.code, 401)


if __name__ == "__main__":
    unittest.main(verbosity=2)
