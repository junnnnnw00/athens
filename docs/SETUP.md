# Athens — Setup Guide

## Prerequisites

- Flutter 3.29+ (stable): https://flutter.dev/docs/get-started/install
- Node.js 20+: https://nodejs.org
- Supabase CLI: `brew install supabase/tap/supabase`
- Docker (for local Supabase): https://docs.docker.com/get-docker/
- A Spotify account (Premium recommended for recently-played)

## 1. Clone and Configure

```bash
git clone https://github.com/YOUR_HANDLE/athens.git
cd athens
cp .env.example .env
```

Edit `.env` with your credentials (see sections below).

## 2. Supabase Setup

### 2a. Create Supabase Project

1. Go to https://supabase.com → New project
2. Note your **Project URL** and **API keys** (Settings → API)
3. Update `.env` (client/public values only):
   ```
   SUPABASE_URL=https://YOUR_REF.supabase.co
   SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
   ```
   The service-role key is server-only — set it as an edge-function secret
   (`supabase secrets set`), never in `.env`.

### 2b. Run Migrations

```bash
cd supabase
supabase link --project-ref YOUR_REF
supabase db reset   # runs all migrations + seed.sql
```

### 2c. Deploy Edge Functions

```bash
supabase functions deploy spotify-app-token --no-verify-jwt
supabase functions deploy lastfm-proxy

# Set the server-side secrets, one per line:
#   supabase secrets set SPOTIFY_CLIENT_ID <value>
#   supabase secrets set SPOTIFY_CLIENT_SECRET <value>
#   supabase secrets set LASTFM_API_KEY <value>
```

### 2d. Enable Auth Providers

Supabase Dashboard → Authentication → Providers:
- **Email**: enabled by default
- **Google**: add OAuth credentials from Google Cloud Console
- **Apple**: add credentials from Apple Developer Portal

## 3. Spotify Setup

See [SPOTIFY.md](SPOTIFY.md) for full details.

Short version:
1. Create app at https://developer.spotify.com/dashboard
2. Add redirect URIs: `athens://spotify-callback` and `http://127.0.0.1:8888/callback`
3. Copy Client ID + Secret to `.env`
4. Add yourself (+ ≤4 friends) to the Spotify app allowlist

## 4. Last.fm Setup

1. Create API account at https://www.last.fm/api/account/create
2. Copy API key to `.env`: `LASTFM_API_KEY=...`

## 5. Run the Flutter App

```bash
cd app
flutter pub get
flutter run        # pick a device
```

For web:
```bash
flutter run -d chrome
```

## 6. Run the Web Profile

```bash
cd web
npm ci
npm run dev
# Open http://localhost:3000/u/YOUR_HANDLE
```

For production deploy, see [Vercel deployment](#vercel).

## 7. Vercel Deployment (web profile)

1. Push to GitHub
2. Import repo at https://vercel.com → New Project
3. Set **Root Directory** to `web`
4. Add environment variables:
   - `NEXT_PUBLIC_SUPABASE_URL` = your Supabase URL
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY` = your anon/publishable key
5. Deploy

Public profiles will be at `https://athens.vercel.app/u/[handle]`.

## 8. Spotify Allow-List Management

Spotify Dev Mode caps at 5 authorized users. To add a user:
1. Spotify Dashboard → your app → User Management
2. Add their Spotify email
3. In Supabase, set `UPDATE profiles SET spotify_enabled = true WHERE spotify_user_id = '...'`

## 9. Development Environment (athens-dev)

For local development and staging testing of new features (e.g. Premium/Backer features), we use a separate environment to avoid polluting production data:

1. **Git Branch:** Always check out and work on the `dev` branch.
2. **Database:** Put your development database configuration in `app/config/app_config_dev.json`.
3. **Running the client:** Use `make run-dev` or `make run-dev-seed` to start the Flutter app using development configurations.
4. **Deploying edge functions to dev:**
   ```bash
   cd supabase
   supabase link --project-ref <your-athens-dev-project-ref>
   supabase functions deploy spotify-app-token --no-verify-jwt
   supabase functions deploy lastfm-proxy
   ```
5. **Staging Web Deploy:** Use `make web-deploy-dev` to push a preview build of the web profile app to Vercel without affecting the production `athens.vercel.app` alias.

## Troubleshooting

- **`flutter analyze` errors**: run `flutter pub get` first
- **Supabase auth not working**: check redirect URLs match exactly (including trailing slashes)
- **Spotify 403 errors**: confirm user is in the Dev Mode allowlist; confirm `SPOTIFY_CLIENT_SECRET` is only in edge function secrets, not `.env` shipped to client
- **Last.fm returning no tags**: some tracks have few crowd tags — this is normal; MusicBrainz genres fill the gap
