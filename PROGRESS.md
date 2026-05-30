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
| 3. `flutter build apk --debug` | ✅ exit 0 | "✓ Built build/app/outputs/flutter-apk/app-debug.apk" (openjdk@17 + Android SDK 35, 290s) |
| 4. `flutter build web` | ✅ exit 0 | background build completed |
| 5. `npm ci && npm run build` (web) | ✅ exit 0 | background build completed |
| 6. SQL sqlfluff clean + RLS + view + edge fns | ✅ | sqlfluff exit 0; 5 tables RLS; `public_profiles`; 2 edge fns |
| 7. No secrets + complete `.env.example` | ✅ | secret-leak grep returns nothing |
| 8. Docs complete | ✅ | README, LICENSE, CONTRIBUTING, SETUP, SPOTIFY, TAGS, ARCHITECTURE, RUN |
| 9. PROGRESS/DECISIONS/BLOCKERS/MORNING/IDEAS | ✅ | all present + updated |
| 10. Commit history + milestone tags | ✅ | conventional commits; tags m0–m7 |

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

## Deployment prep (2026-05-31)

- Hid the unstable image-share entry point from the Profile UI while keeping the route/code intact for later repair.
- Switched initial public profile URL references to `https://athens.vercel.app` and added matching Next metadata.
- Added Vercel alias `athens.vercel.app` and deployed production `web-co5nu0x24-junwoo-hong-s-projects.vercel.app`.
- Fresh checks: `cd web && npm run build` ✅, `cd app && flutter analyze` ✅, `cd app && flutter test` ✅, live `https://athens.vercel.app` 200 ✅, `/u/unknown` 404 ✅.

## Flutter web production deploy (2026-05-31)

- Built Flutter web with hosted client config: `cd app && flutter build web --dart-define-from-file=config/app_config.json`.
- Created Vercel project `athens`, disabled SSO deployment protection, and deployed the Flutter static bundle.
- Repointed `https://athens.vercel.app` to `athens-mrgnkmvds-junwoo-hong-s-projects.vercel.app`.
- Fresh checks: live root 200 ✅, root serves `flutter_bootstrap.js` ✅, manifest is Athens-specific ✅, `cd app && flutter analyze` ✅.

## Single unified web app — DONE (2026-05-31)

**Goal met:** ONE stable website (`web` Next.js project) now serves the Flutter app
AND the public profile view. `athens.vercel.app` aliased to it. Decision + rationale
in DECISIONS.md → "Web deployment — single unified site".

**Layout (live):** `/` = landing · `/u/[handle]` = SSR profile · `/app/*` = Flutter
web (static in `web/public/app/`, hash routing → no deep-link rewrites).

**Done:**
1. [x] `web/next.config.ts` — rewrite `/app` → `/app/index.html`.
2. [x] Real landing `web/app/page.tsx` (mint tokens, hero + feature grid + CTA→/app).
3. [x] `profile_view.tsx` footer → `/app`; Flutter `og:url` → `/app`.
4. [x] `web/.gitignore` ignores `/public/app`; `web/.vercelignore` ships it on deploy.
5. [x] Makefile `web-flutter` / `web-build` / `web-deploy` pipeline.
6. [x] Retired old `app/web/vercel.json` (app-at-root config).

**Deploy gotcha solved:** local `vercel build` inlines empty NEXT_PUBLIC_* (Production
env vars are sensitive → `vercel pull` returns ""), which 404'd profiles. Fixed by
deploying via **remote build** (`vercel deploy --prod`, real env injected) + a
`.vercelignore` that omits `public/app` so the gitignored Flutter bundle still uploads.

**Fresh live checks (athens.vercel.app, 2026-05-31):**
| Path | Code | Note |
|------|------|------|
| `/` | 200 | landing renders ("앱 시작하기") |
| `/app` | 200 | `<base href="/app/">`, flutter_bootstrap.js |
| `/app/main.dart.js` | 200 | bundle asset |
| `/u/nerdyahh_` | 200 | SSR, real data, `<title>nerdyahh_ — Athens</title>`, `x-matched-path /u/[handle]` |
| `/u/__nope__` | 404 | notFound works |

`cd web && npm run build` ✅ · local `next start` smoke ✅ · `cd app && flutter build web` ✅.

**Cleanup left for human (optional):** the now-orphaned `athens` Vercel project (old
Flutter-only deploy) can be deleted in the dashboard; nothing points to it anymore.

## Rich item info feature — DONE (2026-05-31)

Implemented and deployed the rich item search/detail info feature, resolving the remaining steps from the previous agent.

### Scope completed
- **Facts**: year, album, and duration (mm:ss) rendered dynamically in a row.
- **Last.fm stats**: listener and play count formatted beautifully (e.g. 1.2M, 99K).
- **MusicBrainz proxy**: Deployed `musicbrainz-proxy` to hosted Supabase to avoid CORS blocks on web.
- **Artist details**: Bio summary and a list of popular tracks (tappable to trigger a search).

### Implementation
1. [x] **Render the info on the detail screen**: Created `_InfoSection` inside `item_detail_screen.dart`, fetching metadata reactively on-demand using `itemInfoProvider`.
2. [x] **Deploy Edge Function**: Registered and deployed `musicbrainz-proxy` to Supabase hosted functions (added to Makefile `deploy-functions`).
3. [x] **Tests & Goldens**: Wrote unit tests for Last.fm track/artist/top-tracks and MusicBrainz year parsers. Regenerated golden screens (`item_detail_light` / `item_detail_dark`) to reflect the new layout.
4. [x] **Production Deploy & Alias**: Ran `make web-deploy` to trigger remote build with sensitive env vars on Vercel, then repointed `athens.vercel.app` alias to the new deployment. Smoke-tested all endpoints successfully (200 OK).

## Web app bug fixes (2026-05-31)

Two issues reported after the unified deploy:

1. **Spotify connect on web → "redirect_uri Not matching configuration".**
   Implemented the web PKCE flow (per request to support it on web): web redirect
   URI is the app entry `${origin}/app/`, launched same-tab (`webOnlyWindowName:
   '_self'`); Spotify returns to `/app/?code=…` and `main.dart`'s boot-time
   `handleCallback(Uri.base)` exchanges it (detection now by `?code` presence on
   web, guarded by the stored verifier). Desktop stays gated. `spotify_pkce_service.dart`
   + `spotify_connect_screen.dart`. **Manual step:** register
   `https://athens.vercel.app/app/` in the Spotify dashboard (MORNING-CHECKLIST §2)
   — without it the mismatch persists.

2. **Rated library empty in the app, but present on `/u/<handle>`.** Root cause:
   `LibraryRepository.loadLibrary()` read **only** the local Drift cache; sync was
   push-only. A fresh web browser has an empty Drift, so the library looked empty
   even though the ratings were in Supabase (which is what the public profile reads).
   Fix: added a **remote pull**. `SupabaseGateway.getRatingsWithItems()` fetches
   ratings joined with their catalog items; `LibraryRepository.pullRemote()` hydrates
   Drift from it (reconciling on `source:source_id`, last-write-wins so newer local
   edits aren't clobbered); `LibraryController.build()` pulls before loading. This
   also gives real cross-device sync on mobile, not just web.

**Checks:** `flutter analyze` 0 issues ✅ · `flutter test` all pass (added 2 pull
tests: fresh-device hydrate + last-write-wins) ✅ · rebuilt + redeployed; live
`athens.vercel.app` `/`, `/app`, `/app/main.dart.js`, `/u/nerdyahh_` all 200 ✅.
Web login + pull round-trip to be eyeball-confirmed by signing in on the site.
