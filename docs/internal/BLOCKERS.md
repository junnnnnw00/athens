# Athens — Blockers

## Active

### Image share export — hidden in the UI
The image-share screen still exists in code + tests, but the Profile UI doesn't
link to it: export/share output isn't reliable enough for launch. Public profile
**link** sharing works. Re-enable once the export is solid (tracked in PRELAUNCH.md
post-launch features).

### Pre-launch checklist — see PRELAUNCH.md
Account-deletion processing, email confirmation, and crash reporting are tracked
in `/PRELAUNCH.md`, not here.

## Resolved (history)

- **Spotify per-user connect — REMOVED entirely (commit 8f556d2).** Login is
  Supabase Auth; listening history is Last.fm connect. The old blockers (web
  redirect URI, macOS keychain entitlement, PKCE device round-trip) are moot —
  there is no Spotify user-connect path anymore. Catalog search is iTunes
  (client-direct); the server-side Spotify app-token path is unused dead code.
- **APK build / Java runtime —** builds fine; v1.5.8 APK + AAB shipped (Flutter
  uses the Android Studio JDK). See RELEASE.md.
- **Supabase live —** migrations through 0023 applied to the hosted project; edge
  functions (lastfm/musicbrainz cached+rate-limited proxies, spotify-app-token)
  deployed. The `public_profiles` security-definer view is guarded by
  `WHERE is_public = true` (safe; linter warning is a false positive).
- **Last.fm recent order, search caps, web 404s, theme, dead controls —** all
  fixed previously (see git history + DECISIONS.md).
