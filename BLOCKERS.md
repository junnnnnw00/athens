# Athens — Blockers

## Active Blockers

### Image share export — temporarily hidden before web deployment

The image share screen still exists in code and tests, but the Profile UI no
longer links to it because export/share behavior is not reliable enough for
public launch. Public profile link sharing remains available.

### Web — Spotify connect needs the redirect URI registered (manual)

Web Spotify connect is implemented (PKCE, same-tab redirect to the app entry
`/app/`, callback handled on boot in `main.dart`). It will fail with
"redirect_uri Not matching configuration" until you add the EXACT redirect URI
**`https://athens.vercel.app/app/`** (with trailing slash) in the Spotify dashboard
→ app settings → Redirect URIs. See MORNING-CHECKLIST §2. (Spotify token + `/v1/me`
endpoints are CORS-enabled for public PKCE clients, so the browser flow works once
the URI is registered.) Desktop stays gated (no keychain entitlement).

### macOS desktop — Spotify connect disabled (no signing cert)

`flutter_secure_storage` (PKCE token store) needs the `keychain-access-groups`
entitlement, which forces development signing — ad-hoc local macOS builds fail to
build with it. Removed the entitlement so the app builds/runs; Spotify connect on
desktop shows "모바일 앱에서만 지원돼요" instead. Spotify is a mobile/allow-listed
feature, so this is fine. On iOS/Android the keychain works normally.

### APK build — no Java runtime / Android SDK on this build machine

`flutter build apk --debug` fails locally: "Unable to locate a Java Runtime."
(no JDK and no Android SDK installed on this macOS host).

**Impact:** DoD check #3 unverifiable on this machine only.

**Status:** The Flutter code compiles clean (`flutter analyze` 0 issues,
`flutter build web` succeeds, all tests pass). The APK path is unchanged.

**Where it IS verified:** CI (`.github/workflows/ci.yml`, `ubuntu-latest` +
`subosito/flutter-action`, which provisions the Android SDK) runs
`flutter build apk --debug` on every push.

**To verify locally:** install a JDK (`brew install --cask temurin`) + Android
cmdline-tools, then `cd app && flutter build apk --debug`. See MORNING-CHECKLIST §2.

### Supabase — unverified against a live DB

Migrations are written and **sqlfluff-clean** (`.sqlfluff`, postgres dialect), with
RLS on every table, a `public_profiles` security-definer view, and the two edge
functions. `supabase db reset` still needs Docker + the Supabase CLI linked.

**To verify:** MORNING-CHECKLIST §1 / §9.

### Live external APIs — Spotify catalog now verified live

Real impls exist (`SpotifyApiHttp`, `ItunesApiHttp`, `LastfmApiHttp`,
`MusicBrainzApiHttp`); the network boundary is faked in tests. **Spotify
catalog search is now confirmed working live** (limit=10 returns tracks +
artists with images; see DECISIONS "Spotify dev-mode search caps"). The PKCE
recently-played round-trip still needs a real allow-listed device session.

**To verify:** MORNING-CHECKLIST §7 (PKCE on device). iTunes fallback covers
any Spotify gap.

## Resolved

- **Search capped / artist photos missing (2026-05-31):** Spotify dev-mode
  `/search` rejects `limit>10` → every search 400'd → iTunes fallback (capped,
  no artist art). Fixed by `kSearchPageSize=10` + offset paging + token caching
  + removing bulk artist endpoint. Verified live. See DECISIONS.
- **Web landing + profiles 404'd (2026-05-31):** Vercel `framework:null` served
  static `public/` only; project had no env vars. Fixed via `web/vercel.json`
  (`framework:nextjs`) + `NEXT_PUBLIC_SUPABASE_*` on the project. `/`, `/u/*`,
  `/app` all 200.
- **Web unified into one site (2026-05-31):** the two separate Vercel projects
  (`athens` Flutter static + `web` Next.js profiles) are now ONE site served by the
  `web` project — `/` landing, `/u/[handle]` SSR profile, `/app/*` Flutter. Live at
  `athens.vercel.app`. Old `app/web/vercel.json` removed; old `athens` project orphaned
  (safe to delete). See DECISIONS.md + PROGRESS.md.
- Runtime used `Fake*` APIs + in-memory state → replaced with real impls behind
  interfaces + Drift-backed `LibraryRepository`; fakes moved to `test/`.
- Dead controls (empty `onPressed`/`onTap`) → all wired.
- Default-Material theme → custom `lib/theme` (mint, Hanken Grotesk), asserted by test.
- Spotify PKCE flow → implemented (`SpotifyPkceService`: launch → callback → token
  exchange → secure storage → refresh). Real device test still pending (MORNING §2).
- `pubspec.lock`, generated `.g.dart`, `withOpacity` deprecation, `custom_lint`
  conflict, duplicate artifact → all fixed previously.

## Stubs / fakes documented

| Item | Where |
|------|-------|
| Supabase project + `db reset` | supabase/ + MORNING-CHECKLIST §1/§9 |
| Spotify keys + device round-trip | MORNING-CHECKLIST §2/§7 |
| Last.fm / MusicBrainz live calls | faked in test/fakes/ (parsers unit-tested) |
| APK build (Java/Android SDK) | CI (GitHub Actions) |
