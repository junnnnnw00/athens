# Athens — Architecture

## Overview

Athens is a single centralized hosted service. One Supabase project serves all users, isolated by Row Level Security. The mobile app (Flutter) talks directly to Supabase and to edge functions for external API calls. The web profile (Next.js) reads from Supabase via the anon key.

## Monorepo Layout

```
/app        Flutter client
  lib/
    domain/           Pure Dart: Elo, scoreFromElo, PairSelector, StatsEngine
    features/
      auth/           Supabase Auth (email + Google/Apple OAuth)
      catalog/        Search + metadata + tag enrichment
      rank/           Duel UI (pairwise comparison)
      library/        Ranked list + item detail
      home/           Recently-played prompts (Spotify, allow-listed)
      reviews/        Per-item text reviews
      stats/          StatsEngine UI (fl_chart)
      share/          IG card export + web link
      profile/        Public/private profile management
      spotify_connect/ PKCE OAuth flow (allow-listed users)
    data/
      local/          Drift database (SQLite, offline cache)
      remote/         Supabase gateway interface + impl
      sync/           Bidirectional sync (local → push → realtime pull)
    api/              External API interfaces + Fake implementations
    router.dart       go_router configuration
    main.dart

/web        Next.js App Router
  app/
    u/[handle]/       Public profile page (anon Supabase read)
    layout.tsx
    page.tsx

/supabase
  migrations/         Numbered SQL files (000x_*.sql)
  functions/
    spotify-app-token/ Fetch Client Credentials app token (keeps secret server-side)
    lastfm-proxy/      Proxy Last.fm tag calls (keeps API key server-side)
  seed.sql

/docs
  SETUP.md            Full setup guide
  SPOTIFY.md          Spotify integration details
  TAGS.md             Tag pipeline (Last.fm + MusicBrainz)
  ARCHITECTURE.md     This file
```

## Data Flow

### Catalog Search + Tag Enrichment

```
User searches → CatalogService
  → spotify-app-token edge fn → Spotify /search
  → (fallback) iTunes Search API
  → LastfmApi.getTopTags(track) + LastfmApi.getTopTags(artist)
  → MusicBrainzApi.getGenres(mbid)  [≤1 req/sec]
  → merge tags → store in items.tags (jsonb)
  → cache in Drift local DB
```

### Rating / Duel

```
User picks winner in duel → PairSelector.next()
  → Elo.update(winner, loser, k=32)
  → scoreFromElo(elo) → 0-10 score
  → write to Drift local DB
  → sync → Supabase (ratings + comparisons tables)
  → Realtime update → other devices
```

### Spotify Recently Played (allow-listed users only)

```
User has spotify_enabled = true
  → PKCE OAuth → Spotify access token → flutter_secure_storage
  → GET /me/player/recently-played
  → diff vs already-rated items
  → surface unrated items as "rate this" cards on HomeScreen
```

## Security

- `SPOTIFY_CLIENT_SECRET` — edge function environment only, never in Flutter app
- `LASTFM_API_KEY` — edge function environment only (via lastfm-proxy)
- `SUPABASE_SECRET_KEY` — edge function environment only
- Spotify user OAuth tokens — `flutter_secure_storage` on device, never sent to backend
- RLS on every Supabase table — users can only read/write their own data
- Public profiles — only `is_public = true` profiles exposed via `security definer` view

## Elo Score Mapping

`scoreFromElo(elo) = 10 / (1 + exp(-(elo - 1000) / 200))`

- elo 600 → ~1.0
- elo 1000 → 5.0 (starting / midpoint)
- elo 1400 → ~9.0

K-factor = 32 (standard chess beginner). Higher K means faster convergence (appropriate for music taste which changes over time).
