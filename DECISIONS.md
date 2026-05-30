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

## Package Substitutions
None — all specified packages verified available on pub.dev.
