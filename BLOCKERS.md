# Crate — Blockers

## Active Blockers

### APK Build (DoD #3) — No Android SDK on build machine

`flutter build apk --debug` fails with "No Android SDK found."

**Stub:** Build runs clean in CI (GitHub Actions `ubuntu-latest` with `subosito/flutter-action`
which includes Android SDK). The code compiles — confirmed via `flutter analyze` (0 issues)
and `flutter build web` (succeeds). APK build verified via CI only; not locally verifiable
without installing Android SDK.

**Action required:** See MORNING-CHECKLIST.md step 10 — run `flutter build apk --debug` after
installing Android Studio or `sdkmanager`.

## Resolved Blockers

None yet.

## Stubs / Deferred Items

| Item | Stub | Location |
|------|------|----------|
| Supabase project creation | Placeholder URLs in .env.example | docs/SETUP.md |
| Spotify app registration | Mock PKCE flow + fake tokens | app/lib/features/spotify_connect/ |
| Last.fm API key | FakeLastfmApi returns mock tags | app/lib/catalog/fake_lastfm_api.dart |
| MusicBrainz live test | FakeMusicBrainzApi | app/lib/catalog/fake_musicbrainz_api.dart |
| Physical device testing | Widget + integration tests | app/test/ |
| Supabase CLI / Docker verification | SQL noted as unverified | supabase/README.md |
