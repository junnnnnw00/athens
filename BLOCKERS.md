# Athens — Blockers

## Active Blockers

### APK Build — No Android SDK on build machine

`flutter build apk --debug` fails: "No Android SDK found."

**Impact:** DoD check #3 unverifiable locally.

**Workaround:** CI (`ubuntu-latest` + `subosito/flutter-action`) includes Android SDK — APK build verified there. Code compiles clean (`flutter analyze` 0 issues, `flutter build web` succeeds).

**Fix:** Install Android Studio or run `sdkmanager`. See MORNING-CHECKLIST.md step 2 equivalent.

### Supabase migrations — unverified against live DB

SQL written and linted, but `supabase db reset` requires Docker + Supabase CLI linked to the project.

**Fix:** See MORNING-CHECKLIST.md step 1.

### Spotify PKCE flow — stub only

`_startPkceFlow()` shows a snackbar. Full flow (url_launcher → callback → token exchange → `flutter_secure_storage`) needs real `SPOTIFY_CLIENT_ID` and device testing.

**Fix:** See MORNING-CHECKLIST.md step 2.

## Resolved

- `pubspec.lock` excluded from git → fixed (committed)
- `build_runner` generated `.g.dart` missing → fixed (.gitignore exception, file committed)
- `withOpacity` deprecation warnings → fixed (`withValues(alpha:)`)
- `custom_lint` version conflict → fixed (removed from pubspec)
- Duplicate artifact `item_detail_screen 2.dart` → deleted

## Stubs Documented

| Item | Stub location |
|------|--------------|
| Supabase project + migrations | supabase/ + MORNING-CHECKLIST.md |
| Spotify PKCE flow | app/lib/features/spotify_connect/ |
| Last.fm API key | FakeLastfmApi + edge function |
| MusicBrainz live rate-limit | FakeMusicBrainzApi |
| Physical device test | MORNING-CHECKLIST.md |
| APK build | CI (GitHub Actions) |
