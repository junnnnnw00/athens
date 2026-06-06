# Athens — Build Progress

## v1.4.0 릴리즈 + Google Play Billing 도입 (2026-06-03)

### 전체 배포 현황

| 플랫폼 | 버전 | 상태 |
|--------|------|------|
| 🌐 Web (Vercel) | 1.4.0 | ✅ 라이브 — `athens.vercel.app` |
| 🤖 Android APK (GitHub) | 1.4.0 | ✅ [GitHub Release v1.4.0](https://github.com/junnnnnw00/athens/releases/tag/v1.4.0) |
| 🍎 macOS ZIP (GitHub) | 1.4.0 | ✅ [GitHub Release v1.4.0](https://github.com/junnnnnw00/athens/releases/tag/v1.4.0) |
| 🛒 Android AAB (Play Store) | 1.4.0 | 🔄 업로드 진행 중 — `com.nerdyahh.athens` |

### 배포 검증 (v1.4.0, 2026-06-03)

| Check | Result |
|-------|--------|
| `make analyze` | ✅ No issues found |
| `make test` | ✅ All 134 tests passed |
| `make web-deploy` | ✅ Vercel prod + alias 재핀 (athens.vercel.app / athens-sand.vercel.app) |
| `make android-apk` (GitHub용) | ✅ 70.8MB — GitHub Release v1.4.0 업로드 완료 |
| `make android-aab-store` (Play Store용) | ✅ 55.6MB — STORE_BUILD=true, 패키지명 com.nerdyahh.athens |
| `scripts/release-macos.sh` | ✅ athens-macos.zip — GitHub Release v1.4.0 업로드 완료 |

### 주요 변경 내역

#### [1] Google Play Billing 도입 (핵심)

**전략: dart-define 빌드 플래버 분리**
- `STORE_BUILD=false` (기본) → GitHub APK: 프로모 코드 방식 유지, billing 코드 없음
- `STORE_BUILD=true` → Play Store AAB: Google Play Billing $4.99 일회성 구매

**신규 파일:**
- `lib/api/billing/billing_service.dart` — 추상 인터페이스 (`BillingService`, `PurchaseResult`)
- `lib/api/billing/noop_billing_service.dart` — GitHub 빌드용 no-op (항상 `notSupported`)
- `lib/api/billing/play_billing_service.dart` — Play Store 구현체 (`in_app_purchase` 패키지, 구매·복원·서버검증 흐름)
- `lib/api/billing/billing_providers.dart` — Riverpod Provider (STORE_BUILD 분기)
- `supabase/functions/verify-play-purchase/index.ts` — 구매 토큰 서버검증 Edge Function (Google Play Developer API 호출 → `profiles.is_premium = true`)
- `supabase/migrations/0017_add_play_purchase_token.sql` — `profiles.play_purchase_token TEXT` 컬럼 추가

**수정 파일:**
- `pubspec.yaml`: `in_app_purchase: ^3.2.0` 추가
- `features/premium/premium_upgrade_screen.dart`: Google Play 결제 카드 + 구매복원 버튼 추가 (kStoreBuild 조건부)
- `features/profile/profile_service.dart`: `grantPremiumViaIap()` 메서드 추가
- `Makefile`: `android-apk-store`, `android-aab-store` 타겟 추가, `deploy-functions`에 `verify-play-purchase` 포함
- `android/app/build.gradle.kts`: `applicationId` / `namespace` → `com.nerdyahh.athens` (Play Console 등록명 맞춤)

**Product ID:** `athens_premium` ($4.99, 일회성)

#### [2] 버전 bump
- `1.3.12+10312` → `1.4.0+10400`
- Git tag: `v1.4.0`

### Play Store 배포 잔여 수동 작업

- [ ] Play Console 인앱 제품 `athens_premium` $4.99 등록 + 활성화
- [ ] Google Cloud 서비스 계정 JSON 발급
- [ ] `supabase secrets set GOOGLE_PLAY_PACKAGE_NAME=com.nerdyahh.athens`
- [ ] `supabase secrets set GOOGLE_SERVICE_ACCOUNT_JSON='...'`
- [ ] `make deploy-functions` (verify-play-purchase Edge Fn 배포)
- [ ] Supabase Dashboard SQL — `0017_add_play_purchase_token.sql` 실행
- [ ] Play Console 내부 테스트 → 프로덕션 검토 제출

---

## Cleanup run (2026-06-03) — GOAL-cleanup.md

Full spec in `GOAL-cleanup.md`. Order: A(탭 네비)→B(가림)→D12(Spotify)→C(리팩터)→D13~15→E.

### [A] 탭 스코프 네비게이션 — DONE (코드), 런타임 검증 대기(E)
- `router.dart`: 단일 `ShellRoute` → `StatefulShellRoute.indexedStack`, 2 브랜치(Home=`_homeNavKey`, Me=`_meNavKey`).
  - Branch0 Home: `/home`(+child `item/:id`), `/duel`, `/duel/:focusId`, `/search`(+child `item/:id`), `/share`.
  - Branch1 Me: `/library`(+`item/:id`), `/stats`, `/profile`(+`edit`), `/friends`(+`compare/:id`(+`item/:id`)).
  - `/premium-upgrade`, `/auth`, `/landing` = 루트 네비게이터(탭바 없음).
- `/item/:id` 를 공용 헬퍼 `_itemRoute()` 로 각 리스트 부모 아래 **상대 경로 자식**으로 등록 → 호출부를 상대 `push('item/<id>')` 로 변경(home/library/friends_comparison/search 4곳). 진입한 탭 네비게이터에 스택되어 탭 하이라이트·FloatingNav 유지.
- `_AppShell._navIndex` 휴리스틱 제거 → `navigationShell.currentIndex` 가 진실 소스.
- 하드웨어/브라우저 백: `PopScope` — 현재 브랜치 pop 가능하면 pop, 루트면 비-Home→Home 복귀, Home 루트에서만 종료 허용.
- `item_detail` 삭제 후: `go('/library')` → `canPop?pop:go('/library')` (진입 탭 유지).
- 검증: `make analyze` 0, `make test` 128 pass. **런타임 클릭 검증은 E 단계에서.**

### [B] 플로팅 네비 가림 — DONE (코드), 런타임 검증 대기(E)
- `tokens.dart`: `AppLayout` 추가 — `floatingNavHeight=78`(단일 소스) + `scrollBottomInset(context)` = nav + `AppSpacing.md` + `MediaQuery.viewPadding.bottom`.
- 하드코딩 매직넘버(`bottom: 110/130`) 전부 제거 → `AppLayout.scrollBottomInset(context)` 로 교체. 적용 스크롤뷰 14곳: home, profile, stats, library(목록+빈상태), search(결과+스켈레톤+추천), friend_list(검색결과+빈상태+친구목록), friend_comparison(개요탭×2+곡목록), item_detail, profile_edit, duel.
- 검증: `make analyze` 0, `make test` 128 pass(골든 불변).

### [D12] Spotify 사용자-OAuth 죽은코드 제거 — DONE
- 삭제 파일: `lib/api/spotify_pkce_service.dart`, `lib/features/spotify_connect/spotify_connect_screen.dart`(미사용·미라우팅).
- `spotify_api.dart`: `getRecentlyPlayed()`(추상+구현)·`parseRecentlyPlayed()`·PKCE import 제거. **`search()` + `_appToken()`(앱-토큰 카탈로그 검색)은 보존** — `recentlyPlayedProvider` 는 이미 Last.fm 사용 중이라 Spotify 최근재생은 죽은 코드였음.
- `main.dart`: 빈 스텁이던 `app_links` 딥링크 배선 전부 제거 → `AthensApp` 을 `ConsumerStatefulWidget`→`ConsumerWidget` 으로 단순화.
- `AndroidManifest.xml`: `athens://spotify-callback` intent-filter + `flutter_deeplinking_enabled` 메타 제거.
- `pubspec.yaml`: `app_links`·`crypto` 의존성 제거(PKCE 전용이었음). `flutter_secure_storage` 는 i18n 언어설정에 쓰여 보존(주석만 수정).
- `i18n.dart`: 미사용 키 `home_spotify_connect`, `home_spotify_connect_desc`, `profile_spotify_sub` 제거.
- Spotify 참조 88→30(남은 건 전부 앱-토큰 검색/`source:'spotify'` 데이터ID/fallback 주석).
- 검증: `make analyze` 0, `make test` 128 pass.

### [C] 스파게티 정리 — 부분 DONE
- `stats_screen.dart` 784→380줄: 프레젠테이션 위젯 7개(_BigStat·_SectionTitle·_InsightCard·_ScoreDistributionChart·_TagBar·_PreferenceBar·_ActivityChart)를 `stats/widgets/stats_charts.dart` 로 `part` 분리(같은 라이브러리 유지 → private 접근 보존, 동작 무변).
- `search_screen.dart` 845→238줄: leaf 위젯(_LoadMoreShimmer~_RecommendationsSkeleton)을 `catalog/widgets/search_widgets.dart` 로 `part` 분리.
- `friend_comparison_screen.dart`(1487줄 단일 State 클래스): `part` 분리 불가(top-level 단위만 분리됨) → 위젯 추출 리팩터 필요, 회귀 위험 커서 별도 PR 로 **의도적 연기**(IDEAS.md 기록).
- 검증: `make analyze` 0, `make test` 128 pass(stats 골든 불변).

### [D14] 멀티플랫폼 분기 정리 — DONE
- 신규 `lib/api/platform.dart` `AppPlatform`(isWeb/isAndroid/isIOS/isMacOS/isMobile/supportsInAppUpdate) — `dart:io` Platform 접근을 `kIsWeb` 가드 뒤 단일 파일로 집중.
- 5개 분기 사이트 마이그레이션(duel 햅틱, platform_storage, update_service×2, update_banner). `dart:io` 직접 import 4→1(File/Process 쓰는 곳만 잔류; update_banner 의 `Platform.resolvedExecutable` 는 경로용이라 유지).
- 검증: `make analyze` 0.

### [D13] 에러 삼킴 감사 — DONE (결론: 무음 사용자-액션 실패 없음)
- 39개 `catch(_)` 전수 검토. 대부분 의도된 best-effort(태그 enrichment·동기화·로컬 캐시·언어설정 저장) 또는 fallback(launchUrl 모드)이며, 네트워크/데이터 에러는 UI 의 `AsyncValue.when` 에러 분기로 이미 surface 됨 → 새 SnackBar 중복 추가 안 함.
- 의도가 불명확하던 곳에 "왜 무음인지" 주석 추가: home 새로고침, friend_list 새로고침, i18n 언어저장, platform_storage load/save, profile launchUrl×2.
- ⛔ `premium_upgrade_screen.dart`(line 468)는 스코프 밖이라 미변경.
- 검증: `make analyze` 0.

### [D15 / E19] 죽은코드·의존성 — DONE
- 일반 죽은코드는 D12(Spotify) + `make analyze` 0(미사용 import/var 없음)로 정리됨.
- `flutter pub outdated`: 신규 버전 있는 54개는 전부 **major/제약 비호환**(riverpod 3, go_router 17, freezed 3 등) — 안전한 마이너 없음. 메이저 업그레이드는 스코프 밖 → 별도 작업으로 IDEAS 처리.

### [E] 검증 게이트 — 자동 검증 DONE (수동 클릭은 MORNING-CHECKLIST)
클린 상태 fresh 결과(2026-06-03):
| Check | Result |
|------|--------|
| `make analyze` | ✅ No issues found |
| `make test` | ✅ All 128 tests passed (골든 불변) |
| `flutter build macos --debug` | ✅ `✓ Built ...Athens.app` (exit 0) |
| macOS 런타임 부팅 | ✅ Supabase init 완료, **GoException/RenderFlex/Exception 없음** → StatefulShellRoute·shell·screens 런타임 정상 구성 |
| `flutter build web` | ✅ `✓ Built build/web` (exit 0) → `dart:io` 중앙화 웹 안전 확인. wasm 경고는 기존 `flutter_secure_storage_web`(이번 변경 무관) |
| `make web-deploy` (prod) | ✅ Deploy Checklist 준수 → Vercel prod + alias 재핀(athens.vercel.app/athens-sand). 라이브 `/`·`/app`·`/privacy` 전부 200 (2026-06-03 15:08) |
| 골든 | ✅ 재생성 불필요(불변) |

**A 자동 검증 추가(2026-06-03):** `test/widget/navigation_test.dart` — 실제 라우터 shell 을 마운트해 4개 시나리오 자동 검증, 전부 통과:
| 시나리오 | 단언 | 결과 |
|---|---|---|
| 부팅 | HomeScreen + FloatingNav, currentIndex=0 | ✅ |
| Home→item→back | ItemDetailScreen 에서 nav 보임 + index=0 유지, back→Home | ✅ |
| Me(library)→item→back | index=1 유지(Me 탭), back→Library | ✅ |
| 탭 전환(Me→Home) | currentIndex 정확 전환 | ✅ |
- 이를 위해 router.dart 의 shell 을 `buildAppShellRoute()` 로 추출(auth 게이트 없이 테스트 마운트 가능). 총 테스트 128→132.

**남은 수동 항목(human, 디바이스 필요):** B 가림 시각 확인 + Android 하드웨어 백 체감 + `make android-install` → MORNING-CHECKLIST.md 의 "Cleanup run" 매트릭스. (A 핵심 동작은 위 자동 테스트로 검증됨.)

### 요약
A(탭 네비)·B(가림)·D12(Spotify 제거)·D13(에러 감사)·D14(플랫폼 헬퍼) **완료**. C 는 stats·search 분리 완료, friend_comparison 은 의도적 연기(IDEAS). 모든 단계 analyze 0 / test 128 / 빌드(macOS·web) green.

## Current State (2026-06-02)

Rebuilt from "compiles-but-mockup" into working software per ACCEPTANCE.md + DESIGN.md.
The runtime now renders only real data through Riverpod → repository → Drift/APIs.

### DoD + ACCEPTANCE checks (fresh, this machine)

| Check | Status | Evidence |
|-------|--------|----------|
| 1. `flutter analyze` | ✅ 0 issues | "No issues found! (ran in 4.9s)" |
| 2. `flutter test` | ✅ 128 pass | full suite green after the final cleanup |
| 2. rank-domain coverage ≥90% | ✅ 98.9% | 91/92 lines (elo/score/pair_selector/stats_engine) |
| 3. `flutter build apk --debug` | ✅ exit 0 | "✓ Built build/app/outputs/flutter-apk/app-debug.apk" (openjdk@17 + Android SDK 35, 290s) |
| 4. `flutter build web` | ✅ exit 0 | background build completed |
| 5. `npm ci && npm run build` (web) | ✅ exit 0 | background build completed |
| 6. SQL sqlfluff clean + RLS + view + edge fns | ✅ | sqlfluff exit 0; 5 tables RLS; `public_profiles`; 2 edge fns |
| 7. No secrets + complete `.env.example` | ✅ | secret-leak grep returns nothing |
| 8. Docs complete | ✅ | README, LICENSE, CONTRIBUTING, SETUP, SPOTIFY, TAGS, ARCHITECTURE, RUN |
| 9. PROGRESS/DECISIONS/BLOCKERS/MORNING/IDEAS | ✅ | all present + updated |
| 10. Commit history + milestone tags | ✅ | conventional commits; tags m0–m7 |

### ACCEPTANCE gates

| Gate | Status |
|------|--------|
| A1 no hardcoded display data | ✅ all via providers → repository |
| A3 no unfinished paths / dead controls | ✅ grep clean; every control wired |
| A4 fakes only in test/ | ✅ grep "Fake" in lib/ clean |
| A5 ranking engine real | ✅ asserted in domain tests |
| B1–B10 features proven by tests | ✅ repo persist/restart, parsers, search/home widget, integration loop |
| C custom theme (mint, Hanken) | ✅ `lib/theme`; D4 assertion test passes |
| D3 integration_test core loop | ✅ search→add→duel→library→stats→share green |
| D5 committed goldens | ✅ 11 PNGs in `app/test/golden/` (dark+light + IG card) |
| D6 RUN.md | ✅ written |
| secret-leak grep | ✅ returns nothing |

## Infrastructure Separation for Crowdfunding (2026-06-01)

- **Crowdfunding Planning**: Brainstormed paid feature ideas, App Store compliance, and crowdfunding platforms (Tumblbug, etc.). Created `funding_and_premium_features_plan.md` in conversation artifacts.
- **Git Branching Strategy**: Checked out `dev` branch to isolate crowdfunding & premium features development.
- **Environment Isolation**:
  - Created `app/config/app_config_dev.json` to configure the `athens-dev` Supabase project.
  - Added Makefile commands `run-dev` and `run-dev-seed` for running with development configurations.
  - Added Makefile command `web-deploy-dev` and script `scripts/deploy-web-dev.sh` to trigger Vercel Preview/Preview builds, preventing impact on the live production URL.
  - Updated documentation files `RUN.md` and `docs/SETUP.md` to explain how to configure and run the isolated development environment.

## What changed this run

- `lib/theme/` (tokens + ThemeData, dark+light, mint accent, Hanken/Pretendard bundled).
- Signature widgets: ScoreRing, CoverArt, FloatingNav, FilterChips.
- `LibraryRepository` over Drift = single source of truth; duels persist + survive restart.
- Real API impls (Spotify/iTunes/Last.fm/MusicBrainz); fakes moved to `test/fakes/`.
- Every screen rewritten to the design system + wired (no dead controls).
- `dev_seed.dart` (kDevSeed) seeds the real data layer.
- Tests: theme, repository persistence, API parsers, search/home widgets,
  integration core loop, golden screens. `.sqlfluff` config; migrations reformatted clean.
- Docs: README design section + RUN.md; DECISIONS/BLOCKERS/MORNING/IDEAS updated.
- Last.fm recent-tracks root cause fixed: the API already returns newest-first,
   so the home screen now preserves upstream ordering instead of re-sorting and
   accidentally pushing the current track out of position.
- Search genre recommendations now keep the selected genre state stable across
   rebuilds and fall back through available genre candidates before showing an
   empty section.
- Home recent-played cards now carry Last.fm timestamps through the data layer
   so ordering is auditable end-to-end.
- Final deployment completed on 2026-06-02 via `make web-deploy`.
   Production alias pinned to `https://athens.vercel.app` and `https://athens-sand.vercel.app`.
   Build finished cleanly after the unused import warning in `app/lib/main.dart` was removed.

## Milestone history (tags)

M0 scaffold · M1 ranking engine · M2 auth+sync · M3 catalog+tags · M4 spotify ·
M5 library+stats · M6 share+web · M7 OSS polish — tags `m0`–`m7`.

## Next (human, see MORNING-CHECKLIST)

Supabase `db reset` (Docker), deploy edge functions with secrets, register Spotify
+ Last.fm keys, Vercel deploy, physical-device flow test.

## Deployment prep (2026-05-31)

- Hid the unstable image-share entry point from the Profile UI while keeping the route/code intact for later repair.
- Switched initial public profile URL references to `https://athens.vercel.app` and added matching Next metadata.
- Added Vercel alias `athens.vercel.app` and deployed production `web-co5nu0x24-junwoo-hong-s-projects.vercel.app`.
- Fresh checks: `cd web && npm run build` ✅, `cd app && flutter analyze` ✅, `cd app && flutter test` ✅, live `https://athens.vercel.app` 200 ✅, `/u/unknown` 404 ✅.

## Flutter web production deploy (2026-05-31)

- Built Flutter web with hosted client config: `cd app && flutter build web --dart-define-from-file=config/app_config.json`.
- Created Vercel project `athens`, disabled SSO deployment protection, and deployed the Flutter static bundle.
- Repointed `https://athens.vercel.app` to `athens-mrgnkmvds-junwoo-hong-s-projects.vercel.app`.
- Fresh checks: live root 200 ✅, root serves `flutter_bootstrap.js` ✅, manifest is Athens-specific ✅, `cd app && flutter analyze` ✅.

## Single unified web app — DONE (2026-05-31)

**Goal met:** ONE stable website (`web` Next.js project) now serves the Flutter app
AND the public profile view. `athens.vercel.app` aliased to it. Decision + rationale
in DECISIONS.md → "Web deployment — single unified site".

**Layout (live):** `/` = landing · `/u/[handle]` = SSR profile · `/app/*` = Flutter
web (static in `web/public/app/`, hash routing → no deep-link rewrites).

**Done:**
1. [x] `web/next.config.ts` — rewrite `/app` → `/app/index.html`.
2. [x] Real landing `web/app/page.tsx` (mint tokens, hero + feature grid + CTA→/app).
3. [x] `profile_view.tsx` footer → `/app`; Flutter `og:url` → `/app`.
4. [x] `web/.gitignore` ignores `/public/app`; `web/.vercelignore` ships it on deploy.
5. [x] Makefile `web-flutter` / `web-build` / `web-deploy` pipeline.
6. [x] Retired old `app/web/vercel.json` (app-at-root config).

**Deploy gotcha solved:** local `vercel build` inlines empty NEXT_PUBLIC_* (Production
env vars are sensitive → `vercel pull` returns ""), which 404'd profiles. Fixed by
deploying via **remote build** (`vercel deploy --prod`, real env injected) + a
`.vercelignore` that omits `public/app` so the gitignored Flutter bundle still uploads.

**Fresh live checks (athens.vercel.app, 2026-05-31):**
| Path | Code | Note |
|------|------|------|
| `/` | 200 | landing renders ("앱 시작하기") |
| `/app` | 200 | `<base href="/app/">`, flutter_bootstrap.js |
| `/app/main.dart.js` | 200 | bundle asset |
| `/u/nerdyahh_` | 200 | SSR, real data, `<title>nerdyahh_ — Athens</title>`, `x-matched-path /u/[handle]` |
| `/u/__nope__` | 404 | notFound works |

`cd web && npm run build` ✅ · local `next start` smoke ✅ · `cd app && flutter build web` ✅.

**Cleanup left for human (optional):** the now-orphaned `athens` Vercel project (old
Flutter-only deploy) can be deleted in the dashboard; nothing points to it anymore.

## Rich item info feature — DONE (2026-05-31)

Implemented and deployed the rich item search/detail info feature, resolving the remaining steps from the previous agent.

### Scope completed
- **Facts**: year, album, and duration (mm:ss) rendered dynamically in a row.
- **Last.fm stats**: listener and play count formatted beautifully (e.g. 1.2M, 99K).
- **MusicBrainz proxy**: Deployed `musicbrainz-proxy` to hosted Supabase to avoid CORS blocks on web.
- **Artist details**: Bio summary and a list of popular tracks (tappable to trigger a search).

### Implementation
1. [x] **Render the info on the detail screen**: Created `_InfoSection` inside `item_detail_screen.dart`, fetching metadata reactively on-demand using `itemInfoProvider`.
2. [x] **Deploy Edge Function**: Registered and deployed `musicbrainz-proxy` to Supabase hosted functions (added to Makefile `deploy-functions`).
3. [x] **Tests & Goldens**: Wrote unit tests for Last.fm track/artist/top-tracks and MusicBrainz year parsers. Regenerated golden screens (`item_detail_light` / `item_detail_dark`) to reflect the new layout.
4. [x] **Production Deploy & Alias**: Ran `make web-deploy` to trigger remote build with sensitive env vars on Vercel, then repointed `athens.vercel.app` alias to the new deployment. Smoke-tested all endpoints successfully (200 OK).

## Web app bug fixes (2026-05-31)

Two issues reported after the unified deploy:

1. **Spotify connect on web → "redirect_uri Not matching configuration".**
   Implemented the web PKCE flow (per request to support it on web): web redirect
   URI is the app entry `${origin}/app/`, launched same-tab (`webOnlyWindowName:
   '_self'`); Spotify returns to `/app/?code=…` and `main.dart`'s boot-time
   `handleCallback(Uri.base)` exchanges it (detection now by `?code` presence on
   web, guarded by the stored verifier). Desktop stays gated. `spotify_pkce_service.dart`
   + `spotify_connect_screen.dart`. **Manual step:** register
   `https://athens.vercel.app/app/` in the Spotify dashboard (MORNING-CHECKLIST §2)
   — without it the mismatch persists.

2. **Rated library empty in the app, but present on `/u/<handle>`.** Root cause:
   `LibraryRepository.loadLibrary()` read **only** the local Drift cache; sync was
   push-only. A fresh web browser has an empty Drift, so the library looked empty
   even though the ratings were in Supabase (which is what the public profile reads).
   Fix: added a **remote pull**. `SupabaseGateway.getRatingsWithItems()` fetches
   ratings joined with their catalog items; `LibraryRepository.pullRemote()` hydrates
   Drift from it (reconciling on `source:source_id`, last-write-wins so newer local
   edits aren't clobbered); `LibraryController.build()` pulls before loading. This
   also gives real cross-device sync on mobile, not just web.

**Checks:** `flutter analyze` 0 issues ✅ · `flutter test` all pass (added 2 pull
tests: fresh-device hydrate + last-write-wins) ✅ · rebuilt + redeployed; live
`athens.vercel.app` `/`, `/app`, `/app/main.dart.js`, `/u/nerdyahh_` all 200 ✅.
Web login + pull round-trip to be eyeball-confirmed by signing in on the site.

## Search rate-limit fix + artist images (2026-05-31)

**Symptoms reported:** songs that exist don't appear; "10+ results but not all
shown"; no load-more; artist profile photos missing even for famous artists.

**Root cause (verified live):** Spotify dev-mode **search** API was app-level
rate-limited — `api.spotify.com/v1/search` → `HTTP 429`, `retry-after: ~530s`
(token endpoint stayed 200). Search silently fell back to iTunes, which has
poorer track coverage AND returns NO artist artwork (`musicArtist` results have
no `artworkUrl`), so artists rendered as initials.

**Why the quota burned:** `spotify-app-token` minted a fresh token on *every*
call; 'all' search fired 3 parallel Spotify calls per query; `_enrichArtistImages`
added a `/v1/artists?ids=` call (a dev-mode-forbidden bulk-metadata endpoint).

**Fixes (commit a71e8a0):**
1. Edge fn `spotify-app-token`: module-scope token cache, refresh 60s pre-expiry
   (per-isolate; cross-isolate sharing not guaranteed but client cache dominates).
2. `SpotifyApiHttp`: client-side token cache (holds one token ~1h); `market=KR`
   for consistent/broader search; 429 → typed `SpotifyRateLimitException`.
3. `CatalogService` 'all' mode: ONE combined `type=track,album,artist` call
   (1/3 the quota); unified pagination so 'all' loads more too.
4. Removed `_enrichArtistImages`/`fetchArtistImages` — search payload already
   carries artist images; the bulk endpoint was forbidden + wasteful.

**Two further root causes found + fixed (commit 4f30195):**
5. **Spotify dev-mode caps `/search` `limit` at 10** — `limit>10` → HTTP 400
   "Invalid limit" (verified: 10→200, 11→400; offset paging fine to ~1000).
   The app used limit=20 everywhere → *every* Spotify search 400'd → silent
   iTunes fallback (≤20 results, no artist artwork). This — not the 429 — was
   the dominant cause of "results cap out / no artist photos". Set
   `kSearchPageSize=10`; more results via `offset` paging. Dropped the
   speculative `market=KR` (it filters tracks unlicensed in-market). With
   Spotify search succeeding, artist images return from the search payload.
6. **Web landing + profiles were dead** (`/`, `/u/[handle]` → 404). Vercel
   project had `framework: null` → served only static `public/`, ignored Next
   routing; the Flutter bundle at `/app` masked it. Project also had ZERO env
   vars → `NEXT_PUBLIC_SUPABASE_*` empty → every profile `notFound()`. Fix:
   pinned `framework: nextjs` via `web/vercel.json`; added
   `NEXT_PUBLIC_SUPABASE_URL` + `NEXT_PUBLIC_SUPABASE_ANON_KEY` (publishable,
   public) to the Vercel project (prod+preview+dev).

**Fresh live checks (athens.vercel.app, after final deploy):**
| Check | Result |
|------|--------|
| `/` · `/u/nerdyahh_` · `/app` · `/app/main.dart.js` | all 200 ✅ |
| `/u/nerdyahh_` SSR | `<title>nerdyahh_ — Athens</title>` ✅ |
| Spotify search `limit=10` | 10 tracks + 10 artists, every artist has images ✅ |
| `make analyze` / `flutter test` | 0 issues / 119 pass (added 429→iTunes test) ✅ |

Non-obvious Spotify dev-mode caps saved to agent memory
(`athens-spotify-devmode-limits`).

## Genre stats & Profile Top Genres (2026-05-31)

Added genre preference analysis and a top genres list to the profile page:
1. **Genre/Mood Preferences**: Calculates average scores (preference levels) of rated items per genre and mood in `StatsEngine`, showing users their highest-rated tags alongside volume/frequency.
2. **Profile Top Genres**: Displays the user's top 4 most frequent genres on their profile page as neat chips.
3. **Verification**: Added unit tests to `stats_engine_test.dart` to assert preference calculation accuracy and updated/regenerated stats golden test images. All tests pass and are clean. Deployed unified app to Vercel production.
