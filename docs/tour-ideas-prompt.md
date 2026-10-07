# City Tour-Idea Library — Research Prompt (v1)

Use as the task prompt for a Claude run with web search / fetch and code execution. One city per run. Output feeds `Resources/Cities/<city>_tour_ideas.json`, which the app's `TourIdeaService` uses to generate tours **outside walk mode**. Run it **after** at least one cluster of the city's content pack exists (see `content-pipeline-prompt.md`), so ideas can reference pack entry ids.

---

## 0. Objective

Build a library of 15–30 high-quality walking-tour ideas for `{{city}}` by studying publicly available tour suggestions, then re-expressing them as original, verified, route-feasible ideas that reference our own content-pack entries. Ideas are **inspiration and structure**, never copied products. Each idea must work as a template the app can adapt to the user's start point, time budget, kids mode and difficult-history setting.

## 1. Inputs

- City: `{{city}}`; languages: `{{languages}}` (NYC en; Munich en, de; Milan en, de, it; Rome en, it, de — confirm)
- Pack entry index: `{{entry_index}}` (id, names, coordinates, tier, themes, sensitivity fields, kids_safe)
- Target: `{{n_ideas}}` ideas (15–30) covering a spread of durations (60, 90, 180, 360 min), themes and audiences
- Today's date: `{{today}}`

## 2. Sources to search (run queries in English and in the local language)

Query patterns: "best walking tour {city}", "{city} walking itinerary 3 hours / one day / two days", "{city} self-guided walking tour", "{city} walking route {theme}" (history, architecture, art, food, hidden, family, nightlife, religion, film, literature), "{city} with kids itinerary", "{city} free walking tour route", plus local-language equivalents ("Stadtrundgang {Stadt}", "itinerario a piedi {città}").

Source classes (use several of each):
1. **Official tourism boards and city sites** (self-guided routes, themed trails, downloadable walking maps).
2. **Museums, universities, heritage bodies** (trail leaflets, audio-tour outlines, historic-district walking tours).
3. **Wikivoyage** walking/itinerary articles (CC BY-SA; structure and leads only, no copied sentences).
4. **Public-domain guidebooks and walks** (see `content-pipeline-prompt.md` section 6 for the public-domain rules).
5. **Reputable editorial guides and independent guide blogs** (for what visitors actually recommend; leads only).
6. **Commercial tour operators' public itineraries** — use only to learn what recurs; do **not** reproduce any single operator's stop selection and order.

Skip paywalled content, content behind login, and anything disallowed by the site's robots rules or terms. If a site blocks access, say so; do not work around it.

## 3. Process

### Step 1 — Gather
For each theme/duration family, read **at least 8 independent sources**. For each source record: URL, title, publisher, class, terms/license as stated on the site, accessed date, and the ordered stop list it suggests with any stated duration.

### Step 2 — Extract structure only
Capture: theme, audience, stated duration and distance, start/end areas, stop order, why the route works, timing advice (best hour, season, closing days), practical warnings. Do **not** capture prose. Do not keep company names, brand names or slogans.

### Step 3 — Find consensus and originality
- A stop that appears in ≥3 independent sources for the same theme is a **strong candidate**.
- A stop mentioned by only one source is `single_source`: include only if it fits the route and can be verified against the content pack or an authoritative source.
- Look for recurring **pairings** and **sequences** (A→B is walkable and thematically linked), not for any one source's complete route.

### Step 4 — Map to the content pack
Map every stop to a pack entry id. Stops without an entry go to `missing_entries` (with name, QID if known, coordinates from an authoritative source, and which ideas need it). Do not invent entries.

### Step 5 — Compose original ideas
For each idea:
- **Blend ≥3 sources** and re-order using route logic (shortest sensible walk, no backtracking, avoid crossing the same main road repeatedly, respect topography).
- Write your own title (no operator names), a one-sentence pitch, and a 1–2 sentence "why it works".
- Provide `variants`: a shorter cut (drop lowest-interest stops) and, where relevant, `variant_without_sensitive` and a kids version (see section 5).
- Give connective walking notes per leg (30–50 words, for the ear): what changes between here and the next stop, what to notice. Use pack facts only; no new facts.

### Step 6 — Validate feasibility
Compute, with code: leg distances (haversine × 1.25 street factor unless you can verify a walking route), total distance, walking time at 4.5 km/h plus each stop's `duration_minutes`, and compare with the stated idea duration (tolerance ±15%). Flag: legs longer than 1.2 km, backtracking, big elevation changes, stops likely closed on certain weekdays (record as `check_hours` note, not as fact), and routes needing tickets or reservations (`needs_booking: true` without prices).

### Step 7 — Self-review
Ask: Would a local think this route makes sense? Is any single source's route reproduced (stop set and order)? If overlap with any one source is > 70% of stops in the same order, re-blend. Is every stop real, open to the public, and in the pack?

## 4. Legal and originality rules

- Facts and ideas are not the same as a source's expression, but a specific **selection and arrangement** of stops, and the text describing it, can be protected. Never copy a single commercial tour's route or wording. Blend, re-order, re-write.
- Do not use third-party photos, maps, brand names, or logos.
- Record terms/license for each source. Anything unclear: lead only.
- Wikivoyage (CC BY-SA): structure and leads only; no copied sentences.
- Flag to counsel: whether aggregating public itineraries into a commercial library raises any concerns in the target jurisdictions.

## 5. Sensitive content and kids

- Aggregate `sensitivity_tags` from the pack entries in each idea. If an idea contains `sensitive_only` entries, provide `variant_without_sensitive` (those stops removed and the route repaired) and confirm it still meets a minimum of 3 stops and ≥60% of the duration; otherwise mark the idea `adult_only_toggle_on`.
- Kids ideas (`audience: "kids" | "family"`) use only `kids_safe` entries, shorter legs (≤ 600 m), play or snack breaks, and total duration ≤ 120 minutes.
- Never rely on tone alone: exclusion is by entry flags.

## 6. Output

1. `tour_ideas_{{city_slug}}.json` — array of ideas (schema below).
2. `missing_entries_{{city_slug}}.md` — stops needed but absent from the pack, prioritized by how many ideas need them.
3. `sources_tour_ideas_{{city_slug}}.json` — sources with class, terms/license, accessed date.
4. `report_{{city_slug}}.md` — coverage by theme/duration/audience, ideas needing human review, top risks.

### Idea schema
```json
{
  "id": "rome-ancient-3h-01",
  "city": "rome",
  "theme": "history|architecture|art|food|hidden|family|nightlife|religion|film|literature",
  "audience": "adult|family|kids|all",
  "title": {"en": "", "it": "", "de": ""},
  "pitch": {"en": "", "it": "", "de": ""},
  "why_it_works": {"en": ""},
  "duration_minutes": 180,
  "distance_m": 4200,
  "difficulty": "easy|moderate|hilly",
  "start_area": "", "end_area": "",
  "stops": [
    {"entry_id": "rome-c1-000042", "order": 1, "stay_minutes": 15,
     "leg_note": {"en": "", "it": "", "de": ""}, "check_hours": false}
  ],
  "best_time": {"time_of_day": null, "season": null, "avoid": null},
  "needs_booking": false,
  "sensitivity_tags": [],
  "kids_safe": true,
  "variants": {"short": [], "without_sensitive": [], "kids": []},
  "adult_only_toggle_on": false,
  "adaptation": {"can_start_mid_route": true, "reversible": true, "drop_priority": ["entry ids, lowest interest first"]},
  "inspiration_source_ids": ["s1", "s4", "s9"],
  "overlap_max_with_single_source": 0.4,
  "review_flags": [],
  "verification": {"status": "agent_checked|needs_review", "last_verified": "{{today}}"}
}
```

## 7. How the app uses this (context, not for you to implement)

At tour-generation time `TourIdeaService` filters ideas by city, theme, audience, kids mode and the difficult-history setting, ranks them by fit with the user's start point and time budget, adapts the chosen idea (start mid-route, drop stops by `drop_priority`, reorder legs), and passes the selected pack entries to the model to write only the introduction and transitions. Facts come from the pack. Walk mode ignores this library and uses the trigger engine.

## 8. Method and done

- Use web search and page fetch for every source; open pages, do not rely on snippets.
- Use code for distance/time checks, overlap calculations and schema validation; validate every idea before returning.
- Work in batches of 5 ideas; report status after each batch.
- Done when: target count met across durations and themes; every stop maps to a pack entry or appears in `missing_entries`; every idea passes feasibility and overlap checks; sensitive and kids variants exist where required; every source has recorded terms.
