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
  LocaleNotifier() : super(AppLanguage.ko) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final code = await PlatformStorage.read(key: _localeKey);
      if (code == AppLanguage.en.code) {
        state = AppLanguage.en;
      } else {
        state = AppLanguage.ko;
      }
    } catch (_) {
      state = AppLanguage.ko;
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    try {
      await PlatformStorage.write(key: _localeKey, value: language.code);
    } catch (_) {}
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
    // Home Screen
    'home_title': {AppLanguage.ko: '오늘은 무엇을 평가할까요?', AppLanguage.en: 'What are we rating today?'},
    'home_recent': {AppLanguage.ko: '최근 들은 음악', AppLanguage.en: 'Recently Played'},
    'home_recent_error': {AppLanguage.ko: '최근 재생 목록을 불러오지 못했어요', AppLanguage.en: 'Failed to load recently played tracks'},
    'home_start_duel': {AppLanguage.ko: '듀얼 시작하기', AppLanguage.en: 'Start Duel'},
    'home_start_duel_sub': {AppLanguage.ko: '둘 중 더 좋은 걸 고르면 순위가 매겨져요', AppLanguage.en: 'Choose the better one to rank your music'},
    'home_rate': {AppLanguage.ko: '평가', AppLanguage.en: 'Rate'},
    'home_spotify_connect_desc': {AppLanguage.ko: 'Spotify를 연결하면 최근 들은 곡이 여기에 나와요', AppLanguage.en: 'Connect Spotify to see your recently played tracks here'},
    'home_spotify_connect': {AppLanguage.ko: 'Spotify 연결', AppLanguage.en: 'Connect Spotify'},
    // Library Screen
    'lib_no_rated_title': {AppLanguage.ko: '아직 평가한 음악이 없어요', AppLanguage.en: 'No rated music yet'},
    'lib_no_rated_desc': {AppLanguage.ko: '검색해서 음악을 추가하고 듀얼을 시작하세요.', AppLanguage.en: 'Search music to add them, then start dueling.'},
    'lib_search_music': {AppLanguage.ko: '음악 검색', AppLanguage.en: 'Search Music'},
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
    'profile_spotify_sub': {AppLanguage.ko: '최근 들은 곡 가져오기', AppLanguage.en: 'Import recently played tracks'},
    'profile_language': {AppLanguage.ko: '언어 설정 (Language)', AppLanguage.en: 'Language Settings'},
    'profile_feedback_title': {AppLanguage.ko: '기능 건의함', AppLanguage.en: 'Suggest Features'},
    'profile_feedback_subtitle': {AppLanguage.ko: '의견이나 건의사항은 Instagram DM(@nerdyahh_)으로 보내주세요', AppLanguage.en: 'Send feedback or suggestions via Instagram DM (@nerdyahh_)'},
    'profile_top_genres': {AppLanguage.ko: '선호 장르', AppLanguage.en: 'Top Genres'},
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
    // Duel Screen
    'duel_question': {AppLanguage.ko: '어떤 게 더 좋아요?', AppLanguage.en: 'Which one do you prefer?'},
    'duel_skip': {AppLanguage.ko: '무승부 / 둘 다 모름', AppLanguage.en: 'Skip / Don\'t know either'},
    'duel_not_sure': {AppLanguage.ko: '잘 모르겠어요', AppLanguage.en: 'Not sure'},
    'duel_skip_btn': {AppLanguage.ko: '건너뛰기', AppLanguage.en: 'Skip'},
    'duel_assigning_rank': {AppLanguage.ko: '순위 정하는 중 · {0}/{1}', AppLanguage.en: 'Assigning rank · {0}/{1}'},
    'duel_placement_complete': {AppLanguage.ko: '순위가 정해졌어요', AppLanguage.en: 'Rank determined!'},
    'duel_view_library': {AppLanguage.ko: '라이브러리 보기', AppLanguage.en: 'View Library'},
    'duel_add_more': {AppLanguage.ko: '더 추가하기', AppLanguage.en: 'Add More'},
    'duel_empty_library': {AppLanguage.ko: '듀얼을 시작하려면 음악을 추가하세요', AppLanguage.en: 'Add music to start a duel'},
    'duel_empty_sub': {AppLanguage.ko: '같은 종류끼리 겨뤄요 — 한 종류에 2개 이상 추가하면 시작돼요', AppLanguage.en: 'Compare items of the same type — add 2 or more of one type to start'},
    'duel_streak': {AppLanguage.ko: '🔥 {0}개 연속 평가 중!', AppLanguage.en: '🔥 {0} in a row!'},
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
    final AppLanguage lang = ref?.watch(localeProvider) ?? AppLanguage.ko;
    return I18n.get(key, lang, args);
  }
}
