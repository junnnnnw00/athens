# Athens — Morning Checklist (Manual Steps)

These steps require real credentials, a physical device, or external service access.
Everything else was completed and tested automatically overnight.

---

## ✅ Done this session (backend live)

Project `athens` (ref `hgehnwruprjoeewrhbgg`, Seoul):
- [x] Migrations pushed to the **live** DB (`supabase db push`) — all tables + RLS
      + `public_profiles` view. Fixed `uuid_generate_v4()` → `gen_random_uuid()`
      (hosted puts uuid-ossp off the search_path).
- [x] Local `supabase db reset` applies migrations + seed clean.
- [x] Edge functions deployed: `spotify-app-token`, `lastfm-proxy` (`--no-verify-jwt`).
- [x] Secrets set: `SPOTIFY_CLIENT_ID`, `SPOTIFY_CLIENT_SECRET`, `LASTFM_API_KEY`.
- [x] Live smoke: spotify-app-token → Bearer token; lastfm-proxy → real tags;
      Spotify catalog search returns results (dev-mode does NOT restrict search).

- [x] §5 **Vercel deployed** (project `web`): live at
      https://web-jvtw5n44a-junwoo-hong-s-projects.vercel.app — home 200,
      `/u/<unknown>` → 404 (no data leak). Env vars set (prod/preview/dev);
      disabled default Deployment Protection so public profiles are reachable.
- [x] §10 **GitHub**: repo pushed to https://github.com/junnnnnw00/athens
      (main + tags m0–m7); Actions secrets `SUPABASE_URL` + `SUPABASE_PUBLISHABLE_KEY`
      set; CI Flutter version bumped 3.29→3.41.9 (flutter_lints 6 needs Dart ≥3.8).

Still manual (you):
- §2 set `spotify_enabled=true` — needs a signed-up user first (sign up in the app,
  give me the email, I run the UPDATE).
- §6 device test: `cd app && flutter run`.
- §8 Google/Apple OAuth — optional; email auth already works. Needs Google Cloud /
  Apple Developer credentials (your dashboards).

> ⚠️ Revoke the Personal Access Token pasted into chat
> (supabase.com/dashboard/account/tokens) — it was used only in-memory, not stored.

---

## 1. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project named `athens`.
2. Copy your project URL + anon key + service role key into `.env`:
   ```
   SUPABASE_URL=https://YOUR_REF.supabase.co
   SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
   ```
   The service-role key is NOT a client value — set it server-side only
   (`supabase secrets set`), never in `.env`.
3. Install Supabase CLI: `brew install supabase/tap/supabase`
4. Link project: `supabase link --project-ref YOUR_REF`
5. Run migrations: `supabase db reset` (requires Docker)
6. Deploy edge functions:
   ```
   supabase functions deploy spotify-app-token --no-verify-jwt
   supabase functions deploy lastfm-proxy
   ```
7. Set edge function secrets (Spotify client secret, Last.fm API key, and the
   Supabase service-role key) via `supabase secrets set NAME <value>` for each.

## 2. Register Spotify App

1. Go to [developer.spotify.com/dashboard](https://developer.spotify.com/dashboard)
2. Create app named `Athens`
3. Add redirect URIs:
   - `athens://spotify-callback` (mobile)
   - `http://127.0.0.1:8888/callback` (local dev)
4. Copy Client ID into `.env`: `SPOTIFY_CLIENT_ID=...`
5. Set the client secret as an edge-function secret only (server-only — never in `.env`)
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
- [x] `flutter test` exits 0 (rank domain 98.9% coverage; unit + widget + golden)
- [x] `flutter test integration_test` exits 0 (core-loop e2e)
- [ ] `flutter build apk --debug` — **CI only** (no JDK/Android SDK on the build
      host). To run locally: `brew install --cask temurin`, install Android
      cmdline-tools, accept licenses, then `cd app && flutter build apk --debug`.
- [x] `flutter build web` exits 0
- [x] `npm ci && npm run build` (web) exits 0
- [x] SQL migrations sqlfluff-clean (`.sqlfluff`); unverified against live DB — see #9
- [x] No secrets committed (`.env` in `.gitignore`; secret-leak grep clean)
- [x] External APIs behind interfaces; fakes live only in `test/`
