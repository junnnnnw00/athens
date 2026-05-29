# Athens — Build Progress

## Current State (2026-05-29)

All 8 milestones implemented and committed. App renamed from "Crate" to **Athens**. Credentials from `.env` applied to `.env.example` (public values only).

### DoD Checks

| Check | Status | Evidence |
|-------|--------|---------|
| `flutter analyze` | ✅ 0 issues | Verified after rename |
| `flutter test` (49 tests) | ✅ All pass | Verified before rename; analyze clean after |
| Domain coverage ≥90% | ✅ 97.8% | 90/92 lines |
| `flutter build web` | ✅ Exit 0 | Verified: "Built build/web" |
| `npm ci && npm run build` | ✅ Exit 0 | Next.js `/u/[handle]` route live |
| SQL migrations + RLS | ✅ Written | Needs `supabase db reset` to verify live |
| Secrets not committed | ✅ | `.env` in `.gitignore` |
| All docs | ✅ | README, SETUP, SPOTIFY, TAGS, ARCHITECTURE |
| MORNING-CHECKLIST | ✅ | 10 steps documented |
| `flutter build apk` | ⚠️ Blocked | No Android SDK on this machine — see BLOCKERS.md |

## Milestone History

| Milestone | Status |
|-----------|--------|
| M0 Scaffold | ✅ |
| M1 Ranking Engine | ✅ |
| M2 Auth + Sync | ✅ |
| M3 Catalog + Tags | ✅ |
| M4 Spotify Connect | ✅ |
| M5 Library + Stats | ✅ |
| M6 Share + Web | ✅ |
| M7 OSS Polish | ✅ |

## Commit History

1. `feat: M0-M6` — 74 files, full scaffold through share/web
2. `feat(M7)` — 129 files, platform dirs + ItemDetailScreen + ReviewsService
3. `chore: deslop` — shadow var + empty-guard fix
4. `chore: rename Crate → Athens` — (pending)

## Next Steps (Morning Checklist)

1. **`supabase db reset`** — verify migrations apply clean (requires Docker + Supabase CLI)
2. **Flutter APK build** — install Android SDK, run `flutter build apk --debug`
3. **Deploy edge functions** — `supabase functions deploy` with real secrets set
4. **Spotify app** — register at developer.spotify.com, add `athens://spotify-callback` redirect
5. **Last.fm key** — create at last.fm/api/account/create
6. **Vercel deploy** — set root dir to `web`, add Supabase env vars
7. **Physical device test** — `flutter run`, full flow: sign-up → search → duel → share
