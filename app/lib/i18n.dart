import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api/platform_storage.dart';

const _localeKey = 'athens_locale';

enum AppLanguage {
  ko('ko', '한국어'),
  en('en', 'English');

  final String code;
  final String label;
  const AppLanguage(this.code, this.label);
}

class LocaleNotifier extends StateNotifier<AppLanguage> {
  LocaleNotifier() : super(AppLanguage.en) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final code = await PlatformStorage.read(key: _localeKey);
      if (code == AppLanguage.ko.code) {
        state = AppLanguage.ko;
      } else {
        state = AppLanguage.en;
      }
    } catch (_) {
      state = AppLanguage.en;
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    try {
      await PlatformStorage.write(key: _localeKey, value: language.code);
    } catch (_) {
      // Persisting the preference is best-effort; apply the language regardless.
    }
    state = language;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLanguage>((ref) {
  return LocaleNotifier();
});

class I18n {
  static const Map<String, Map<AppLanguage, String>> _keys = {
    // Auth Screen
    'auth_title': {AppLanguage.ko: '로그인', AppLanguage.en: 'Sign In'},
    'auth_supabase_missing': {AppLanguage.ko: 'Supabase가 설정되지 않았습니다. 로컬 모드로 동작합니다.', AppLanguage.en: 'Supabase is not configured. Running in local mode.'},
    'auth_email': {AppLanguage.ko: '이메일', AppLanguage.en: 'Email'},
    'auth_password': {AppLanguage.ko: '비밀번호', AppLanguage.en: 'Password'},
    'auth_login': {AppLanguage.ko: '로그인', AppLanguage.en: 'Sign In'},
    'auth_signup': {AppLanguage.ko: '계정 만들기', AppLanguage.en: 'Sign Up'},
    'auth_email_sent': {AppLanguage.ko: '확인 이메일을 보냈어요. 메일함을 확인하세요.', AppLanguage.en: 'Check your inbox for a confirmation email.'},
    'auth_enter_email_password': {AppLanguage.ko: '이메일과 비밀번호를 입력해주세요.', AppLanguage.en: 'Please enter your email and password.'},
    'auth_password_min_length': {AppLanguage.ko: '비밀번호는 최소 6글자 이상이어야 합니다.', AppLanguage.en: 'Password must be at least 6 characters.'},
    // Landing Screen
    'landing_desc': {AppLanguage.ko: '두 곡 중 더 끌리는 쪽을 고르면 평가 끝.\nElo가 알아서 순위를 매겨요.', AppLanguage.en: 'Choose the better song to rate them.\nElo calculates your ranking automatically.'},
    'landing_question': {AppLanguage.ko: '어느 곡이 더 좋아요?', AppLanguage.en: 'Which song do you prefer?'},
    'landing_tap_hint': {AppLanguage.ko: '탭해서 골라보세요 →', AppLanguage.en: 'Tap to choose →'},
    'landing_start': {AppLanguage.ko: '시작하기', AppLanguage.en: 'Get Started'},
    'landing_have_account': {AppLanguage.ko: '이미 계정이 있어요 →', AppLanguage.en: 'Already have an account? →'},
    // Home Screen
    'home_title': {AppLanguage.ko: '오늘은 무엇을 평가할까요?', AppLanguage.en: 'What are we rating today?'},
    'home_recent': {AppLanguage.ko: '최근 들은 음악', AppLanguage.en: 'Recently Played'},
    'home_recent_error': {AppLanguage.ko: '최근 재생 목록을 불러오지 못했어요', AppLanguage.en: 'Failed to load recently played tracks'},
    'home_start_duel': {AppLanguage.ko: '듀얼 시작하기', AppLanguage.en: 'Start Duel'},
    'home_start_duel_sub': {AppLanguage.ko: '둘 중 더 좋은 걸 고르면 순위가 매겨져요', AppLanguage.en: 'Choose the better one to rank your music'},
    'home_rate': {AppLanguage.ko: '평가', AppLanguage.en: 'Rate'},
    'home_back_exit': {AppLanguage.ko: '뒤로가기 버튼을 한 번 더 누르면 앱이 종료됩니다.', AppLanguage.en: 'Press back again to exit.'},
    'home_recs_hot': {AppLanguage.ko: '지금 가장 핫한 #{0} 추천 트랙', AppLanguage.en: 'Trending #{0} Tracks'},
    'home_recs_personalized': {AppLanguage.ko: '자주 듣는 #{0} 취향 저격 곡', AppLanguage.en: 'Personalized #{0} Picks'},
    'home_friends_rated': {AppLanguage.ko: '친구들이 평가한 음악', AppLanguage.en: 'Friends\' Rated Music'},
    'home_friend_rated_label': {AppLanguage.ko: '친구가 평가함', AppLanguage.en: 'Rated by a friend'},
    'home_added_toast': {AppLanguage.ko: '"{0}" 추가됨 — 같은 종류를 더 추가하면 순위를 매겨요', AppLanguage.en: '"{0}" added — add more of the same kind to rank them'},
    'home_recent_all_rated': {AppLanguage.ko: '최근 들은 음악을 모두 평가했습니다! 🎉\n음악을 들으면 여기에 나타납니다.', AppLanguage.en: 'All recently played music has been rated! 🎉\nListen to more music to see them here.'},
    'home_recent_connect_lastfm': {AppLanguage.ko: 'Last.fm을 연동하면 최근 들은 곡이 여기에 나타나요.', AppLanguage.en: 'Connect Last.fm to see your recently played tracks here.'},
    'home_connect_lastfm_btn': {AppLanguage.ko: 'Last.fm 연동하기', AppLanguage.en: 'Connect Last.fm'},
    'rate_prompt_track': {AppLanguage.ko: '이 곡은 어땠나요?', AppLanguage.en: 'How was this track?'},
    'rate_prompt_album': {AppLanguage.ko: '이 앨범은 어땠나요?', AppLanguage.en: 'How was this album?'},
    'rate_prompt_artist': {AppLanguage.ko: '이 아티스트는 어땠나요?', AppLanguage.en: 'How was this artist?'},
    'onboarding_title': {AppLanguage.ko: '내 취향 랭킹 시작하기 ({0}/3)', AppLanguage.en: 'Start My Taste Ranking ({0}/3)'},
    'onboarding_desc': {AppLanguage.ko: '곡 보관함이 완성되면 1:1 월드컵 듀얼을 시작하고, 내 음악 취향에 대한 상세한 분석 리포트를 얻을 수 있어요.', AppLanguage.en: 'Once your library is ready, you can start 1:1 duels and get detailed analysis reports on your music taste.'},
    'onboarding_status_0': {AppLanguage.ko: '좋아하는 첫 번째 노래를 검색하고 별점을 주세요. 🎧', AppLanguage.en: 'Search and rate your first favorite song. 🎧'},
    'onboarding_status_1': {AppLanguage.ko: '좋은 시작입니다! 2곡만 더 담으면 첫 번째 듀얼을 붙일 수 있어요.', AppLanguage.en: 'Great start! Add 2 more songs to start your first duel.'},
    'onboarding_status_2': {AppLanguage.ko: '이제 딱 한 곡 남았어요! 한 곡만 더 추가하고 듀얼 매치를 완성해 보세요.', AppLanguage.en: 'Just one more song left! Add it to complete your first duel match.'},
    'onboarding_search_btn': {AppLanguage.ko: '노래 찾으러 가기', AppLanguage.en: 'Go Find Songs'},
    // Library Screen
    'lib_no_rated_title': {AppLanguage.ko: '아직 평가한 음악이 없어요', AppLanguage.en: 'No rated music yet'},
    'lib_no_rated_desc': {AppLanguage.ko: '검색해서 음악을 추가하고 듀얼을 시작하세요.', AppLanguage.en: 'Search music to add them, then start dueling.'},
    'lib_search_music': {AppLanguage.ko: '음악 검색', AppLanguage.en: 'Search Music'},
    'lib_sort_tooltip': {AppLanguage.ko: '정렬', AppLanguage.en: 'Sort'},
    'lib_sort_rank': {AppLanguage.ko: '랭킹순', AppLanguage.en: 'By rank'},
    'lib_sort_recent': {AppLanguage.ko: '최근 평가순', AppLanguage.en: 'Recently rated'},
    'lib_sort_alpha': {AppLanguage.ko: '가나다순', AppLanguage.en: 'Alphabetical'},
    'lib_sort_most_dueled': {AppLanguage.ko: '듀얼 많은순', AppLanguage.en: 'Most dueled'},
    'lib_close_tooltip': {AppLanguage.ko: '닫기', AppLanguage.en: 'Close'},
    'lib_search_hint': {AppLanguage.ko: '내 라이브러리 검색…', AppLanguage.en: 'Search your library…'},
    'lib_clear_tooltip': {AppLanguage.ko: '지우기', AppLanguage.en: 'Clear'},
    'lib_search_tooltip': {AppLanguage.ko: '검색', AppLanguage.en: 'Search'},
    'lib_sync_tooltip': {AppLanguage.ko: '동기화 대기 {0}개 · 탭하여 동기화', AppLanguage.en: '{0} pending · tap to sync'},
    'lib_load_error': {AppLanguage.ko: '라이브러리를 불러오지 못했어요', AppLanguage.en: 'Failed to load library'},
    'lib_empty_filter': {AppLanguage.ko: '이 필터에 항목 없음', AppLanguage.en: 'No items in this filter'},
    'lib_item_not_found': {AppLanguage.ko: '항목을 찾을 수 없어요.', AppLanguage.en: 'Item not found.'},
    'lib_duels': {AppLanguage.ko: '듀얼', AppLanguage.en: 'Duels'},
    'lib_tags': {AppLanguage.ko: '태그', AppLanguage.en: 'Tags'},
    'lib_review': {AppLanguage.ko: '리뷰', AppLanguage.en: 'Review'},
    'lib_review_hint': {AppLanguage.ko: '이 음악에 대한 생각을 적어보세요…', AppLanguage.en: 'Write your thoughts about this music...'},
    'lib_cancel': {AppLanguage.ko: '취소', AppLanguage.en: 'Cancel'},
    'lib_save': {AppLanguage.ko: '저장', AppLanguage.en: 'Save'},
    'lib_write_review_hint': {AppLanguage.ko: '탭해서 리뷰 작성…', AppLanguage.en: 'Tap to write a review...'},
    'lib_delete_confirm_title': {AppLanguage.ko: '라이브러리에서 삭제할까요?', AppLanguage.en: 'Remove from library?'},
    'lib_delete_confirm_desc': {AppLanguage.ko: '이 항목의 평가와 비교 기록이 모두 사라져요.', AppLanguage.en: 'This will delete all ratings and comparison history for this item.'},
    'lib_delete': {AppLanguage.ko: '삭제', AppLanguage.en: 'Delete'},
    'lib_placement_test': {AppLanguage.ko: '재배치고사', AppLanguage.en: 'Placement Duel'},
    'lib_unrated_message': {AppLanguage.ko: '아직 라이브러리에 추가되지 않은 항목입니다.', AppLanguage.en: 'This item has not been added to your library yet.'},
    'lib_add_to_library': {AppLanguage.ko: '라이브러리에 추가', AppLanguage.en: 'Add to Library'},
    'lib_listeners_count': {AppLanguage.ko: '청취자 {0}', AppLanguage.en: '{0} Listeners'},
    'lib_play_count': {AppLanguage.ko: '재생수 {0}', AppLanguage.en: '{0} Plays'},
    'lib_genres_label': {AppLanguage.ko: '장르', AppLanguage.en: 'Genres'},
    'lib_popular_tracks': {AppLanguage.ko: '인기 트랙', AppLanguage.en: 'Popular Tracks'},
    'community_rating': {AppLanguage.ko: '커뮤니티 평가', AppLanguage.en: 'Community Rating'},
    'community_rated_count': {AppLanguage.ko: '{0}명 평가', AppLanguage.en: '{0} ratings'},
    'average_score_trend': {AppLanguage.ko: '평균 점수 추이', AppLanguage.en: 'Average Score Trend'},
    'score_suffix': {AppLanguage.ko: '{0}점', AppLanguage.en: '{0} pts'},
    'my_elo_trend': {AppLanguage.ko: '내 Elo 변화', AppLanguage.en: 'My Elo Trend'},
    'others_reviews': {AppLanguage.ko: '다른 사람들의 리뷰', AppLanguage.en: 'Reviews from others'},
    'score_points': {AppLanguage.ko: '{0}점\n', AppLanguage.en: '{0} pts\n'},
    'people_count': {AppLanguage.ko: '{0}명', AppLanguage.en: '{0} people'},
    'date_format_tooltip': {AppLanguage.ko: '{0}월 {1}일\n', AppLanguage.en: '{0}/{1}\n'},
    // Search Screen
    'search_all': {AppLanguage.ko: '전체', AppLanguage.en: 'All'},
    'search_track': {AppLanguage.ko: '곡', AppLanguage.en: 'Track'},
    'search_album': {AppLanguage.ko: '앨범', AppLanguage.en: 'Album'},
    'search_artist': {AppLanguage.ko: '아티스트', AppLanguage.en: 'Artist'},
    'search_hint': {AppLanguage.ko: '트랙, 앨범, 아티스트 검색…', AppLanguage.en: 'Search tracks, albums, artists...'},
    'search_enter_hint': {AppLanguage.ko: '검색어를 입력하세요', AppLanguage.en: 'Enter a search term'},
    'search_error': {AppLanguage.ko: '검색에 실패했어요. 네트워크를 확인하세요.', AppLanguage.en: 'Search failed. Check your network.'},
    'search_no_results': {AppLanguage.ko: '결과가 없어요', AppLanguage.en: 'No results'},
    'search_more': {AppLanguage.ko: '더 보기', AppLanguage.en: 'See more'},
    'search_added_toast': {AppLanguage.ko: '추가됨 — 같은 종류를 더 추가하면 순위를 매겨요', AppLanguage.en: 'added — add more of the same kind to rank them'},
    'search_add': {AppLanguage.ko: '추가', AppLanguage.en: 'Add'},
    'search_back_tooltip': {AppLanguage.ko: '뒤로', AppLanguage.en: 'Back'},
    'search_category_more': {AppLanguage.ko: '{0} 카테고리에서 더보기', AppLanguage.en: 'See more in {0}'},
    'search_taste_engine_title': {AppLanguage.ko: '나의 음악 취향 분석 엔진', AppLanguage.en: 'My Music Taste Analysis Engine'},
    'search_taste_engine_desc': {AppLanguage.ko: '곡을 평가(듀얼)하여 추가하면, 나의 취향 장르 분석 결과가 실시간으로 반영되어 추천곡 목록이 지속적으로 업데이트됩니다.', AppLanguage.en: 'Rate songs in duels to automatically analyze your favorite genres and get real-time recommendations.'},
    'search_go_analyze': {AppLanguage.ko: '지금 취향 분석하러 가기', AppLanguage.en: 'Analyze my taste now'},
    'search_realtime_genres': {AppLanguage.ko: '실시간 장르 분석 결과', AppLanguage.en: 'Real-time Genre Analysis'},
    'search_updating_live': {AppLanguage.ko: '실시간 갱신 중', AppLanguage.en: 'Updating live'},
    'search_genre_desc': {AppLanguage.ko: '듀얼 평가 결과로 산출된 장르 선호도 순위입니다. 가장 선호하는 장르의 곡이 하단에 추천됩니다.', AppLanguage.en: 'Genre preference ranks calculated from duels. Recommended tracks matching your top genre appear below.'},
    // Profile Screen
    'profile_me': {AppLanguage.ko: 'Me', AppLanguage.en: 'Me'},
    'profile_edit': {AppLanguage.ko: '프로필 편집', AppLanguage.en: 'Edit Profile'},
    'profile_logout': {AppLanguage.ko: '로그아웃', AppLanguage.en: 'Sign Out'},
    'profile_local_user': {AppLanguage.ko: '로컬 사용자', AppLanguage.en: 'Local User'},
    'profile_ratings_count': {AppLanguage.ko: '개 평가', AppLanguage.en: 'ratings'},
    'profile_public': {AppLanguage.ko: '공개 프로필', AppLanguage.en: 'Public Profile'},
    'profile_private': {AppLanguage.ko: '비공개 프로필', AppLanguage.en: 'Private Profile'},
    'profile_private_desc': {AppLanguage.ko: '편집에서 공개로 바꾸면 공유할 수 있어요', AppLanguage.en: 'Change to public in edit to share'},
    'profile_copy_link': {AppLanguage.ko: '링크 복사', AppLanguage.en: 'Copy Link'},
    'profile_link_copied': {AppLanguage.ko: '링크 복사됨', AppLanguage.en: 'Link copied'},
    'profile_library': {AppLanguage.ko: '라이브러리', AppLanguage.en: 'Library'},
    'profile_stats': {AppLanguage.ko: '통계', AppLanguage.en: 'Stats'},
    'profile_share': {AppLanguage.ko: '취향 공유', AppLanguage.en: 'Share Taste'},
    'profile_language': {AppLanguage.ko: '언어 설정 (Language)', AppLanguage.en: 'Language Settings'},
    'profile_feedback_title': {AppLanguage.ko: '기능 건의함', AppLanguage.en: 'Suggest Features'},
    'profile_feedback_subtitle': {AppLanguage.ko: '의견이나 건의사항은 Instagram DM(@nerdyahh_)으로 보내주세요', AppLanguage.en: 'Send feedback or suggestions via Instagram DM (@nerdyahh_)'},
    'profile_top_genres': {AppLanguage.ko: '선호 장르', AppLanguage.en: 'Top Genres'},
    'profile_demo_title': {AppLanguage.ko: '개발용 데모 데이터 주입', AppLanguage.en: 'Inject Demo Data'},
    'profile_demo_desc': {AppLanguage.ko: '18개 명반 평가 + 153개 듀얼 내역을 생성합니다.', AppLanguage.en: 'Generates 18 album ratings and 153 duel logs.'},
    'profile_demo_success': {AppLanguage.ko: '데모 데이터 주입 완료!', AppLanguage.en: 'Demo data injected successfully!'},
    'profile_demo_failed': {AppLanguage.ko: '데이터 주입 실패: {0}', AppLanguage.en: 'Data injection failed: {0}'},
    'profile_demo_inject_btn': {AppLanguage.ko: '주입', AppLanguage.en: 'Inject'},
    'profile_friends_title': {AppLanguage.ko: '친구 목록 및 검색', AppLanguage.en: 'Friends List & Search'},
    'profile_friends_desc': {AppLanguage.ko: '친구들의 음악 취향과 나의 매칭률 확인', AppLanguage.en: 'Check friends\' music taste and match rate'},
    'profile_lastfm_title': {AppLanguage.ko: 'Last.fm 연동', AppLanguage.en: 'Last.fm Connection'},
    'profile_lastfm_connected': {AppLanguage.ko: '연동 완료 (@{0})', AppLanguage.en: 'Connected (@{0})'},
    'profile_lastfm_connect_desc': {AppLanguage.ko: 'Last.fm 계정 연동하여 재생 기록 가져오기', AppLanguage.en: 'Connect Last.fm to fetch play history'},
    'profile_delete_account_title': {AppLanguage.ko: '계정 및 데이터 삭제', AppLanguage.en: 'Delete Account & Data'},
    'profile_delete_account_desc': {AppLanguage.ko: '계정과 모든 데이터를 영구적으로 삭제합니다', AppLanguage.en: 'Permanently delete account and all data'},
    'profile_delete_account_confirm_title': {AppLanguage.ko: '계정 삭제', AppLanguage.en: 'Delete Account'},
    'profile_delete_account_confirm_desc': {AppLanguage.ko: '계정과 모든 평가·데이터가 영구히 삭제됩니다.\n되돌릴 수 없어요. 계속할까요?', AppLanguage.en: 'Your account and all ratings/data will be permanently deleted.\nThis cannot be undone. Continue?'},
    'profile_view_tooltip': {AppLanguage.ko: '프로필 보기', AppLanguage.en: 'View Profile'},
    // Stats Screen
    'stats_title': {AppLanguage.ko: 'Stats', AppLanguage.en: 'Stats'},
    'stats_rated_items': {AppLanguage.ko: '평가한 항목', AppLanguage.en: 'Rated Items'},
    'stats_comparisons': {AppLanguage.ko: '비교 횟수', AppLanguage.en: 'Comparisons'},
    'stats_distribution': {AppLanguage.ko: '점수 분포', AppLanguage.en: 'Score Distribution'},
    'stats_genres': {AppLanguage.ko: '장르 분포', AppLanguage.en: 'Top Genres'},
    'stats_genre_preference': {AppLanguage.ko: '장르별 선호도', AppLanguage.en: 'Genre Preferences'},
    'stats_moods': {AppLanguage.ko: '무드 분포', AppLanguage.en: 'Top Moods'},
    'stats_mood_preference': {AppLanguage.ko: '무드별 선호도', AppLanguage.en: 'Mood Preferences'},
    'stats_activity': {AppLanguage.ko: '최근 비교 추이', AppLanguage.en: 'Activity Over Time'},
    'stats_not_enough': {AppLanguage.ko: '아직 통계 데이터가 부족합니다.', AppLanguage.en: 'Not enough stats data yet.'},
    'stats_preference_not_enough': {AppLanguage.ko: '충분한 비교 데이터가 없습니다. 듀얼을 진행해 주세요.', AppLanguage.en: 'Not enough comparison data. Go complete some duels!'},
    'stats_empty_title': {AppLanguage.ko: '통계가 아직 없어요', AppLanguage.en: 'No stats yet'},
    'stats_empty_desc': {AppLanguage.ko: '음악을 평가하면 분포·장르·활동이 여기에 표시돼요.', AppLanguage.en: 'Rate music to see your distribution, genres, and activity here.'},
    'stats_items_unit': {AppLanguage.ko: '{0}개', AppLanguage.en: '{0}'},
    'stats_comparisons_unit': {AppLanguage.ko: '{0}개', AppLanguage.en: '{0}'},
    'stats_insights_title': {AppLanguage.ko: '💡 나의 음악 취향 분석 리포트', AppLanguage.en: '💡 Music Taste Insights'},
    'stats_avg_score_label': {AppLanguage.ko: '평균 점수', AppLanguage.en: 'Average Score'},
    'stats_avg_score_value': {AppLanguage.ko: '{0}점', AppLanguage.en: '{0} pts'},
    'stats_avg_score_desc': {AppLanguage.ko: '내 라이브러리 전체 평균', AppLanguage.en: 'Your library average'},
    'stats_most_dueled_label': {AppLanguage.ko: '최다 듀얼 곡', AppLanguage.en: 'Most Dueling Item'},
    'stats_most_dueled_desc': {AppLanguage.ko: '{0}회 격돌', AppLanguage.en: '{0} duels'},
    'stats_top_genre_label': {AppLanguage.ko: '원픽 장르', AppLanguage.en: 'Favorite Genre'},
    'stats_top_genre_desc': {AppLanguage.ko: '평균 {0}점', AppLanguage.en: 'Average {0} pts'},
    'stats_top_mood_label': {AppLanguage.ko: '선호 분위기', AppLanguage.en: 'Favorite Mood'},
    'stats_top_mood_desc': {AppLanguage.ko: '평균 {0}점', AppLanguage.en: 'Average {0} pts'},
    'stats_top_favorites_title': {AppLanguage.ko: '🏆 나의 원픽 음악 Top 5', AppLanguage.en: '🏆 My Top 5 Favorites'},
    'stats_score_suffix': {AppLanguage.ko: '{0}점', AppLanguage.en: '{0} pts'},
    'stats_duels_count': {AppLanguage.ko: '{0}회 대결', AppLanguage.en: '{0} duels'},
    'stats_score_suffix_short': {AppLanguage.ko: '점', AppLanguage.en: ' pts'},
    'stats_tracks_count': {AppLanguage.ko: '{0}곡', AppLanguage.en: '{0} tracks'},
    'stats_count_unit': {AppLanguage.ko: '{0}개', AppLanguage.en: '{0}'},
    'stats_items_count_suffix': {AppLanguage.ko: '{0}개', AppLanguage.en: '{0} items'},
    'stats_score_and_count': {AppLanguage.ko: '{0}점 ({1})', AppLanguage.en: '{0} ({1})'},
    'stats_comparisons_count': {AppLanguage.ko: '{0}회 비교', AppLanguage.en: '{0} comparisons'},
    // Share Screen
    'share_title': {AppLanguage.ko: '취향 공유', AppLanguage.en: 'Share Taste'},
    'share_create_card': {AppLanguage.ko: '나의 음악 취향 카드 만들기', AppLanguage.en: 'Create your music taste card'},
    'share_top_5': {AppLanguage.ko: '최고 점수 5개', AppLanguage.en: 'Top 5 Rated'},
    'share_snapshot': {AppLanguage.ko: '취향 스냅샷', AppLanguage.en: 'Taste Snapshot'},
    'share_recent': {AppLanguage.ko: '최근 비교한 음악', AppLanguage.en: 'Recently compared'},
    'share_top_tags': {AppLanguage.ko: '가장 많은 태그', AppLanguage.en: 'Top tags'},
    'share_top_artists': {AppLanguage.ko: '가장 많은 아티스트', AppLanguage.en: 'Top artists'},
    'share_export': {AppLanguage.ko: '이미지로 내보내기', AppLanguage.en: 'Export as Image'},
    'share_save_failed': {AppLanguage.ko: '사진첩에 저장할 수 없습니다. 권한을 확인하세요.', AppLanguage.en: 'Cannot save to gallery. Check permissions.'},
    'share_saved_toast': {AppLanguage.ko: '이미지가 사진첩에 저장되었습니다!', AppLanguage.en: 'Image saved to gallery!'},
    'share_copied_toast': {AppLanguage.ko: '이미지가 성공적으로 복사/공유되었습니다', AppLanguage.en: 'Image successfully shared/copied'},
    'share_text': {AppLanguage.ko: 'Athens에서 내 음악 취향 보기', AppLanguage.en: 'View my music taste on Athens'},
    'share_button': {AppLanguage.ko: '공유', AppLanguage.en: 'Share'},
    'share_card_taste': {AppLanguage.ko: '내 취향', AppLanguage.en: 'My Taste'},
    'share_card_top5': {AppLanguage.ko: '내 Top 5', AppLanguage.en: 'My Top 5'},
    'share_card_ratings_count': {AppLanguage.ko: '{0}개 평가', AppLanguage.en: '{0} ratings'},
    // Profile Edit Screen
    'edit_title': {AppLanguage.ko: '프로필 편집', AppLanguage.en: 'Edit Profile'},
    'edit_handle': {AppLanguage.ko: '사용자 핸들', AppLanguage.en: 'Username Handle'},
    'edit_display_name': {AppLanguage.ko: '표시 이름', AppLanguage.en: 'Display Name'},
    'edit_bio': {AppLanguage.ko: '소개', AppLanguage.en: 'Bio'},
    'edit_public_label': {AppLanguage.ko: '프로필 공개 여부', AppLanguage.en: 'Public Profile'},
    'edit_public_desc': {AppLanguage.ko: '프로필을 공개하면 다른 사람도 나의 평가된 음악 리스트를 조회할 수 있습니다.', AppLanguage.en: 'When public, others can view your rated music list.'},
    'edit_saving': {AppLanguage.ko: '저장 중...', AppLanguage.en: 'Saving...'},
    'edit_save': {AppLanguage.ko: '프로필 저장', AppLanguage.en: 'Save Profile'},
    'edit_choose_gallery': {AppLanguage.ko: '갤러리에서 선택', AppLanguage.en: 'Choose from Gallery'},
    'edit_delete_photo': {AppLanguage.ko: '사진 삭제', AppLanguage.en: 'Delete Photo'},
    'edit_uploaded_toast': {AppLanguage.ko: '프로필 사진 업로드됨', AppLanguage.en: 'Profile picture uploaded'},
    'edit_upload_failed': {AppLanguage.ko: '이미지 업로드 실패: ', AppLanguage.en: 'Image upload failed: '},
    'edit_saved_toast': {AppLanguage.ko: '프로필 저장됨', AppLanguage.en: 'Profile saved'},
    'edit_handle_taken': {AppLanguage.ko: '이미 사용 중인 핸들이에요', AppLanguage.en: 'This username is already taken'},
    'edit_save_failed': {AppLanguage.ko: '저장 실패: {0}', AppLanguage.en: 'Failed to save: {0}'},
    'edit_load_failed': {AppLanguage.ko: '불러오기 실패: {0}', AppLanguage.en: 'Failed to load: {0}'},
    'edit_login_required': {AppLanguage.ko: '로그인이 필요해요.', AppLanguage.en: 'Sign in is required.'},
    'edit_change_photo': {AppLanguage.ko: '프로필 사진 변경', AppLanguage.en: 'Change Profile Picture'},
    'edit_handle_label': {AppLanguage.ko: '핸들', AppLanguage.en: 'Handle'},
    'edit_public_url_hint': {AppLanguage.ko: '공개 프로필 주소: /u/<핸들>', AppLanguage.en: 'Public profile address: /u/<handle>'},
    'edit_display_name_hint': {AppLanguage.ko: '예: 준우', AppLanguage.en: 'e.g. Junwoo'},
    'edit_bio_hint': {AppLanguage.ko: '한 줄 소개', AppLanguage.en: 'A short bio about yourself'},
    'edit_lastfm_label': {AppLanguage.ko: 'Last.fm 사용자명 (청취 기록 연동)', AppLanguage.en: 'Last.fm Username (sync listening history)'},
    'edit_lastfm_hint': {AppLanguage.ko: 'Last.fm 아이디를 입력하세요', AppLanguage.en: 'Enter your Last.fm username'},
    'edit_lastfm_helper': {AppLanguage.ko: 'Spotify, YouTube Music 등을 연동한 Last.fm 아이디', AppLanguage.en: 'Last.fm username connected to Spotify, YouTube Music, etc.'},
    'edit_public_profile_title': {AppLanguage.ko: '공개 프로필', AppLanguage.en: 'Public Profile'},
    'edit_public_desc_on': {AppLanguage.ko: '누구나 웹에서 내 순위를 볼 수 있어요', AppLanguage.en: 'Anyone can view your rankings on the web'},
    'edit_public_desc_off': {AppLanguage.ko: '나만 볼 수 있어요', AppLanguage.en: 'Only you can view your rankings'},
    'edit_handle_too_short': {AppLanguage.ko: '핸들은 3자 이상이어야 해요', AppLanguage.en: 'Handle must be at least 3 characters'},
    'edit_handle_too_long': {AppLanguage.ko: '핸들은 20자 이하여야 해요', AppLanguage.en: 'Handle must be 20 characters or less'},
    'edit_handle_invalid_chars': {AppLanguage.ko: '소문자, 숫자, 밑줄(_)만 쓸 수 있어요', AppLanguage.en: 'Only lowercase letters, numbers, and underscores are allowed'},
    'edit_delete_account_failed': {AppLanguage.ko: '계정 삭제에 실패했어요. 잠시 후 다시 시도해 주세요.', AppLanguage.en: 'Failed to delete account. Please try again later.'},
    // Duel Screen
    'duel_question': {AppLanguage.ko: '어떤 게 더 좋아요?', AppLanguage.en: 'Which one do you prefer?'},
    'duel_skip': {AppLanguage.ko: '무승부 / 둘 다 모름', AppLanguage.en: 'Skip / Don\'t know either'},
    'duel_not_sure': {AppLanguage.ko: '잘 모르겠어요', AppLanguage.en: 'Not sure'},
    'duel_skip_btn': {AppLanguage.ko: '건너뛰기', AppLanguage.en: 'Skip'},
    'duel_undo': {AppLanguage.ko: '되돌리기', AppLanguage.en: 'Undo'},
    'duel_assigning_rank': {AppLanguage.ko: '순위 정하는 중 · {0}/{1}', AppLanguage.en: 'Assigning rank · {0}/{1}'},
    'duel_placement_complete': {AppLanguage.ko: '순위가 정해졌어요', AppLanguage.en: 'Rank determined!'},
    'duel_view_library': {AppLanguage.ko: '라이브러리 보기', AppLanguage.en: 'View Library'},
    'duel_add_more': {AppLanguage.ko: '더 추가하기', AppLanguage.en: 'Add More'},
    'duel_empty_library': {AppLanguage.ko: '듀얼을 시작하려면 음악을 추가하세요', AppLanguage.en: 'Add music to start a duel'},
    'duel_empty_sub': {AppLanguage.ko: '같은 종류끼리 겨뤄요 — 한 종류에 2개 이상 추가하면 시작돼요', AppLanguage.en: 'Compare items of the same type — add 2 or more of one type to start'},
    'duel_streak': {AppLanguage.ko: '🔥 {0}개 연속 평가 중!', AppLanguage.en: '🔥 {0} in a row!'},
    'duel_win_streak': {AppLanguage.ko: '🔥 {0} {1}연승!', AppLanguage.en: '🔥 {0} is on a {1}-win streak!'},
    'duel_loss_streak': {AppLanguage.ko: '💀 {0} {1}연패...', AppLanguage.en: '💀 {0} is on a {1}-loss streak...'},
    'duel_placement_question': {AppLanguage.ko: '새로 추가한 {0}, 어느 쪽이 더 좋아요?', AppLanguage.en: 'Which {0} do you prefer for the new one?'},
    'duel_question_kind': {AppLanguage.ko: '어떤 {0}이 더 좋아요?', AppLanguage.en: 'Which {0} do you prefer?'},
    'duel_placement_rank': {AppLanguage.ko: '{0} {1}개 중 {2}위', AppLanguage.en: 'Rank {2} of {1} {0}'},
    // Initial Score Dialog
    'dialog_set_initial_score': {AppLanguage.ko: '초기 배치 점수 설정', AppLanguage.en: 'Set Initial Rating'},
    'dialog_opinion_prompt': {AppLanguage.ko: '“제가 지금 생각하기에 이 {0}은 이정도예요.”', AppLanguage.en: '“In my opinion, this {0} is about this rating.”'},
    'dialog_guide_notice': {AppLanguage.ko: '이 점수를 바탕으로 대략적인 첫 위치를 잡습니다. 확인 후, 다른 {0}들과 배틀(1대1 비교)을 치르며 더 정확한 최종 순위를 정하게 됩니다.', AppLanguage.en: 'This rating determines its starting position. After confirming, it will duel against other {0}s to find its final rank.'},
    'dialog_cancel': {AppLanguage.ko: '취소', AppLanguage.en: 'Cancel'},
    'dialog_confirm': {AppLanguage.ko: '확인', AppLanguage.en: 'Confirm'},
    'dialog_kind_item': {AppLanguage.ko: '항목', AppLanguage.en: 'item'},
    // Offline Banner
    'offline_sync_pending': {AppLanguage.ko: '오프라인 — 변경 {0}개는 온라인 시 동기화돼요', AppLanguage.en: 'Offline — {0} pending changes will sync when online'},
    'offline_local_only': {AppLanguage.ko: '오프라인 — 저장된 라이브러리는 그대로 이용할 수 있어요', AppLanguage.en: 'Offline — saved library is available offline'},
    // Update Banner
    'update_invalid_package': {AppLanguage.ko: '다운로드한 파일이 올바른 업데이트 패키지가 아니에요. 잠시 후 다시 시도해 주세요.', AppLanguage.en: 'Downloaded file is not a valid update package. Please try again later.'},
    'update_failed_toast': {AppLanguage.ko: '업데이트 설치 실패: {0}', AppLanguage.en: 'Failed to install update: {0}'},
    'update_available': {AppLanguage.ko: '새 버전 {0} 출시!', AppLanguage.en: 'New version {0} available!'},
    'update_installing': {AppLanguage.ko: '업데이트 설치 중...', AppLanguage.en: 'Installing update...'},
    'update_download_desc': {AppLanguage.ko: '현재 {0} → 업데이트 다운로드', AppLanguage.en: 'Current version {0} → Download update'},
    'update_btn': {AppLanguage.ko: '업데이트', AppLanguage.en: 'Update'},
  };

  static String get(String key, AppLanguage lang, [List<String>? args]) {
    final trans = _keys[key];
    if (trans == null) return key;
    String value = trans[lang] ?? trans[AppLanguage.ko] ?? key;
    if (args != null) {
      for (int i = 0; i < args.length; i++) {
        value = value.replaceAll('{$i}', args[i]);
      }
    }
    return value;
  }
}

extension BuildContextI18n on BuildContext {
  String t(String key, {List<String>? args, WidgetRef? ref}) {
    final AppLanguage lang = ref?.watch(localeProvider) ?? AppLanguage.en;
    return I18n.get(key, lang, args);
  }
}
