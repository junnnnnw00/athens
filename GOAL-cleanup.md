# GOAL — Athens 전 플랫폼 클린업 (Play Billing 이전 안정화)

> 사용법: 아래 코드블록 본문을 `/goal` 뒤에 붙여 무인 실행. 기존 문서 체계 그대로 사용
> (PROGRESS.md=진행/핸드오프, DECISIONS.md=결정·프로포절, BLOCKERS.md=막힌 것,
> IDEAS.md=안 만든 아이디어, ACCEPTANCE.md=사람 수락 필요).
>
> Google Play Billing / 스토어 연계 / 후원·premium UI 변경은 이번 스코프 밖 — 계정 심사 끝난 뒤 별도 진행.

---

```
/goal Athens 전 플랫폼(web/macOS/iOS/Android) 클린업 — 코드 스파게티 정리 + 네비게이션/레이아웃 UX 버그 수정 + 미래 작업 대비 부채 정리. 무인 실행: 작은 단위 커밋, 매 단계 make analyze && make test 통과 후 진행. 기존 문서 체계 사용(PROGRESS.md=진행/핸드오프, DECISIONS.md=결정·프로포절, BLOCKERS.md=막힌 것, IDEAS.md=안 만든 아이디어, ACCEPTANCE.md=사람 수락 필요). PROMPT.md 스코프 유지, 새 외부 API·새 테이블 금지. 디자인은 기존 정제만(ONE accent, ONE type).

⛔ 이번 스코프 밖(절대 하지 말 것 — 계정 심사 끝난 뒤 별도 진행):
- Google Play Billing / 인앱결제 구현 금지.
- Play Store 연계·제출·스토어 메타데이터 작업 금지.
- 후원/premium 업그레이드 UI(premium_upgrade_screen.dart, Ko-fi 링크, 텀블벅 문구) 변경 금지 — 그대로 둘 것.
- DECISIONS.md 의 Play Billing 프로포절 건드리지 말 것.
단, 위 작업이 나중에 깔끔히 얹히도록 promo-code/redeem/is_premium 로직과 토대는 보존.

=== 완료 정의 (Definition of Done) ===

[A. 탭 스코프 네비게이션 정상화 — 최우선, 사용자 핵심 불만]
현재: router.dart 단일 ShellRoute + FloatingNav 2탭(Home=0, Me=1, 가운데 Add=검색). /item/:id, /friends/compare/:id, /profile/edit 등이 탭 비소속 flat 공유 라우트라 진입 탭을 잃음. 진입 방식도 뒤죽박죽(library_screen 은 context.go('/item') 로 스택 갈아엎고, home/compare 는 push).
목표 동작:
- 홈에서 곡 세부 → Home 스택에 push, Home 하이라이트 유지, 뒤로가기→홈.
- Me(라이브러리/프로필/스탯/친구)에서 곡 세부·비교·편집 → Me 스택에 push, Me 하이라이트 유지, 뒤로가기→직전 Me 화면.
- 탭 전환 후 복귀해도 각 탭 스택·스크롤 위치 보존.
구현(기존 router.dart 골격 재사용):
1. ShellRoute → StatefulShellRoute.indexedStack. 2 브랜치: Branch0(Home)=/home+하위(/duel,/duel/:focusId); Branch1(Me)=/library,/stats,/profile,/profile/edit,/friends,/friends/compare/:id. /search(Add)·/share 는 의도에 맞게 배치.
2. /item/:id 는 양 탭에서 진입 → 활성 브랜치 네비게이터에 push(각 브랜치 하위 등록 또는 활성 브랜치 navigator push). 진입 탭 스택에 쌓여 탭 컨텍스트·하이라이트 보존, FloatingNav 가 detail 위에서도 보이고 올바른 탭 켜질 것.
3. 진입 방식 통일: 탭 전환만 goBranch, 하위 페이지는 전부 push. context.go 30곳 전수 검토 — library 의 go('/item'), go('/profile') 등 스택 갈아엎는 호출 교체.
4. _AppShell 의 _navIndex 휴리스틱(library/profile/stats/friends→전부 1) 제거 → StatefulShellRoute currentIndex 를 진실 소스로 FloatingNav 하이라이트 구동.
5. 백 동작: Android 하드웨어 백 + 데스크톱/웹 브라우저 백 모두 — 브랜치 스택 남으면 pop, 루트면 의도된 동작. PopScope 보장. 웹은 브라우저 히스토리와 일관되게.
6. 검증(전 플랫폼): home→search→item→back, me/library→item→back, me/friends→compare→item→back, profile→edit→back. 탭 유지·복귀 순서 PROGRESS.md 표로 기록.

[B. 플로팅 네비 가림 — 최우선, 전 플랫폼]
FloatingNav 는 Stack 오버레이(높이 ≈ 78px: container 42 + bottom 18 + padding 18). 스크롤 화면 하단이 pill 에 가림(friend_list_screen.dart:144 ListView 하단 패딩 AppSpacing.sm 뿐).
7. 단일 상수 kFloatingNavHeight 정의 → 스크롤 가능한 전 화면(friend_list, library, stats, profile, friend_comparison, search 등) 하단 패딩에 이 값 + SafeArea bottom 반영. 마지막 아이템이 pill 위로 완전 노출되는지 화면별·플랫폼별(웹/맥 큰 창, 모바일 작은 화면) 검증.
8. 빈 상태/짧은 리스트에서도 레이아웃 안 깨짐 확인.

[C. 코드 스파게티 정리 — 동작 100% 보존 순수 리팩터]
9. 거대 파일 분해: friend_comparison_screen.dart(1527줄), search_screen.dart(843줄), stats_screen.dart(784줄) 를 위젯/섹션 단위 분리. 추출 위젯은 features/<area>/widgets/. 한 파일 한 책임.
10. 중복 제거: 반복 카드/리스트타일/섹션헤더/패딩을 공용 위젯·상수로. 매직넘버 → AppSpacing/디자인 토큰.
11. 리팩터는 작은 커밋으로 쪼개고 각 커밋 후 analyze+test 그린 유지.

[D. 미래 대비 부채 정리 — 멀티플랫폼 토대]
12. Spotify 사용자-연동 죽은 코드 완전 제거(commit 8f556d2 미완, 현재 88 참조 잔존). 제거: lib/features/spotify_connect/ 전체, lib/api/spotify_pkce_service.dart, Spotify PKCE OAuth 흐름, AndroidManifest 의 athens://spotify-callback intent-filter + flutter_deeplinking_enabled 잔재, 그 흐름만 쓰는 app_links·crypto 의존성(타 사용처 없음 확인 후 pubspec 제거).
    ⚠️ 보존: Spotify 앱-토큰 카탈로그 검색(edge function spotify-app-token, 서버 자격증명, iTunes fallback)은 PROMPT.md 핵심 데이터 경로 — lib/api/spotify_api.dart 의 카탈로그 검색부와 catalog_service 연동 유지. "사용자 OAuth 연동"만 제거, "앱-토큰 검색"은 남길 것. 둘을 코드에서 명확히 분리.
13. 에러 삼킴 정리: catch(_)/빈 catch 42곳 감사. 무음 실패를 (a) 의도된 fallback 이면 주석 1줄로 이유 명시, (b) 사용자에게 보여야 하면 에러 상태/스낵바로 surface. 특히 동기화·네트워크 경로.
14. 멀티플랫폼 분기 정리: Platform.is / kIsWeb 11곳을 헬퍼(예 lib/api/platform.dart)로 모으거나 일관 패턴화. 4개 플랫폼 동일 화면에서 상태(로딩/빈/오프라인/에러) 누락 점검.
15. 죽은 코드 일반 정리: 미사용 import/변수/함수/위젯. 단 promo-code/redeem/is_premium 로직 보존.

[E. 검증 게이트 — 전 플랫폼]
16. make analyze 경고 0(현재 0 유지), make test 전부 통과. Spotify 제거 후 깨진 테스트 정리.
17. 실제 구동: make run(macOS) + make web(또는 web-deploy-dev Preview) + make android-install(USB폰), 가능하면 iOS 시뮬. A·B 손으로 클릭, 관찰 PROGRESS.md 기록.
18. 골든 영향 시 make goldens 재생성 후 시각 차 검토.
19. flutter pub outdated 확인 — 안전한 마이너만 별도 커밋. 메이저/호환깨짐은 IDEAS.md 기록만(스코프 밖).

=== 루프 규칙 ===
- PROGRESS.md 다음 미완료 픽 → 작은 단위 구현 → analyze+test → conventional 커밋 → PROGRESS.md 갱신 → 즉시 다음.
- 같은 체크 3회 연속 실패 → BLOCKERS.md 기록 후 독립 다음 작업.
- 순서: A(탭 네비) → B(가림) → D12(Spotify 제거) → C(리팩터) → D13~15(에러·플랫폼) → E(검증).
- 전 플랫폼 대상이라 web 배포 허용. 배포 시 CLAUDE.md Deploy Checklist 준수(make web-deploy, alias 재핀). vercel deploy 직접 금지.
- 끝나면 클린 상태 DoD 전 항목 통과 결과를 PROGRESS.md 에 붙여넣기.
```
