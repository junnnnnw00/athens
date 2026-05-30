# Athens — Blockers

## Active Blockers

### Image share export — temporarily hidden before web deployment

The image share screen still exists in code and tests, but the Profile UI no
longer links to it because export/share behavior is not reliable enough for
public launch. Public profile link sharing remains available.

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

### Live external APIs — exercised via fakes only

Real impls exist (`SpotifyApiHttp`, `ItunesApiHttp`, `LastfmApiHttp`,
`MusicBrainzApiHttp`); the network boundary is faked in tests. Confirming
dev-mode Spotify catalog access + the PKCE round-trip needs real keys + a device.

**To verify:** MORNING-CHECKLIST §2 / §7. iTunes fallback covers Spotify gaps.

## Resolved

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
