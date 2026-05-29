# Crate — Build Progress

## Status

| Milestone | Status | Notes |
|-----------|--------|-------|
| M0 Scaffold | ✅ Complete | Flutter + Next.js + CI + docs |
| M1 Ranking Engine | ✅ Complete | 49 tests, 97.8% domain coverage |
| M2 Auth + Sync | ✅ Complete | Supabase Auth + Drift + FakeGateway |
| M3 Catalog + Tags | ✅ Complete | Spotify/iTunes/Last.fm/MusicBrainz interfaces + Fakes |
| M4 Spotify Connect | ✅ Complete | PKCE stub + allow-list gate |
| M5 Library + Stats | ✅ Complete | fl_chart score distribution + tags |
| M6 Share + Web | ✅ Complete | Next.js /u/[handle] + IG card templates |
| M7 OSS Polish | ✅ Complete | Docs, MORNING-CHECKLIST, CI |

## DoD Check Results

| Check | Result | Notes |
|-------|--------|-------|
| `flutter analyze` | ✅ 0 issues | |
| `flutter test` | ✅ 49 pass | |
| Domain coverage ≥90% | ✅ 97.8% | 90/92 lines |
| `flutter build apk --debug` | ⚠️ Blocked | No Android SDK on build machine — see BLOCKERS.md |
| `flutter build web` | ✅ Succeeded | Built to app/build/web |
| `npm ci && npm run build` (web) | ✅ Succeeded | Next.js build clean |
| SQL migrations lint | ⚠️ Unverified | Requires Supabase CLI + Docker — see MORNING-CHECKLIST.md |
| RLS on all tables | ✅ Written | In 0001_initial_schema.sql |
| Public view exists | ✅ Written | In 0002_public_view.sql |
| Edge functions present | ✅ Written | spotify-app-token + lastfm-proxy |
| No secrets committed | ✅ | .env in .gitignore |
| .env.example complete | ✅ | All keys documented |
| README complete | ✅ | |
| LICENSE (MIT) | ✅ | |
| CONTRIBUTING complete | ✅ | |
| docs/SETUP.md | ✅ | |
| docs/SPOTIFY.md | ✅ | |
| docs/TAGS.md | ✅ | |
| PROGRESS.md | ✅ | This file |
| DECISIONS.md | ✅ | |
| BLOCKERS.md | ✅ | Android SDK noted |
| MORNING-CHECKLIST.md | ✅ | 10 manual steps documented |

## M0 — Scaffold

**Completed:** 2026-05-29

- Initialized git repo with comprehensive .gitignore (protects .env)
- Created Flutter app (`flutter create`) with Riverpod + go_router + Drift + fl_chart + screenshot + share_plus
- Created Next.js 16 app (App Router + TypeScript) at /web
- GitHub Actions CI: flutter analyze + test + build web; next build
- Root docs: README.md, LICENSE (MIT), CONTRIBUTING.md, .env.example (all keys)
- Stub docs: docs/SETUP.md, docs/SPOTIFY.md, docs/TAGS.md, docs/ARCHITECTURE.md
- Tracking files: PROGRESS.md, DECISIONS.md, BLOCKERS.md, MORNING-CHECKLIST.md

## M1 — Ranking Engine

**Completed:** 2026-05-29

**Files:** `app/lib/domain/` (4 files), `app/test/domain/` (4 test files)

- `elo.dart`: `expected(a,b)` (logistic) + `update(winner, loser, k=32)` returning `(double, double)` record
- `score.dart`: `scoreFromElo(elo)` = `10 / (1 + exp(-(elo-1000)/200))` → maps 1000→5.0
- `pair_selector.dart`: Selects fewest-comparisons pivot from bottom 20%, nearest-elo opponent
- `stats_engine.dart`: totals by kind, avg score, score buckets (10), top-N, genre+mood tag counts, activity by day
- **Coverage:** 97.8% (90/92 domain lines). All 33 domain tests pass.
- **Key decision:** Mood tags identified by keyword set (melancholic, dreamy, etc.); genre is default

## M2 — Auth + Sync

**Completed:** 2026-05-29

- `app/lib/features/auth/auth_screen.dart`: Email sign-in/sign-up via Supabase Auth
- `app/lib/data/local/app_database.dart`: Drift database (LocalItems, LocalRatings, LocalComparisons, LocalReviews)
- `app/lib/data/remote/supabase_gateway.dart`: Abstract gateway + FakeSupabaseGateway (in-memory)
- `app/lib/data/sync/sync_service.dart`: upload local → gateway; download remote; last-write-wins
- `app/test/sync/sync_service_test.dart`: 6 tests covering sync, compare, reviews, profiles
- `supabase/migrations/0001_initial_schema.sql`: All 5 tables + RLS + handle auto-create trigger
- `supabase/migrations/0002_public_view.sql`: `public_profiles` security-definer view (anon readable)

## M3 — Catalog + Tags

**Completed:** 2026-05-29

- `app/lib/api/`: SpotifyApi, ItunesApi, LastfmApi, MusicBrainzApi interfaces + Fake impls
- `app/lib/features/catalog/catalog_service.dart`: Search (Spotify→iTunes fallback) + enrichTags (Last.fm+MusicBrainz)
- `app/test/catalog/catalog_service_test.dart`: 8 tests — fallback, empty query, graceful API failures
- `supabase/functions/spotify-app-token/`: Edge function for Client Credentials token (keeps secret server-side)
- `supabase/functions/lastfm-proxy/`: Edge function proxying Last.fm tag calls

## M4 — Spotify Connect + Home Prompts

**Completed:** 2026-05-29

- `app/lib/features/spotify_connect/spotify_connect_screen.dart`: Gate on `spotify_enabled` profile flag
  - Enabled: shows PKCE OAuth stub with snackbar (requires real `SPOTIFY_CLIENT_ID` on device)
  - Disabled: shows informational "invite-only" message (not blank, not error)
- `app/lib/features/home/home_screen.dart`: Shows recently-played cards (from SpotifyApi) or empty state

## M5 — Library + Stats

**Completed:** 2026-05-29

- `app/lib/features/library/library_screen.dart`: Ranked list sorted by score; shows comparisons count
- `app/lib/features/stats/stats_screen.dart`: fl_chart bar chart (score distribution), top genres/moods bars, activity line chart
- `app/lib/features/rank/duel_screen.dart`: Head-to-head duel UI using DuelNotifier (StateNotifier + PairSelector + Elo)

## M6 — Share + Web Profile

**Completed:** 2026-05-29

- `web/app/u/[handle]/page.tsx`: Server-side profile page reading `public_profiles` view via Supabase anon key
  - Shows avatar, handle, bio, stats (total rated, avg score, total duels), top-10 items with tags
  - `generateMetadata` for SEO
- `app/lib/features/share/share_screen.dart`: Two templates rendered at 1080×1920 via RepaintBoundary
  - **Top 5**: dark gradient with top-5 items + scores
  - **Taste Snapshot**: tag chips + item count, different gradient
  - Shares via `share_plus` (XFile PNG)

## M7 — OSS Polish

**Completed:** 2026-05-29

- All docs finalized (SETUP.md, SPOTIFY.md, TAGS.md, ARCHITECTURE.md)
- MORNING-CHECKLIST.md: 10 steps covering Supabase, Spotify, Last.fm, MusicBrainz, Vercel, device testing, CI
- CI verified: flutter analyze 0 issues, flutter test 49/49 pass, next build clean
- DECISIONS.md: all major architecture choices documented
- BLOCKERS.md: Android SDK blocker documented + CI workaround noted
