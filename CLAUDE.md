# CLAUDE.md — read this first, every turn

Auto-loaded by Claude Code. This is the recovery anchor and the standing-rules book for the
unattended `/goal` run. The active `/goal` defines the finish line; this file defines *how* to get there.

---

## Live infrastructure (deployed — use this, don't re-provision)

- **GitHub:** https://github.com/junnnnnw00/athens (`origin`, branch `main`)
- **Supabase (hosted):** project `athens`, ref `hgehnwruprjoeewrhbgg` (Seoul ap-northeast-2). Migrations pushed, RLS live. Edge functions `spotify-app-token`, `lastfm-proxy`, `musicbrainz-proxy` deployed.
- **Vercel:** project `athens` (`junwoo-hong-s-projects`) → **https://athens.vercel.app** (alias `athens-sand.vercel.app`). Deployment Protection OFF. The Next.js `web/` project is the host shell; Flutter bundle lives under `/app`.
- **The app talks to HOSTED Supabase.** Local `supabase start` is ONLY for testing migrations. Stop it with `make sb-stop`.

---

## Common commands (use the Makefile — always run from repo root)

```bash
make run            # Run app on default device (macOS) against hosted backend
make run-seed       # Run with sample data seeded into Drift
make test           # Unit + widget + golden tests
make analyze        # flutter analyze
make goldens        # Regenerate committed golden screenshots

# Android (USB-connected phone)
make android-run    # Debug run on USB device
make android-apk    # Build signed release APK → app/build/.../app-release.apk
make android-install # Build + ADB install APK to USB device
make android-logs   # Stream ADB logcat filtered by athens

# Web
make web-deploy     # ⚠️  See "Deploy Checklist" below — ALWAYS follow

# Supabase
make db-reset-local   # Apply migrations + seed to LOCAL Docker stack
make deploy-functions # Push edge functions to remote
make sqlfluff         # Lint SQL migrations
```

---

## ⚠️ Deploy Checklist — ALWAYS follow before `make web-deploy`

> **Root cause of past failures:** The AI agent sometimes ran `make web-deploy` using a stale
> Flutter build from a previous session. The deployed app appeared to miss recently added features
> even though `vercel deploy` showed "Ready". Always verify the below before deploying.

### Step-by-step

1. **Commit all code changes** (don't deploy uncommitted work):
   ```bash
   git add -p && git commit -m "feat(...): ..."
   ```

2. **Pass checks:**
   ```bash
   make analyze   # must exit 0
   make test      # must exit 0
   ```

3. **Run the deploy** (this always does a fresh `flutter build web` first):
   ```bash
   make web-deploy
   ```
   `make web-flutter` (called internally) runs `flutter build web` fresh every time → output
   always reflects current source. Then copies `app/build/web/` → `web/public/app/` → deploys.

4. **Verify on the live URL immediately after deploy:**
   - Open https://athens.vercel.app in a browser
   - Hard-refresh: **Cmd+Shift+R** (bypasses Service Worker cache)
   - Confirm the specific feature/fix you just deployed is visible
   - If it looks stale: check `stat -f "%Sm" web/public/app/main.dart.js` — should be within the last few minutes

5. **Push to remote:**
   ```bash
   git push origin main
   ```

### Why `web/public/app/` is always fresh

`web/public/app/` is **gitignored** — it's regenerated each deploy by `make web-flutter`.
`make web-deploy` always runs `flutter build web` before copying, so the bundle always matches
the current source code at the time `make web-deploy` is run.

---

## Android distribution (sideload — no Play Store yet)

- **Keystore:** `app/android/app/upload-keystore.jks` (gitignored, 10,000-day validity)
- **Signing config:** `app/android/key.properties` (gitignored)
- **Release APK:** `make android-apk` → `app/build/app/outputs/flutter-apk/app-release.apk`
- **One-command release script:** `./release-android.sh <version>`
  → bumps `pubspec.yaml` version, builds signed APK, commits + tags, creates GitHub Release with APK attached
- **In-app update check:** `UpdateService` polls GitHub Releases API on every app launch (Android only).
  If a newer version is available, `UpdateBanner` slides in on the home screen with a download link.
- **USB deploy flow:** enable USB Debugging → `make android-install` (builds APK + `adb install -r`)

### ADB path (add to shell or use make targets directly)
```bash
export PATH="$PATH:/opt/homebrew/share/android-commandlinetools/platform-tools"
adb devices   # should show your phone
```

---

## Source of truth (read before acting)

1. **PROMPT.md** — full spec, milestones M0–M7, Definition of Done. Authoritative.
2. **PROGRESS.md** — save file: what's done, in progress, next concrete step.
3. **DECISIONS.md** — choices already made + "Needs human approval" proposals.
4. **BLOCKERS.md** — stubbed/blocked items and stub left behind.
5. **IDEAS.md** — improvement ideas intentionally NOT built (for morning review).
6. **MORNING-CHECKLIST.md** — human-only items (keys, device tests).
7. **ACCEPTANCE.md** — items that need human acceptance before goal is complete.
8. **DESIGN.md** — visual design document.

---

## Continuous work loop (never idle)

- Pick the next incomplete task from PROGRESS.md. Implement in small, verifiable steps.
- After each step: `make analyze` + `make test`. Fix failures before advancing.
- After each meaningful unit: commit (conventional message) + update PROGRESS.md.
- Finish one task → immediately start the next. Don't stop to ask.
- Tag each completed milestone: `git tag m0`, `m1`, …

---

## Loop-failure escape (don't burn the night)

If the SAME check fails ~3 times in a row → write the failure + stub into BLOCKERS.md and move to
the next INDEPENDENT task. One stuck spot must not consume the whole run.

---

## Self-improvement (proactive but disciplined — design-led product)

Between milestones, one focused pass. Think like a thoughtful product designer:
1. **UX** — core loop (pairwise duel) fast, obvious, satisfying. Fewer taps, clearer state.
2. **UI** — editorial, music-zine, restrained. Dark bg, ONE confident accent, strong type, real album art.
3. **Missing-but-obvious** — empty states, loading skeletons, error/offline, undo on destructive actions.
4. **New features** — only if they serve rate→rank→reflect→share AND stay inside PROMPT.md scope.

---

## Hard guardrails (do not cross without approval)

- Stay inside PROMPT.md scope + data sources. No new external APIs, no scraping.
- ONE accent color, ONE type system. Refine what works; don't redesign.
- No new backend table/RLS without DECISIONS.md entry + reversible plan.
- Anything touching privacy, auth, sharing, money → STOP, write PROPOSAL in DECISIONS.md.
- Before any commit: scan staged changes for secrets (`sb_secret_`, `SPOTIFY_CLIENT_SECRET`, `LASTFM_API_KEY`, raw `.env` values). If found → abort + log in BLOCKERS.md.

---

## Rate limits vs context (handle differently)

- **Rate/usage limit:** resolves on its own. Continue when able.
- **Context filling up:** write full handoff into PROGRESS.md + BLOCKERS.md, commit everything, THEN compact and resume. Treat repo docs as memory — assume conversation may be wiped anytime; files alone must be enough to continue.

---

## Core architecture constraints

- Login = Supabase Auth, NOT Spotify (Spotify dev mode caps at 5 users).
- Spotify = optional per-user connect, allow-listed (≤5), recently-played only.
- Catalog = Spotify app-token (Client Credentials) via edge function, iTunes fallback.
- Genre + mood = Last.fm tags + MusicBrainz. NO Spotify audio-features. NO scraping RateYourMusic.
- Secrets live in edge functions only — never bundled in Flutter app or Next.js client.
- Flutter uses `anon` JWT key (NOT `sb_publishable_`) in `app/config/app_config.json` — see DECISIONS.md.

---

## Goal completion

Do NOT consider the goal met until all DoD items pass from a CLEAN state and you've pasted the
fresh check results into PROGRESS.md. If anything fails, keep going.
