# Athens — Overnight Build Prompt (Claude Code + OMC)

> 사용법: 새 빈 폴더에 이 파일을 `PROMPT.md`로 저장 → 그 폴더에서 Claude Code 실행 →
> 아래 "HOW TO RUN"의 OMC `/ralph` 명령으로 자율 실행.
> 본문은 영어 (오픈소스 레포 + 에이전트 정확도). `Athens`는 가칭이니 자유롭게 rename ("Podiums"는 실제 앱 이름이라 사용 금지).

---

## GOAL

Build **Athens**: an open-source, **single centralized hosted service** (one Supabase backend that
anyone can sign up for) whose source code is MIT-licensed and open to contributions. Its core
interaction is a **pairwise "which do you prefer?" mini-game** that converts head-to-head choices
into a per-user 0–10 score and a ranked list. Users rate tracks/albums/artists, see deep
genre + mood tags (RYM-spirit, sourced legally), get prompted to rate music they recently listened
to (Spotify, for a small allow-listed set of users), sync ratings + reviews across their devices,
and share a public profile page (web) + an Instagram-story image with personal stats.

This run must produce a **clean, compiling, fully-tested codebase with complete docs and OSS
scaffolding** — not a half-finished pile. Anything requiring my real credentials or a physical
device must be **stubbed/mocked and listed in `MORNING-CHECKLIST.md`** — do NOT stop the run on it.

---

## PRODUCT MODEL (read carefully — this drives the auth design)

- **One official hosted instance.** Many users on one Supabase project, isolated by Row Level Security. Public profiles are shareable. NOT a per-user self-hosted model.
- **Login = Supabase Auth** (email + Google/Apple OAuth). **Login must NOT depend on Spotify**, because Spotify Development Mode caps an app at 5 authorizing users — gating login on Spotify would cap the whole service at 5. Keep auth Spotify-independent so the service scales.
- **Spotify is an *optional per-user connection*, not the login.** Only users on an allow-list (me + a few friends, ≤5 total — the Spotify dev-mode cap) can connect Spotify to import listening history. Everyone else uses the app fully without Spotify.

---

## DATA SOURCES (what comes from where, and the hard constraints)

| Need | Source | Notes / constraints |
| --- | --- | --- |
| Catalog search + basic metadata + cover art | **Spotify app token (Client Credentials)** first, **iTunes Search API** as fallback | Client Credentials is app-level, not user-capped. BUT dev-mode may restrict some public data — **verify at build time; fall back to iTunes (no auth, has artwork) gracefully.** |
| Deep genre + mood tags (the RYM feel) | **Last.fm** (`track.getTopTags`, `artist.getTopTags`) + **MusicBrainz** genres/tags | Last.fm crowd tags ≈ RYM descriptors (shoegaze, dreamy, melancholic…). API key + User-Agent. MusicBrainz: **max 1 req/sec, meaningful User-Agent**. Covers via **Cover Art Archive**. |
| Recently-listened → "rate this" prompt | **Spotify `GET /me/player/recently-played`** | User-auth → counts against the 5-user cap → **allow-listed users only**. Optional alt: Last.fm `user.getRecentTracks` for users who scrobble. |
| Auth / sync / public profile | **Supabase** (Postgres + Auth + Realtime + RLS) | The official backend. |

**HARD "DO NOT USE" (Spotify removed these — not a cap issue, they 403 for new apps):**
`audio-features`, `audio-analysis`, `recommendations`, `related-artists`, `new-releases`,
artist top-tracks, track available-markets, bulk multi-ID metadata, other users' profiles,
artist followers/popularity, album label. **There is no "mood/energy/danceability" from Spotify** —
mood comes from Last.fm tags instead.

**DO NOT scrape RateYourMusic.** RYM has no public API and explicitly forbids scraping (Cloudflare-blocked, IP/account bans). You may *adopt an open community genre-tree taxonomy* for organizing tags, but never fetch from rateyourmusic.com.

---

## LOCKED TECH DECISIONS (do not re-litigate — build)

- **Client:** Flutter (stable), Dart. State: **Riverpod**. Routing: **go_router**.
- **Backend:** **Supabase** (Postgres + Auth + Realtime + RLS).
- **Local cache (offline-first):** **Drift** (SQLite). Sync: local write → push → realtime pull; last-write-wins.
- **Spotify connect:** OAuth **Authorization Code + PKCE** (NO client secret in app); tokens in `flutter_secure_storage`. App-token (Client Credentials) handled server-side via a **Supabase Edge Function** so the client never holds the Spotify client secret.
- **External APIs behind interfaces** (`SpotifyApi`, `LastfmApi`, `MusicBrainzApi`, `ItunesApi`) each with a **Fake** impl used in tests. No real network in tests.
- **Charts:** `fl_chart`. **Share image:** `screenshot` (RepaintBoundary→PNG 1080×1920) + `share_plus`.
- **Public web page:** **Next.js (App Router)**, reads the Supabase public view via anon key. Route `/u/[handle]`. Deploy target: Vercel.
- **CI:** GitHub Actions (flutter analyze + test; next build). **License:** MIT. Repo docs/comments: English.

If a package is unavailable/broken, pick the closest maintained equivalent and log it in `DECISIONS.md`.

---

## ARCHITECTURE (monorepo)

```
/app        Flutter client (android + ios + web)
/web        Next.js public-profile site
/supabase   migrations/*.sql, seed.sql, functions/ (edge: spotify-app-token, lastfm-proxy)
/docs       SETUP.md, SPOTIFY.md, TAGS.md (lastfm/musicbrainz), ARCHITECTURE.md
PROMPT.md PROGRESS.md DECISIONS.md BLOCKERS.md MORNING-CHECKLIST.md
README.md LICENSE CONTRIBUTING.md .env.example
```

Flutter modules: `auth`, `catalog` (search + item cache + tag enrichment), `rank` (duel engine),
`library` (ranked list), `home` (recently-played prompts, allow-listed), `reviews`, `stats`,
`share` (web link + IG card), `profile`, `spotify_connect`.

Pure-Dart domain (no Flutter/IO; fully unit-tested):
- `Elo`: `expected(a,b)`, `update(winner, loser, k=32)`.
- `scoreFromElo(elo)`: logistic map to 0–10 (elo 1000 → 5.0).
- `PairSelector`: fewest-comparisons item × nearest-rating opponent, with randomness.
- `StatsEngine`: totals by kind, avg score, score-distribution buckets, top-N, **tag/genre & mood breakdown** (from cached tags), activity over time.

---

## DATA MODEL (Supabase / Postgres)

- `profiles` (id uuid pk = auth.users.id, handle citext unique, display_name, avatar_url, bio, is_public bool default false, **spotify_enabled bool default false** (allow-list flag), spotify_user_id, created_at)
- `items` (id uuid pk, kind text check in ('track','album','artist'), source text, source_id text, title, primary_artist, image_url, **tags jsonb** (genre+mood from lastfm/mb), metadata jsonb, created_at, unique(source, source_id)) — shared catalog cache
- `ratings` (id uuid pk, user_id fk, item_id fk, elo numeric default 1000, comparisons int default 0, score numeric, updated_at, unique(user_id, item_id))
- `comparisons` (id uuid pk, user_id, winner_item_id, loser_item_id, created_at)
- `reviews` (id uuid pk, user_id, item_id, body text, rating_snapshot numeric, updated_at, unique(user_id, item_id))

**RLS:**
- `ratings`/`comparisons`/`reviews`: full CRUD only where `auth.uid() = user_id`.
- `items`: select for all authenticated; insert/update by any authenticated (shared cache).
- `profiles`: select where `is_public = true OR auth.uid() = id`; update only own row.
- **Public sharing:** a `security definer` view exposing, for `is_public = true` profiles, ranked items + computed stats, readable by anon. Private profiles expose nothing.
- Migrations lint clean (`sqlfluff`); if supabase CLI + Docker present, `supabase db reset` must succeed, else note unverified in BLOCKERS.

---

## MILESTONES (commit + update PROGRESS.md after each)

- **M0 Scaffold:** monorepo, Flutter + Next.js init, Riverpod/go_router, lint, CI, README/LICENSE/CONTRIBUTING/.env.example, empty docs.
- **M1 Ranking engine (do first, do well):** pure-Dart Elo + score map + pair selector + StatsEngine, **≥90% line coverage** unit tests.
- **M2 Auth + sync:** Supabase migrations + RLS; Supabase Auth (email + Google/Apple); Drift cache; bidirectional sync tested against a FakeSupabase gateway; cross-device consistency test.
- **M3 Catalog + tags:** `CatalogService` = Spotify-app-token search (edge fn) with iTunes fallback; enrich items with Last.fm + MusicBrainz tags (genre+mood) into `items.tags`; cache to `items`. All behind interfaces with Fakes; no network in tests.
- **M4 Spotify connect + home prompts:** PKCE connect flow gated by `profiles.spotify_enabled`; pull `recently-played`; diff vs rated; surface unrated as "rate this" cards. Non-enabled users see a graceful empty/alt state.
- **M5 Library + stats:** ranked list, item detail with tags, reviews, stats screen (fl_chart: score distribution, top genres/moods, activity).
- **M6 Share:** Next.js `/u/[handle]` reading the public view; IG-story PNG export (1080×1920), ≥2 templates ("Top 5" + "Taste Snapshot" with top tags).
- **M7 OSS polish:** finalize README, docs/SETUP.md + SPOTIFY.md + TAGS.md, contribution guide, CI green, write MORNING-CHECKLIST.md.

---

## DEFINITION OF DONE (all must pass — autonomously verifiable)

1. `cd app && flutter analyze` → 0 issues.
2. `cd app && flutter test` → all pass; `rank` domain coverage ≥ 90%.
3. `cd app && flutter build apk --debug` → succeeds.
4. `cd app && flutter build web` → succeeds.
5. `cd web && npm ci && npm run build` → succeeds.
6. SQL migrations lint clean; RLS on every table; public view exists; edge functions present.
7. No secrets committed; complete `.env.example`.
8. README, LICENSE (MIT), CONTRIBUTING, docs/SETUP.md, docs/SPOTIFY.md, docs/TAGS.md complete.
9. PROGRESS.md, DECISIONS.md, BLOCKERS.md, MORNING-CHECKLIST.md written.
10. Clean commit history, ≥1 commit per milestone, conventional commit messages.

---

## WHAT YOU CANNOT DO (stub + document in MORNING-CHECKLIST — never block)

- Create my Spotify app, Supabase project, Last.fm API account, or obtain real keys → `.env.example` placeholders + step-by-step docs.
- Run real end-to-end Spotify/Supabase OAuth or test on a physical device → mocked/widget tests + manual steps in MORNING-CHECKLIST.
- Verify dev-mode Client-Credentials catalog access without my keys → implement Spotify path + iTunes fallback, leave a TODO note to confirm.
- Anything ambiguous → reasonable default, record in DECISIONS.md, keep moving.

---

## EXECUTION RULES

- Work M0→M7 in order. After each: run relevant DoD checks, commit, append PROGRESS.md.
- Many small verified steps over big unverified leaps; if a check fails, fix before advancing (ralph verify/fix loop).
- All external APIs behind interfaces with fakes; tests never hit the network.
- If blocked, write the blocker + the stub you left to BLOCKERS.md and move to the next independent task. Never idle.
- Do not mark DONE until every Definition-of-Done item passes.

---

## HOW TO RUN (OMC, in the project folder)

```bash
# 0. before sleeping: rate-limit auto-resume + a completion ping
omc wait --start
omc config-stop-callback telegram --enable --token <bot_token> --chat <chat_id> --tag-list "@me"
#    (discord/slack also supported)

# 1. start Claude Code in the folder, then:
/ralph "Implement the project defined in PROMPT.md all the way to its Definition of Done. Work milestone by milestone (M0→M7), run the DoD checks after each, commit per milestone, update PROGRESS.md, and do not stop until every Definition-of-Done item passes. Stub anything under 'WHAT YOU CANNOT DO' and record it in MORNING-CHECKLIST.md instead of blocking."
```

Optional: `/ralplan "review PROMPT.md and produce the execution plan"` first to sanity-check, then `/ralph ...`.
For an unattended overnight run, `/ralph` alone is enough.
