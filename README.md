# Athens

**Athens** is an open-source music rating app built around a pairwise "which do you prefer?" mini-game that converts head-to-head choices into per-user 0–10 scores and ranked lists.

Rate tracks, albums, and artists. Get deep genre + mood tags (powered by Last.fm + MusicBrainz). Optionally connect Spotify to rate music you've actually been listening to. Share your taste with a public profile page and Instagram-story image.

**One official hosted instance** — sign up at the hosted service. Source code is MIT-licensed and open to contributions.

---

## Features

- **Pairwise ranking** — head-to-head duels → Elo scores → 0–10 ratings
- **Deep tags** — genre + mood tags from Last.fm crowd tags + MusicBrainz (RYM-spirit, sourced legally)
- **Spotify integration** (optional, allow-listed) — import recently-played → rate what you listen to
- **Cross-device sync** — Supabase Realtime, offline-first with local Drift cache
- **Public profile** — shareable web page at `/u/[handle]`
- **IG Story export** — 1080×1920 PNG with "Top 5" or "Taste Snapshot" template

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile app | Flutter (Riverpod, go_router, Drift) |
| Backend | Supabase (Postgres + Auth + Realtime + RLS) |
| Catalog | Spotify Client Credentials (app token) + iTunes fallback |
| Tags | Last.fm + MusicBrainz |
| Public web | Next.js App Router (Vercel) |
| Share image | `screenshot` + `share_plus` |
| Charts | `fl_chart` |

## Quick Start

See **[docs/SETUP.md](docs/SETUP.md)** for full setup instructions.

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

## Spotify Note

Spotify is an **optional per-user connection** — login uses Supabase Auth (email + Google/Apple OAuth). Only allow-listed users (≤5, due to Spotify Dev Mode cap) can connect Spotify to import listening history. Everyone else uses the app fully.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Issues and PRs welcome.

## License

[MIT](LICENSE)
