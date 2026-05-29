# Athens — Spotify Integration

## Overview

Spotify serves two roles in Athens:

1. **Catalog search** (all users) — app-level Client Credentials token, fetched server-side
2. **Recently-played import** (allow-listed users only) — user OAuth via PKCE

These are deliberately separate. Login/auth does NOT depend on Spotify.

## Why Separate Auth from Spotify

Spotify Development Mode caps an app at **5 authorizing users** (users who complete the OAuth flow). If login required Spotify, the entire service would be capped at 5 users. Instead:

- Login = Supabase Auth (email + Google/Apple) — unlimited users
- Spotify = optional per-user feature, gated by `profiles.spotify_enabled`

## Catalog Search (Client Credentials)

The Flutter app never holds `SPOTIFY_CLIENT_SECRET`. Instead:

```
Flutter app
  → POST /functions/v1/spotify-app-token (Supabase Edge Function)
  → Edge function calls Spotify /api/token (Client Credentials)
  → Returns short-lived access token to client
  → Client uses token for catalog search requests
```

**Edge function**: `supabase/functions/spotify-app-token/index.ts`
**Secret**: `SPOTIFY_CLIENT_SECRET` set via `supabase secrets set`

### Removed Endpoints (do not use)

Spotify removed these for new apps — they return 403:
- `audio-features`, `audio-analysis` (mood/energy/danceability)
- `recommendations`, `related-artists`
- `new-releases`, artist top-tracks
- Other users' profiles, artist followers/popularity

**Mood data comes from Last.fm tags instead.** See [TAGS.md](TAGS.md).

### iTunes Fallback

If the Spotify catalog search fails (rate limit, dev-mode restriction, etc.), `CatalogService` falls back to the iTunes Search API:

- No authentication required
- Returns cover artwork
- Endpoint: `https://itunes.apple.com/search?term=...&entity=song`

## Recently-Played Import (Allow-Listed Users)

### Flow

```
User taps "Connect Spotify" (only shown if spotify_enabled = true)
  → PKCE code verifier + challenge generated in Flutter
  → Open Spotify OAuth URL in browser
  → Redirect to athens://spotify-callback
  → Exchange code → access token + refresh token
  → Store tokens in flutter_secure_storage (never sent to server)
  → GET /me/player/recently-played
  → Diff vs already-rated items
  → Surface unrated tracks as "rate this" cards
```

### Allow-List Management

1. Add user's Spotify email to Spotify Dashboard → User Management
2. Set `spotify_enabled = true` in Supabase:
   ```sql
   UPDATE profiles SET spotify_enabled = true, spotify_user_id = 'spotify:user:ID'
   WHERE id = 'user-uuid';
   ```

### Non-Enabled Users

Users without `spotify_enabled = true` see:
- HomeScreen: curated "explore new music" content (not blank)
- spotify_connect screen: informational message (not an error)
- Full app functionality — search, rate, stats, share all work

### Scopes

Only `user-read-recently-played` is requested. No write permissions, no playlist access.

## Redirect URIs

Register these EXACTLY in the Spotify Dashboard (including the scheme):

| Environment | URI |
|-------------|-----|
| Mobile (production) | `athens://spotify-callback` |
| Local dev | `http://127.0.0.1:8888/callback` |

## Token Refresh

Access tokens expire in 1 hour. The app automatically refreshes using the stored refresh token before making API calls. Refresh tokens are rotated on each refresh — the new token overwrites the old one in `flutter_secure_storage`.
