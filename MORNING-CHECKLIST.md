# Athens — Morning Checklist (Manual Steps)

These steps require real credentials, a physical device, or external service access.
Everything else was completed and tested automatically overnight.

---

## 1. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project named `athens`.
2. Copy your project URL + anon key + service role key into `.env`:
   ```
   SUPABASE_URL=https://YOUR_REF.supabase.co
   SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
   SUPABASE_SECRET_KEY=sb_secret_...
   ```
3. Install Supabase CLI: `brew install supabase/tap/supabase`
4. Link project: `supabase link --project-ref YOUR_REF`
5. Run migrations: `supabase db reset` (requires Docker)
6. Deploy edge functions:
   ```
   supabase functions deploy spotify-app-token --no-verify-jwt
   supabase functions deploy lastfm-proxy
   ```
7. Set edge function secrets:
   ```
   supabase secrets set SPOTIFY_CLIENT_SECRET=... LASTFM_API_KEY=...
   ```

## 2. Register Spotify App

1. Go to [developer.spotify.com/dashboard](https://developer.spotify.com/dashboard)
2. Create app named `Athens`
3. Add redirect URIs:
   - `athens://spotify-callback` (mobile)
   - `http://127.0.0.1:8888/callback` (local dev)
4. Copy Client ID into `.env`: `SPOTIFY_CLIENT_ID=...`
5. Copy Client Secret into `.env`: `SPOTIFY_CLIENT_SECRET=...` (server-only!)
6. Add yourself + ≤4 friends to the allowlist in Spotify dashboard (Dev Mode = 5 user cap)
7. In Supabase, set `profiles.spotify_enabled = true` for allowlisted users

## 3. Register Last.fm API Key

1. Go to [last.fm/api/account/create](https://www.last.fm/api/account/create)
2. Create app named `Athens`
3. Copy API key into `.env`: `LASTFM_API_KEY=...`
4. Optional: copy Shared Secret for authenticated calls: `LASTFM_SHARED_SECRET=...`

## 4. Configure MusicBrainz User-Agent

1. Update `.env`: `MUSICBRAINZ_USER_AGENT=Athens/0.1 ( your@email.com )`
2. Use your real email — MusicBrainz may contact you if usage is unexpected.

## 5. Deploy Web Profile (Vercel)

1. Push repo to GitHub
2. Import repo in [vercel.com](https://vercel.com)
3. Set root directory to `web`
4. Add environment variables:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
5. Deploy → your public profiles will be at `https://your-domain.vercel.app/u/[handle]`

## 6. Test on Physical Device (iOS/Android)

1. Connect device via USB
2. `cd app && flutter run` — select your device
3. Test the full flow: sign up → search a track → rate it → view stats → share

## 7. Verify Spotify Client Credentials Catalog Search

1. With real `SPOTIFY_CLIENT_ID` + `SPOTIFY_CLIENT_SECRET` in edge function secrets:
2. Call the `spotify-app-token` edge function and confirm it returns a valid token
3. Test catalog search with the token — confirm dev-mode doesn't restrict public search
4. If restricted, the iTunes fallback activates automatically (verify it returns results)

## 8. Enable Google/Apple OAuth (Supabase Auth)

1. Supabase Dashboard → Authentication → Providers
2. Enable Google: add OAuth credentials from Google Cloud Console
3. Enable Apple: add credentials from Apple Developer Portal
4. Update redirect URLs in each provider's dashboard to match your Vercel deployment

## 9. Confirm `supabase db reset` Succeeds

- Requires Docker running locally
- `cd supabase && supabase db reset`
- Expected: all migrations apply clean, seed data loads, RLS policies active

## 10. CI / CD (GitHub Actions)

1. Push to GitHub
2. Add repository secrets:
   - `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` (for integration tests if added later)
3. Verify CI passes on first push: flutter analyze, flutter test, next build

---

## Verified Automatically (no action needed)

- [x] `flutter analyze` exits 0
- [x] `flutter test` exits 0 (rank domain ≥ 90% coverage)
- [x] `flutter build apk --debug` exits 0
- [x] `flutter build web` exits 0
- [x] `npm ci && npm run build` (web) exits 0
- [x] No secrets committed (`.env` in `.gitignore`)
- [x] SQL migrations written (unverified against live DB — see #9)
- [x] All external APIs behind interfaces with Fake impls
