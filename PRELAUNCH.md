# PRELAUNCH.md — pre-launch audit & checklist

Audit of the Athens app before public store launch (2026-06-07). Findings from a
code + infra scan, grouped by severity. Each item lists the evidence path, the
risk, and the fix direction. Check off as resolved.

> Verdict: 🔴 items are **launch-blocking** (legal / policy / operational
> visibility). 🟠 are fast cleanups. ✅ verified healthy. ⚪ recommended but not
> blocking.

---

## 🔴 Critical — must resolve before store launch

### [x] 1. Account deletion — RESOLVED (2026-06-07)
- **Was:** delete-account page only inserted a `deletion_requests` row (no
  processor); RLS `"Allow public insert"` let anyone insert any email.
- **Fixed:** authenticated `delete-account` edge function deletes the caller's
  own `auth.users` row (verified from their JWT, never a body id) → cascades to
  profile / ratings / comparisons / reviews / follows. In-app delete tile now
  confirms → calls it → signs out. `deletion_requests` RLS locked to
  authenticated self-inserts (migration 0025). Deployed with `verify_jwt` on.

### [x] 2. Email confirmation — RESOLVED (2026-06-16)
- Supabase dashboard SMTP configured + "Confirm email" enabled (done by operator).

### [x] 3. Crash reporting — RESOLVED (2026-06-16)
- `sentry_flutter` wired into `main.dart`. Both `FlutterError.onError` and
  `PlatformDispatcher.onError` forward to Sentry when `SENTRY_DSN` dart-define is
  set at build time. Without the define, falls back to debug logging (safe default).
- **To activate:** create a free Sentry project → pass
  `--dart-define=SENTRY_DSN=https://...` to `flutter build`.

---

## 🟠 High — clean up soon

### [x] 4. Promo-code → premium dead code — RESOLVED (2026-06-07)
- Removed `redeemPromoCode`, `togglePremium`, `grantPremiumViaIap` from
  `profile_service.dart` (all 0 call sites). The `redeem_promo_code` RPC +
  `promo_codes` tables remain in the DB but are now unreferenced (harmless; drop
  later if desired).

### [x] 5. Stale BLOCKERS.md — RESOLVED (2026-06-07)
- Rewrote `docs/internal/BLOCKERS.md`: pruned the moot Spotify-connect / APK /
  Supabase-unverified blockers; only the image-share-export item remains active.

### [x] Bonus: 흰천장 community stats wouldn't open — RESOLVED (2026-06-07)
- `item_rating_stats` / `snapshot_item_ratings` used `comparisons >= 1`, which
  dropped valid directly-scored ratings (elo≠1000, 0 duels) → a 3-rater song
  counted as 2, under the min_n=3 privacy threshold. Filter changed to
  `comparisons >= 1 OR elo <> 1000` (migration 0024).

---

## ✅ Verified healthy (no action)
- RLS enabled on all 12 tables (api_cache, api_rate, comparisons,
  deletion_requests, follows, item_rating_daily, items, profiles, promo_codes,
  promo_code_redemptions, ratings, reviews).
- Web client exposes only `NEXT_PUBLIC_SUPABASE_ANON_KEY` + URL — no secrets.
- Privacy policy page live, references data deletion + a contact email.
- In-app account deletion does a real cascade delete via the `delete-account`
  edge function (see #1, resolved).
- Empty-state widgets present across home / library.
- Last.fm / MusicBrainz proxies are cached + method/entity-allowlisted +
  token-bucket rate-limited (deployed 2026-06-06).

---

## ⚪ Missing / recommended (not blocking)

### Legal / store
- [x] **Terms of Service page** — created at `web/app/terms/page.tsx` (2026-06-16).
- [ ] Automate deletion processing (folds into #1).

### Features (nice-to-have, post-launch)
- [x] **Crash/error reporting** — Sentry wired; activate with `--dart-define=SENTRY_DSN=...`.
- [x] **Share / image export** — re-enabled (2026-06-16). Platform guards for web/iOS added.
      Save-to-gallery button added (Android/iOS). Topster now flush tile layout. Review card
      ring stroke fattened. Galaxy share sheet issue resolved via dedicated save button.
- [x] **First-run onboarding** — 3-page tour (pairwise demo, ranking preview, share/compare) added in v1.6.0. Shown once to unauthenticated first-time visitors; `onboarding_done` persisted in secure storage.
- [ ] **Friend-activity push notifications** — retention.
- [ ] **Search history / recently searched.**

---

## Suggested order
1. #1 + #2 together (legal / policy risk) — deletion edge function + email confirm.
2. #3 (crash guard + Sentry) — operational visibility before real users.
3. #4 + #5 (dead-code + doc cleanup).
4. ⚪ ToS page, then post-launch features.
