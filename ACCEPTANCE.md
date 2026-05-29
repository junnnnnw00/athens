# ACCEPTANCE.md — Functional & Visual Acceptance Spec

> Read alongside PROMPT.md and CLAUDE.md. **This document overrides any weaker reading of the
> Definition of Done.** The previous build compiled, tested, and ran — but every screen was a
> mockup with fake data and the UI was unstyled default Material. That is an explicit FAILURE
> here, not a pass. The rule from now on: **working software, not a clickable mockup.**

---

## 0. Why the last build failed (so it isn't repeated)

"flutter analyze passes + flutter test passes + flutter build succeeds" is satisfiable by a
fully fake app: hardcoded lists rendered in widgets, buttons with empty handlers, tests that only
exercise fakes against each other, and Flutter's default blue/purple Material theme. All green,
all useless. The gates below make that state IMPOSSIBLE to pass.

---

## PART A — Anti-mockup rules (global, non-negotiable)

A1. **No hardcoded display data anywhere in `lib/`.** Every list, card, number, and chart shown to
the user MUST originate from a Riverpod provider backed by a repository that reads from Drift
(local) and/or Supabase/external APIs. A literal array of items/ratings/tags rendered directly in a
widget is a failure.

A2. **Seed/sample data is allowed in exactly one place:** a clearly named `dev_seed.dart` guarded by
a `kDevSeed` flag that is `false` in release builds. It populates the *real* data layer (Drift/
Supabase), it does NOT short-circuit the UI. Seeded data must flow through the same providers as
real data.

A3. **No unfinished runtime paths.** In `lib/` (excluding `*_test.dart` and `dev_seed.dart`):
no `UnimplementedError`, no `throw UnsupportedError('TODO')`, no empty `onPressed: () {}` /
`onTap: () {}` on interactive controls, no `return Container();`-style placeholder screens, no
"Coming soon" text. Every interactive element is wired to a real handler that performs its action.

A4. **Mocks/fakes live ONLY in tests.** `FakeSpotifyApi`, `FakeSupabaseGateway`, etc. exist under
`test/`. They must never be imported by `lib/` runtime code. The running app talks to the real
interfaces (which read keys from env / edge functions).

A5. **The ranking engine is real logic, not a stub.** Elo update, score mapping, and pair selection
are pure functions with deterministic, asserted behavior (see B1). "Returns a random number" or
"returns the first item" is a failure.

---

## PART B — Per-feature functional acceptance criteria

Each feature is DONE only when its criteria are proven by an automated test (unit/integration/
widget) AND wired into the live UI. Write the test first where practical.

**B1. Ranking engine (the heart — hold the highest bar)**
- `expected(a,b)` returns 0.5 when ratings equal; >0.5 when a>b; monotonic. (asserted)
- `update(winner, loser)` raises winner, lowers loser, conserves reasonably; upset (low beats high) moves ratings more than expected win. (asserted with concrete numbers)
- `scoreFromElo` maps elo 1000 → 5.0, is monotonic, bounded 0–10. (asserted)
- `PairSelector` never returns a pair with two identical items; biases toward fewest-comparisons items; over many picks, covers the whole library. (asserted over a simulated library)
- Coverage on the `rank` domain ≥ 90% with MEANINGFUL assertions (not just "calls without throwing").

**B2. Rate a duel → persisted ranking**
- Given two items on the duel screen, tapping one records a `comparison`, updates both `ratings` via Elo, and the library reflects the new order.
- Integration test: seed real data layer → simulate N choices → assert ranked order changes AND survives an app restart (re-read from Drift). No fake shortcut.

**B3. Catalog search (real data)**
- Searching a query calls `CatalogService` → Spotify app-token (or iTunes fallback) → returns real results with title/artist/cover, cached into `items`.
- In tests the network boundary is faked with REALISTIC fixtures; in the running app it hits the real API. Acceptance: a widget test drives the search box and renders results from the service layer, not a literal list.
- Empty query, no-results, and network-error states each render their own real UI (not a crash, not a blank).

**B4. Genre + mood tags**
- Adding/opening an item enriches it with Last.fm + MusicBrainz tags into `items.tags`; the item detail screen renders those real tags. No hardcoded ["shoegaze","dreamy"] in the widget.

**B5. Home "rate this" prompts (allow-listed Spotify users)**
- For a `spotify_enabled` profile, the home pulls recently-played, diffs against already-rated items, and surfaces unrated ones as cards. For non-enabled users, a real alternative/empty state renders.
- Integration test with a fake recently-played fixture asserts only unrated items appear.

**B6. Cross-device sync**
- A rating/review written on "device A" (one client/session) appears on "device B" (second session, same user) via Supabase. Integration test with FakeSupabaseGateway proves push→pull→merge and last-write-wins; RLS prevents reading another user's rows.

**B7. Reviews**
- Writing/editing a review persists (Drift + Supabase), survives restart, and shows on item detail and the public profile (if public).

**B8. Stats**
- Stats screen computes from the user's actual ratings: score distribution, top genres/moods (from cached tags), activity over time. Charts read computed values, never hardcoded series. Asserted: StatsEngine over a known fixture yields the expected buckets.

**B9. Public profile web page**
- `/u/[handle]` fetches the Supabase public view with the anon/publishable key and renders the real ranked list + stats for a `is_public` profile; a private/nonexistent handle renders a proper "not available" page, never leaks data.

**B10. Instagram-story export**
- Produces a real 1080×1920 PNG from live data via RepaintBoundary, with ≥2 templates ("Top 5", "Taste Snapshot" using real top tags), and triggers share. Golden test asserts the card renders the data (not placeholders).

---

## PART C — Design system (kill the default-Material look)

The app must NOT look like stock Material. Match the visual language of the project's reference
prototype (the editorial music-zine look already approved): deep dark canvas, one confident accent,
strong type hierarchy, generous whitespace, real album art carrying the visuals.

C1. **One central theme, no defaults.** Create `lib/theme/` with `app_theme.dart` (a fully specified
dark `ThemeData`) and `tokens.dart` (color/spacing/radius/type tokens). NO widget may rely on the
default Material blue/purple/teal. `MaterialApp` uses this theme; `useMaterial3: true` but every
default color is overridden.

C2. **Palette (tokens):**
- background `#0C0A10` (deep ink), surface `#15121C`, surface-2 `#1C1825`, hairline `#2A2533`
- text `#ECE7E1`, muted `#8D8597`, faint `#5B5566`
- ONE accent: `#FF5D8F` (pink haze). A single secondary `#6FA8FF` is allowed only for the duel's "other side". No other accent colors. No rainbow charts — chart series use tints of the accent + neutrals.

C3. **Typography:**
- Display/editorial: **Fraunces** (serif), used for titles, scores, the duel prompt.
- UI/body + Korean: **Pretendard** (preferred for Korean) or IBM Plex Sans KR. Mono accents: IBM Plex Mono for labels/tags.
- Bundle fonts via `google_fonts` or local assets; define text styles in tokens, never inline ad-hoc `TextStyle(fontSize: 14)` scattered around.

C4. **Component standards:**
- Duel cards: large album art, type tag, title (serif), artist; tap = scale/opacity feedback; the chosen card pops, the other dims. Match the prototype's feel.
- Ranked list rows: rank number (crown on #1), 52px cover, title (serif), "artist · N comparisons", right-aligned 0–10 score (serif).
- Bottom nav: 2 tabs + center accent FAB. Custom, not default `BottomNavigationBar` styling.
- Consistent 8px spacing scale, 14–18px radii, hairline borders, subtle accent glows. No raw default `ElevatedButton`/`Card` left unstyled.

C5. **Motion & states:** screen/list entrance animations (subtle), tap feedback on every control,
real loading skeletons (not a bare spinner where a skeleton fits), and designed empty/error states
that match the aesthetic.

C6. **Korean-first polish:** UI strings in Korean read naturally; line-breaks/ellipsis handle long
Korean titles; tap targets ≥ 44px.

---

## PART D — Hardened Definition of Done (replaces the 10 in PROMPT.md where stricter)

All original 10 still apply, PLUS:

D1. Part A grep gates pass (see PART E) — zero hardcoded-display / unfinished-path hits in `lib/`.
D2. Every B1–B10 feature has its acceptance test(s) passing; rank-domain coverage ≥90% with real assertions.
D3. An `integration_test/` suite boots the app on seeded real data and walks the core loop
(search → add → duel → library reorder → stats render → share export) asserting REAL widgets and
REAL values at each step. It passes via `flutter test integration_test/`.
D4. A custom theme exists; a startup assertion (or test) verifies the app's primary/scaffold colors
equal the tokens, NOT Material defaults.
D5. **Proof-of-function artifacts:** golden tests render Home, Duel, Library, Item-detail, Stats,
and the IG card from seeded data; the generated golden PNGs are committed under
`test/golden/` so the morning review can see real screens at a glance.
D6. `RUN.md` documents exactly how to launch the app against real keys and what each screen should
show, so a human can verify in 5 minutes.

The goal is NOT met while any screen shows placeholder data, any control is dead, or the theme is
default Material — even if analyze/test/build are green.

---

## PART E — Verification commands & grep gates

Run from repo root; all must pass before declaring done:

```bash
# 1. anti-mockup grep gates (must return NOTHING in lib/, excluding tests + dev_seed)
! grep -rnE "UnimplementedError|UnsupportedError\('TODO|Coming soon|placeholder" app/lib --include=*.dart
! grep -rnE "onPressed:\s*\(\)\s*\{\s*\}|onTap:\s*\(\)\s*\{\s*\}" app/lib --include=*.dart
! grep -rn "// TODO" app/lib --include=*.dart   # allow only if moved to IDEAS.md; none should block core loop

# 2. fakes never imported by runtime
! grep -rn "Fake" app/lib --include=*.dart

# 3. standard gates
cd app && flutter analyze
cd app && flutter test                                  # includes unit + widget + golden
cd app && flutter test integration_test/                # core-loop e2e on seeded data
cd app && flutter build apk --debug
cd app && flutter build web
cd web && npm ci && npm run build

# 4. secret-leak gate (must return NOTHING)
! git grep -nE "sb_secret_|SPOTIFY_CLIENT_SECRET=|LASTFM_API_KEY=[A-Za-z0-9]"
```

If a gate can't pass because of a genuine credential/device limit, stub the NETWORK BOUNDARY only
(never the UI or logic), prove the path with a fake fixture in tests, and record the exact manual
verification step in MORNING-CHECKLIST.md. The UI and the logic still ship real.

---

## PART F — Wiring this into the run

- CLAUDE.md: add ACCEPTANCE.md to the "Source of truth" list and treat PART A as a hard guardrail.
- The `/goal` finish line should reference this: append to the goal text →
  *"...AND all ACCEPTANCE.md gates pass (Parts A–E): no mockups, no dead controls, custom theme (not default Material), every B-feature proven by a passing test, integration_test core-loop suite green, and committed golden screens."*
- Rebuild order if the current tree is mostly mockups: keep the scaffold, then for each feature
  B1→B10 replace fake/hardcoded UI with the real provider→repository→data path, styling each screen
  to PART C as you go. Commit + tag per feature. Update PROGRESS.md and golden screens each time.
