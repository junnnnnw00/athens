# PRELAUNCH.md — pre-launch audit & checklist

Audit of the Athens app before public store launch (2026-06-07). Findings from a
code + infra scan, grouped by severity. Each item lists the evidence path, the
risk, and the fix direction. Check off as resolved.

> Verdict: 🔴 items are **launch-blocking** (legal / policy / operational
> visibility). 🟠 are fast cleanups. ✅ verified healthy. ⚪ recommended but not
> blocking.

---

## 🔴 Critical — must resolve before store launch

### [ ] 1. Account deletion is "request only" — nothing actually deletes
- **Evidence:** `web/app/delete-account/page.tsx` inserts a row into
  `deletion_requests`; `supabase/migrations/0018_add_deletion_requests.sql` has
  no processor (no cron / edge / trigger). Requests just pile up.
- **Risk:** Google Play **Data Deletion policy** requires a real deletion path,
  not an unprocessed queue. Compliance + legal exposure.
- **Abuse vector:** RLS policy `"Allow public insert to deletion_requests"` lets
  **anyone insert any email** (the client-side password check is bypassable by
  calling the table directly) → malicious deletion requests / spam against the
  table.
- **Fix:** an authenticated edge function that deletes the **caller's own** data
  by `auth.uid()` (cascade ratings / comparisons / reviews / follows / profile +
  `auth.admin.deleteUser`). Lock the `deletion_requests` RLS to authenticated
  self-inserts (or drop the table in favor of the direct-delete function).

### [ ] 2. Email confirmation is OFF (autoconfirm)
- **Evidence:** `supabase/config.toml` `enable_confirmations = false`;
  `DECISIONS.md` notes hosted `mailer_autoconfirm = true` (a dev workaround for
  the free-tier email rate limit).
- **Risk:** anyone can sign up with **any email they don't own** — no
  verification. Fake accounts, impersonation, signup spam.
- **Fix:** enable confirmations on the hosted project + wire a real SMTP
  provider (e.g. Resend) so confirmation emails actually send. Re-test signup.

### [ ] 3. No top-level crash handling or reporting
- **Evidence:** `app/lib/main.dart` has no `runZonedGuarded` /
  `FlutterError.onError` / `PlatformDispatcher.onError`; no Sentry / Crashlytics
  dependency anywhere.
- **Risk:** field crashes die silently with **zero telemetry** — can't diagnose
  production issues after launch.
- **Fix:** wrap `runApp` in a guarded zone + set `FlutterError.onError`; add a
  crash reporter (Sentry free tier is enough). Scrub PII before sending.

---

## 🟠 High — clean up soon

### [ ] 4. Promo-code → premium is dead code
- **Evidence:** `app/lib/features/profile/profile_service.dart`
  `redeemPromoCode()` + `redeem_promo_code` RPC still "unlock premium", but
  premium was removed (`UserProfile.isPremium` hardcoded `true`).
- **Risk:** confusing dead path; the RPC may still mutate `is_premium`.
- **Fix:** remove `redeemPromoCode` + the promo UI; drop/neutralize the RPC and
  `promo_codes` / `promo_code_redemptions` if unused. Note in DECISIONS.md.

### [ ] 5. Stale docs (BLOCKERS.md)
- **Evidence:** `BLOCKERS.md` lists Spotify user-connect as an active blocker,
  but the code has no `connectSpotify` / PKCE paths (removed; verified clean).
- **Fix:** prune the resolved Spotify-connect blockers; keep only what's true.

---

## ✅ Verified healthy (no action)
- RLS enabled on all 12 tables (api_cache, api_rate, comparisons,
  deletion_requests, follows, item_rating_daily, items, profiles, promo_codes,
  promo_code_redemptions, ratings, reviews).
- Web client exposes only `NEXT_PUBLIC_SUPABASE_ANON_KEY` + URL — no secrets.
- Privacy policy page live, references data deletion + a contact email.
- In-app account-deletion entry point exists (`profile_screen.dart` → web form);
  only the *processing* is missing (see #1).
- Empty-state widgets present across home / library.
- Last.fm / MusicBrainz proxies are cached + method/entity-allowlisted +
  token-bucket rate-limited (deployed 2026-06-06).

---

## ⚪ Missing / recommended (not blocking)

### Legal / store
- [ ] **Terms of Service page** — none exists (`web/app/terms` absent). Privacy
  policy is present; Play listing generally wants ToS too.
- [ ] Automate deletion processing (folds into #1).

### Features (nice-to-have, post-launch)
- [ ] **Crash/error reporting** (Sentry free) — see #3; essential for triage.
- [ ] **First-duel onboarding tutorial** — orient new users ("what is this app").
- [ ] **Share / image export** — currently hidden via BLOCKERS.md; it's a viral
  surface. Re-enable once the export is reliable.
- [ ] **Friend-activity push notifications** — retention.
- [ ] **Search history / recently searched.**

---

## Suggested order
1. #1 + #2 together (legal / policy risk) — deletion edge function + email confirm.
2. #3 (crash guard + Sentry) — operational visibility before real users.
3. #4 + #5 (dead-code + doc cleanup).
4. ⚪ ToS page, then post-launch features.
