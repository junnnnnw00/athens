# Athens — Architecture Decisions

## Tech Stack

| Decision | Choice | Reason |
|----------|--------|--------|
| Flutter state | Riverpod | Locked in PROMPT.md |
| Routing | go_router | Locked in PROMPT.md |
| Local cache | Drift (SQLite) | Locked in PROMPT.md |
| Charts | fl_chart | Locked in PROMPT.md |
| Share image | screenshot + share_plus | Locked in PROMPT.md |
| Spotify auth | PKCE, no client secret in app | Security — secret handled by edge function |
| Mood/energy data | Last.fm tags only | Spotify removed audio-features for new apps |
| RYM-style tags | Last.fm crowd tags + MusicBrainz genres | RYM has no public API and forbids scraping |

## API Design

### Spotify Client Credentials
The Spotify app token (Client Credentials) is fetched server-side via a Supabase Edge Function
(`spotify-app-token`). The client never holds `SPOTIFY_CLIENT_SECRET`. The client calls the edge
function which returns a short-lived token for catalog search.

### Tag Pipeline
1. Search item via Spotify (app token) or iTunes fallback
2. Enrich with Last.fm `track.getTopTags` + `artist.getTopTags` (top 10 tags each)
3. Augment with MusicBrainz genres (rate-limited to 1 req/sec)
4. Store merged tag array in `items.tags` (jsonb)
5. Tags are cached — only re-fetch if stale (>7 days)

### Last.fm recent tracks ordering

- `user.getRecentTracks` is treated as the source of truth for recency ordering.
- The home feed must preserve the upstream order from Last.fm rather than
  re-sorting items in the UI, because `nowplaying` entries can lack `date.uts`
  and custom re-sorting can move the current track behind older scrobbles.
- Keep the timestamp on the catalog item for auditing and future debugging, but
  do not use it to override the upstream order in the home feed unless Last.fm
  changes its response shape.

### Elo Score Mapping
`scoreFromElo(elo)` uses a logistic function: `10 / (1 + exp(-(elo - 1000) / 200))`
- elo 1000 → 5.0 (midpoint)
- elo 1400 → ~9.0
- elo 600 → ~1.0

## Design & UI (rebuild)

| Decision | Choice | Reason |
|----------|--------|--------|
| Visual language | DESIGN.md (refined minimalism) **supersedes ACCEPTANCE Part C** | DESIGN.md is the later, authoritative spec (CLAUDE.md source-of-truth #8) |
| Accent | ONE mint (`#74E0A4` dark / `#3DBE6E` light) | DESIGN.md; replaces the earlier pink — album art carries all other colour |
| Type | Hanken Grotesk (display/UI) + Pretendard (Korean) | DESIGN.md; bundled locally in `app/assets/fonts/` for offline + deterministic goldens |
| Modes | Dark default + light | DESIGN.md ships both |
| Nav | 3-item floating pill (Home · Add · Me) | DESIGN.md; Stats/Profile/Share/Spotify reached from app bars + the Me/profile screen |
| UI language | Korean-first strings | Korean target user (C6) |

## Runtime auth config (deploy)

- **Flutter app uses the legacy `anon` JWT (`eyJ…`), NOT the new `sb_publishable_`
  key.** `supabase_flutter` sends the apikey as `Authorization: Bearer`, and the
  non-JWT publishable key fails that check → "Invalid API key" on signup/login. The
  Next.js JS SDK accepts the publishable key fine, so `web/` keeps it; only the
  Flutter `app/config/app_config.json` carries the anon JWT.
- **Email auth: `mailer_autoconfirm = true`** on the hosted project (set via
  Management API). Free-tier default SMTP rate-limits confirmation emails hard
  ("email rate limit exceeded"); autoconfirm skips the email so dev signups work
  instantly. Revisit before real launch (turn back on + real SMTP).

## Data layer (rebuild)

- **`LibraryRepository` over Drift is the single source of truth** the UI renders.
  The old in-memory `ratedItemsProvider` is removed; it is now derived from
  `libraryControllerProvider` (an `AsyncNotifier` that re-reads Drift after every
  mutation). Duels persist and survive restart.
- **Real network impls** (`SpotifyApiHttp`, `ItunesApiHttp`, `LastfmApiHttp`,
  `MusicBrainzApiHttp`) live behind the existing interfaces; the `Fake*` doubles
  moved to `test/fakes/` and are never imported by `lib/` (ACCEPTANCE A4).
- **`dev_seed.dart`** (behind `kDevSeed`, `--dart-define=DEV_SEED=true`) writes real
  rows through the repository — it does not short-circuit the UI.

## Tooling

- **`.sqlfluff`** added (postgres dialect; reference-qualification/aliasing rules
  excluded as stylistic, layout + casing enforced & auto-fixed). Migrations lint clean.
- **Golden tests are tagged `golden`** and excluded in CI (`--exclude-tags golden`)
  because font anti-aliasing differs across platforms; they are the macOS-rendered
  review references and run locally.

## Known environment limit

- `flutter build apk --debug` cannot run on this build machine (no Java runtime /
  Android SDK). The path is unchanged and is built in CI (`ubuntu-latest` +
  `subosito/flutter-action`, which provides the Android SDK). See BLOCKERS.md.

## Web deployment — single unified site (2026-05-31)

**Decision:** Collapse the two separate Vercel projects (`athens` = Flutter web,
`web` = Next.js profiles) into ONE website served by the **Next.js project (`web`)**
as the host shell. URL layout:

| Path | Served by | Notes |
|------|-----------|-------|
| `/` | Next.js (SSR) | Real marketing landing — sign-in CTA into the app |
| `/u/[handle]` | Next.js (SSR) | Public profile. SSR kept for share OG tags + SEO |
| `/app`, `/app/*` | Flutter web (static, in `web/public/app/`) | The full client app |

**Why this layout (chosen over app-at-root / two-projects):**
- Profile pages MUST stay server-rendered so shared links get correct OG/Twitter
  meta + are crawlable. A Flutter SPA cannot do that.
- Putting Flutter under `/app/*` and Next.js at `/` + `/u/*` means **no route
  collision** between the two frameworks → one stable Vercel project, one domain.
- Flutter web uses the **default hash URL strategy** (`main.dart` does NOT call
  `usePathUrlStrategy`), so in-app navigation is `/app/#/home`, `/app/#/duel`, …
  → static hosting needs **no server-side deep-link rewrites** for the app. Only
  `/app` → `/app/index.html` and asset serving are required. Maximally robust.

**Build/deploy pipeline (local CLI, not Git-build):** Vercel's build image has no
Flutter SDK, so the Flutter bundle is built locally and shipped as static assets:
1. `flutter build web --base-href /app/ --dart-define-from-file=config/app_config.json`
2. copy `app/build/web/` → `web/public/app/`
3. `cd web && next build` then `vercel deploy --prod` (CLI, from the linked `web` project)

`web/public/app/` is a build artifact → gitignored, regenerated each deploy. The old
`app/web/vercel.json` (app-at-root rewrites) is retired. Makefile `web-deploy` wraps
the whole pipeline.

## Package Substitutions
None — all specified packages verified available on pub.dev.

## Android distribution — sideload via APK (2026-05-31)

**Decision:** No Play Store yet. Distribute signed APK via GitHub Releases; in-app update check
polls GitHub Releases API.

| Item | Detail |
|------|--------|
| Keystore | `app/android/app/upload-keystore.jks` (JKS, 10,000-day, RSA-2048, alias `athens`) |
| Signing config | `app/android/key.properties` — both files gitignored |
| Release flow | `./release-android.sh <version>` — bumps pubspec, builds APK, `git tag`, GitHub Release |
| In-app update | `UpdateService` (Android only) polls `api.github.com/repos/junnnnnw00/athens/releases/latest` on launch |
| Update UI | `UpdateBanner` slides in on home screen; taps → browser download of `.apk` asset |
| Dependency added | `package_info_plus` for reading the current installed version |

**Why GitHub Releases instead of a custom endpoint:** zero infrastructure cost, integrates with
the existing repo, `gh release create` is one command, and the GitHub API returns structured
release data (tag, assets) without auth for public repos.

## Elo starting points — 5-option initial rating (2026-05-31)

When a user first adds an item (song/album/artist), they pick one of 5 sentiments:

| Option | Starting Elo | Constant |
|--------|-------------|----------|
| 좋았어요! | 1200 | `startingEloGood` |
| 조금 좋아요 | 1100 | `startingEloSlightlyGood` |
| 평범해요 | 1000 | `startingEloAverage` |
| 조금 별로예요 | 900 | `startingEloSlightlyBad` |
| 별로예요 | 800 | `startingEloBad` |

Applies to: search-add, home/recent-add, item detail re-rating.
Existing items migrated +200 Elo (Supabase migration `0009`, local DB schema v2).

## Spotify dev-mode search caps (2026-05-31)

The Spotify app runs in **development mode**, which restricts the Web API in
ways that silently broke catalog search. Verified live against the real app:

| Restriction | Decision |
|---|---|
| `/v1/search` rejects `limit > 10` (HTTP 400 "Invalid limit") | Page size pinned to `kSearchPageSize = 10`; fetch more via `offset` paging (cap 1000), never a larger limit |
| `/v1/artists?ids=` (bulk metadata) + audio-features/recommendations/related forbidden | Removed `fetchArtistImages`/`_enrichArtistImages`; artist images taken straight from the `/search` artist payload |
| Token endpoint hammered → 429 | Cache the Client-Credentials token both in the edge function (module scope) and client-side (`SpotifyApiHttp`, ~1h) |
| `market` filter | **Removed** — `market=KR` drops tracks unlicensed in-market, shrinking coverage ("song exists but doesn't show"). Search relevance is fine without it for a rating (non-playback) app |

**Why it matters:** any `limit>10` made every Spotify search 400 → silent
iTunes fallback (poorer coverage, NO artist artwork). That was the dominant
cause of "results cap out / no artist photos", above the 429s. If Spotify grants
**extended quota mode** later, the limit and bulk-endpoint caps lift.

## Web deployment — framework + env must be pinned (2026-05-31)

The `athens` Vercel project had `framework: null` and ZERO env vars, so:
- It served only the static `public/` dir and 404'd all Next routes (`/`,
  `/u/[handle]`); the Flutter bundle at `/app` masked the breakage.
- `NEXT_PUBLIC_SUPABASE_*` were empty → every public profile `notFound()`.

**Decision:** pin `framework: nextjs` in `web/vercel.json` (committed,
reversible, overrides dashboard drift), and keep `NEXT_PUBLIC_SUPABASE_URL` +
`NEXT_PUBLIC_SUPABASE_ANON_KEY` (the **publishable** key — public, safe in the
browser) set on the Vercel project for prod+preview+dev. These are config, not
secrets, so they stay out of the repo but must exist on the project.

## Proposal: Environment Separation for Public & Development Channels (2026-06-01)

### 1. Git Branching & Deployments
* **`main` Branch (Production):** Keeps public stable version. Connected to production database, deployed to `https://athens.vercel.app`.
* **`dev` Branch (Development/Staging):** Sandbox for new features (Premium, backer activation). Connected to development database, deployed to Vercel preview environments.

### 2. Database/Backend (Supabase)
* **Production Project:** The current hosted project (`hgehnwruprjoeewrhbgg`).
* **Development Project:** 
  * Local Docker stack (`supabase start`) for local testing.
  * *Optionally:* A separate hosted Supabase project (e.g., `athens-dev`) for Vercel preview deployments and TestFlight builds.

### 3. Flutter Configuration Separation
* Rename/add configurations:
  * Production config: `app/config/app_config_prod.json` (or keep `app_config.json` as default).
  * Development config: `app/config/app_config_dev.json`.
* Update `Makefile` to allow running or building with specific environment files (e.g., `make run` runs prod config, `make run-dev` runs dev config).

### 4. Spotify Developer App Integration
* Register a separate Spotify Developer App for development.
  * Development Redirect URI: `athens-dev://spotify-callback` and `http://127.0.0.1:8888/callback`.
  * Allows keeping production users and dev testing accounts completely isolated.


---

## Admin / Developer Dashboard (web `/admin/<secret>`)

* **What:** server-rendered Next.js page showing aggregate stats
  (유저/성장 + 참여도). No per-user PII beyond handles already public via
  `public_profiles`.
* **Hidden URL:** route is `app/admin/[gate]`. Real entrance is
  `/admin/<ADMIN_PATH_SECRET>`; bare `/admin` and any wrong segment return a real
  404 (no page exists / `notFound()`) so it isn't discoverable by guessing
  `/admin`. Defense-in-depth on top of the password.
* **Data access:** Supabase `service_role` key, read **server-only**
  (`web/app/admin/stats.ts`, guarded by `import 'server-only'`). Bypasses RLS to
  count all rows. Key is NOT exposed to the browser and NOT bundled in Flutter.
* **Auth gate:** single shared password `ADMIN_DASHBOARD_PASSWORD`. Cookie stores
  `sha256(password)` (httpOnly, secure, sameSite=lax, path=/admin, 12h). Plaintext
  never leaves the server. Fail-closed if the env var is unset.
* **Reversible:** delete `web/app/admin/` + the two env vars. No schema/RLS change.
* **Required env (set in Vercel project + `web/.env.local`, never commit):**
  `SUPABASE_SERVICE_ROLE_KEY`, `ADMIN_DASHBOARD_PASSWORD`, `ADMIN_PATH_SECRET`
  (long random slug — the hidden path).
