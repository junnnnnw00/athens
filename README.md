# Athens

**Athens** is an open-source music rating app built around a pairwise "which do you prefer?" mini-game that converts head-to-head choices into per-user 0–10 scores and ranked lists.

Rate tracks, albums, and artists. Get deep genre + mood tags (powered by Last.fm + MusicBrainz). Optionally connect your Last.fm account to surface what you've actually been listening to. Share your taste with a public profile page.

**One official hosted instance** — sign up at the hosted service. Source code is MIT-licensed and open to contributions.

---

## Features

- **Pairwise ranking** — head-to-head duels → Elo scores → 0–10 ratings
- **Deep tags** — genre + mood tags from Last.fm crowd tags + MusicBrainz (RYM-spirit, sourced legally)
- **Last.fm connect** (optional) — surface your recently-played → rate what you listen to
- **Cross-device sync** — Supabase Realtime, offline-first with local Drift cache
- **Public profile** — shareable web page at `/u/[handle]`
- **Public sharing** — copy a public profile link at `https://athens.vercel.app/u/[handle]`

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile app | Flutter (Riverpod, go_router, Drift) |
| Backend | Supabase (Postgres + Auth + Realtime + RLS) |
| Catalog search | iTunes Search API (client-direct, per-user IP) |
| Tags | Last.fm + MusicBrainz (via cached, rate-limited edge proxies) |
| Listening history | Last.fm per-user connect (optional) |
| Public web | Next.js App Router (Vercel) |
| Share image | Temporarily hidden in the app UI |
| Charts | `fl_chart` |

## Design

Refined-minimalist, content-first: true-black dark (and warm-grey light) canvas,
**one mint accent**, heavy Hanken Grotesk display type with Pretendard for Korean,
and a signature circular **score ring**. See **[DESIGN.md](DESIGN.md)**. Reference
screens (dark + light) are committed under `app/test/golden/`.

## Quick Start

See **[docs/SETUP.md](docs/SETUP.md)** for full setup, and **[RUN.md](RUN.md)** to
launch and verify each screen in 5 minutes (incl. `--dart-define=DEV_SEED=true`
for instant sample data).

```bash
# Clone
git clone https://github.com/YOUR_HANDLE/athens.git
cd athens

# Configure environment
cp .env.example .env
# Fill in your Supabase, Spotify, and Last.fm credentials

# Flutter app
cd app
flutter pub get
flutter run

# Web profile
cd web
npm ci
npm run dev
```

## Project Structure

```
/app        Flutter client (Android + iOS + Web)
/web        Next.js public-profile site (/u/[handle])
/supabase   Migrations, seed, edge functions
/docs       SETUP.md, SPOTIFY.md, TAGS.md, ARCHITECTURE.md
```

## Accounts & listening history

Login is **Supabase Auth** (email + Google/Apple OAuth) — never Spotify. Listening
history is an **optional Last.fm connect**: link your Last.fm username to surface
your recently-played tracks for rating. Everyone can use the full app without it.

Catalog search hits the **iTunes Search API directly from the client** (per-user
IP, no shared bottleneck). Genre/mood tags come from **Last.fm + MusicBrainz**
through server-side edge proxies that are cached + rate-limited (see
[DECISIONS.md](DECISIONS.md)). Secrets live only in edge functions — never in the
client.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Issues and PRs welcome.

## License

[MIT](LICENSE)
