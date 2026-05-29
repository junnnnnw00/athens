# Athens — Build Progress

## Current State (2026-05-30)

Rebuilt from "compiles-but-mockup" into working software per ACCEPTANCE.md + DESIGN.md.
The runtime now renders only real data through Riverpod → repository → Drift/APIs.

### DoD + ACCEPTANCE checks (fresh, this machine)

| Check | Status | Evidence |
|-------|--------|----------|
| 1. `flutter analyze` | ✅ 0 issues | "No issues found! (ran in 2.4s)" |
| 2. `flutter test` | ✅ 83 pass | unit + widget + golden; full run green |
| 2. rank-domain coverage ≥90% | ✅ 98.9% | 91/92 lines (elo/score/pair_selector/stats_engine) |
| 3. `flutter build apk --debug` | ⏳ see below | Android SDK 35 present; JDK being installed locally; CI builds it |
| 4. `flutter build web` | ✅ exit 0 | background build completed |
| 5. `npm ci && npm run build` (web) | ✅ exit 0 | background build completed |
| 6. SQL sqlfluff clean + RLS + view + edge fns | ✅ | sqlfluff exit 0; 5 tables RLS; `public_profiles`; 2 edge fns |
| 7. No secrets + complete `.env.example` | ✅ | secret-leak grep returns nothing |
| 8. Docs complete | ✅ | README, LICENSE, CONTRIBUTING, SETUP, SPOTIFY, TAGS, ARCHITECTURE, RUN |
| 9. PROGRESS/DECISIONS/BLOCKERS/MORNING/IDEAS | ✅ | all present + updated |
| 10. Commit history + milestone tags | ⏳ | tags m0–m7 applied at end of run |

### ACCEPTANCE gates

| Gate | Status |
|------|--------|
| A1 no hardcoded display data | ✅ all via providers → repository |
| A3 no unfinished paths / dead controls | ✅ grep clean; every control wired |
| A4 fakes only in test/ | ✅ grep "Fake" in lib/ clean |
| A5 ranking engine real | ✅ asserted in domain tests |
| B1–B10 features proven by tests | ✅ repo persist/restart, parsers, search/home widget, integration loop |
| C custom theme (mint, Hanken) | ✅ `lib/theme`; D4 assertion test passes |
| D3 integration_test core loop | ✅ search→add→duel→library→stats→share green |
| D5 committed goldens | ✅ 11 PNGs in `app/test/golden/` (dark+light + IG card) |
| D6 RUN.md | ✅ written |
| secret-leak grep | ✅ returns nothing |

## What changed this run

- `lib/theme/` (tokens + ThemeData, dark+light, mint accent, Hanken/Pretendard bundled).
- Signature widgets: ScoreRing, CoverArt, FloatingNav, FilterChips.
- `LibraryRepository` over Drift = single source of truth; duels persist + survive restart.
- Real API impls (Spotify/iTunes/Last.fm/MusicBrainz); fakes moved to `test/fakes/`.
- Every screen rewritten to the design system + wired (no dead controls).
- `dev_seed.dart` (kDevSeed) seeds the real data layer.
- Tests: theme, repository persistence, API parsers, search/home widgets,
  integration core loop, golden screens. `.sqlfluff` config; migrations reformatted clean.
- Docs: README design section + RUN.md; DECISIONS/BLOCKERS/MORNING/IDEAS updated.

## Milestone history (tags)

M0 scaffold · M1 ranking engine · M2 auth+sync · M3 catalog+tags · M4 spotify ·
M5 library+stats · M6 share+web · M7 OSS polish — tags `m0`–`m7`.

## Next (human, see MORNING-CHECKLIST)

Supabase `db reset` (Docker), deploy edge functions with secrets, register Spotify
+ Last.fm keys, Vercel deploy, physical-device flow test.
