# RELEASE.md — full-platform deploy runbook

The exact order to ship a change to **all** surfaces (web, Android, macOS,
Supabase). Follow top to bottom; each phase gates the next. Derived from the
v1.5.8 release.

> Live infra (don't re-provision): GitHub `junnnnnw00/athens`, Supabase ref
> `hgehnwruprjoeewrhbgg`, Vercel `athens.vercel.app`. See CLAUDE.md.

---

## 0. Pre-flight (always)

```bash
make analyze && make test          # must be green (133+ tests)
make sqlfluff                       # if migrations changed (0022+ pass; older may not)
git diff | grep -inE 'sb_secret_|SPOTIFY_CLIENT_SECRET|LASTFM_API_KEY *=|SERVICE_ROLE_KEY *='
                                    # secret scan — must be empty
```

Artifacts that must stay **out** of git (already in `.gitignore`): `*.aab`,
`app/test/golden/failures/`, `.claude/`, `mockups & store images/`.

## 1. Commit (explicit `git add`, never `-A`)

Group logically (app fixes / backend infra). End messages with the
`Co-Authored-By` trailer.

## 2. Supabase (DB first, then functions)

```bash
yes | supabase db push              # apply new migrations to hosted
make deploy-functions               # deploy edge functions (--no-verify-jwt)
```

Smoke-test (anon, functions are public):

```bash
BASE=https://hgehnwruprjoeewrhbgg.supabase.co/functions/v1
curl -s -o /dev/null -w '%{http_code}\n' "$BASE/lastfm-proxy?method=tag.getTopTracks&tag=shoegaze&limit=3"   # 200
curl -s -o /dev/null -w '%{http_code}\n' "$BASE/lastfm-proxy?method=user.getInfo&user=rj"                    # 403 (allowlist)
```

The two proxies are **cached + rate-limited** (api_cache / api_rate, migration
0022). A 2nd identical call should be markedly faster (cache hit).

## 3. Web

```bash
make web-deploy                     # flutter build web → copy → vercel --prod → re-pin aliases
```

⚠️ NEVER `vercel deploy` directly — aliases won't update. Verify
`curl -s -o /dev/null -w '%{http_code}' https://athens.vercel.app/` → 200, then
hard-refresh (Cmd+Shift+R).

## 4. Android + macOS release (one GitHub Release per version)

```bash
./release-android.sh X.Y.Z          # bumps pubspec, builds APK, commits, tags vX.Y.Z,
                                    # pushes main+tags, creates GH Release w/ APK
make macos-zip                      # → app/build/athens-macos.zip
gh release upload vX.Y.Z app/build/athens-macos.zip#athens-X.Y.Z-macos.zip
```

- **Every release MUST carry the macOS `.zip`** — the in-app updater downloads it;
  without it macOS self-update grabs the release HTML page and breaks.
- The sideload **APK** keeps `STORE_BUILD` off → self-updates from GitHub Releases.

## 5. Play Store bundle (manual upload)

```bash
make android-aab                    # builds with --dart-define=STORE_BUILD=true
                                    # → app/build/app/outputs/bundle/release/app-release.aab
```

`STORE_BUILD=true` disables the GitHub in-app updater (Play manages updates).
Upload the `.aab` to Play Console by hand (signature is the upload key; Google
re-signs). Do NOT attach the `.aab` to the GitHub release.

## 6. Version scheme

`X.Y.Z+CODE` where `CODE = X*100000 + Y*1000 + Z` (e.g. 1.5.8 → 105008).
Monotonic — the Play Store / sideload never sees a build-number regression.

---

## Scaling notes (current)

- Catalog **search = iTunes, called per-user-IP** (client-direct) → no shared
  bottleneck. The Spotify path is dead code.
- Shared-key upstreams = **Last.fm (~5/s)** and **MusicBrainz (hard 1/s)**, both
  behind cached + token-bucketed edge proxies. Comfortable to ~1000 users;
  expect Supabase **Pro ($25/mo)** there for function-invocation volume.
- If search ever needs Spotify again: it stays dev-mode capped (search `limit≤10`)
  until Extended Quota Mode is granted (needs app scale).
