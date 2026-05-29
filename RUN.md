# RUN.md — launch & verify Athens in 5 minutes

How to run the app against real keys and what each screen should show. For setup
of the keys/services themselves, see `docs/SETUP.md` and `MORNING-CHECKLIST.md`.

## 0. Prerequisites
- Flutter 3.29+ stable, Node 20+.
- Public client values in `.env` (Supabase URL + publishable key, Spotify client
  id). Server secrets live only in Supabase edge-function secrets.

## 1. Run with seeded sample data (no backend needed)
The fastest way to see real screens. `kDevSeed` writes real rows into the local
Drift database through the same providers as production:

```bash
cd app
flutter pub get
flutter run --dart-define=DEV_SEED=true        # pick a device/emulator
```

What you should see:
- **Home** — Korean header "오늘은 무엇을 평가할까요?", a mint "듀얼 시작하기" callout,
  and (without Spotify) a graceful "Spotify 연결" empty state.
- **Add (centre nav)** → **Search** — type a query; results stream from the
  catalog service (Spotify→iTunes). Tap 추가 to add (tags are enriched on add).
- **Rate (duel)** — two frosted album cards, "어떤 게 더 좋아요?"; tapping one lifts
  it, dims the other, persists the Elo update, and loads the next pair.
- **Me → Library** — ranked rows with a 56px cover, title, "Kind · artist", a
  mint **score ring** on the right, crown on #1. Filter chips (All/Albums/…).
- **Item detail** — large cover, score ring, Elo/duel stats, real tag chips, and
  a review box that persists (survives restart).
- **Stats** — score distribution bar chart, top genres/moods bars, activity line
  — all computed from your ratings, mint-only series.
- **Share** — Top 5 / Taste Snapshot cards rendered from live data; share exports
  a 1080×1920 PNG.

## 2. Run against the real backend
1. Fill `.env` with the public Supabase + Spotify values.
2. Pass them at launch:
```bash
cd app
flutter run \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY \
  --dart-define=SPOTIFY_CLIENT_ID=$SPOTIFY_CLIENT_ID
```
3. Sign up / sign in (email). Ratings & reviews sync via Supabase with RLS; a
   second session for the same user sees the same data.
4. Spotify connect (allow-listed users only): Me → Spotify 연결 → PKCE flow →
   recently-played tracks surface on Home as unrated "rate this" cards.

## 3. Web profile
```bash
cd web
npm ci
NEXT_PUBLIC_SUPABASE_URL=... NEXT_PUBLIC_SUPABASE_ANON_KEY=... npm run dev
# open http://localhost:3000/u/<handle>   (public profiles only)
```
A public handle renders the ranked list + stats; a private/unknown handle shows a
proper "not found" page and leaks nothing.

## 4. Verify the build (what CI / the DoD checks)
```bash
cd app && flutter analyze
cd app && flutter test                  # unit + widget + golden
cd app && flutter test integration_test # core-loop e2e on seeded data
cd app && flutter build web
cd app && flutter build apk --debug     # needs Android SDK
cd web && npm ci && npm run build
```

## 5. Golden screens
Pre-rendered reference screens (dark + light) live in `app/test/golden/*.png` —
open them for a 30-second visual check without launching anything.
