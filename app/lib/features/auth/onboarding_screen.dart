import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/platform_storage.dart';
import '../../i18n.dart';
import '../../theme/tokens.dart';

const _kOnboardingDoneKey = 'onboarding_done';

Future<void> completeOnboarding() =>
    PlatformStorage.write(key: _kOnboardingDoneKey, value: 'true');

const _covers = [
  'assets/landing/covers/idioteque.jpg',
  'assets/landing/covers/spacesong.jpg',
  'assets/landing/covers/just.jpg',
  'assets/landing/covers/sugar.jpg',
  'assets/landing/covers/lessiknow.jpg',
  'assets/landing/covers/reptilia.jpg',
];

const _rankData = [
  ('Idioteque', 'Radiohead', 8.7, 'assets/landing/covers/idioteque.jpg'),
  ('Space Song', 'Beach House', 7.9, 'assets/landing/covers/spacesong.jpg'),
  ('Just', 'Radiohead', 7.4, 'assets/landing/covers/just.jpg'),
  ('Reptilia', 'The Strokes', 6.2, 'assets/landing/covers/reptilia.jpg'),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _controller.animateToPage(
        _page + 1,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      _done();
    }
  }

  Future<void> _done() async {
    await completeOnboarding();
    if (!mounted) return;
    context.go('/landing');
  }

  @override
  Widget build(BuildContext context) {
    // Always dark — a one-time screen that sets the mood.
    const p = AppPalette.dark;

    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              _DuelPage(p: p, onNext: _next),
              _RankPage(p: p, onNext: _next),
              _SharePage(p: p, onNext: _done),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Row(
                    children: List.generate(3, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 6),
                        width: active ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active ? p.accent : p.line,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  if (_page < 2)
                    GestureDetector(
                      onTap: _done,
                      child: Text(
                        context.t('onb_skip', ref: ref),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: p.faint,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 1: The duel ─────────────────────────────────────────────────────────

class _DuelPage extends ConsumerStatefulWidget {
  const _DuelPage({required this.p, required this.onNext});
  final AppPalette p;
  final VoidCallback onNext;

  @override
  ConsumerState<_DuelPage> createState() => _DuelPageState();
}

class _DuelPageState extends ConsumerState<_DuelPage> {
  int _deckPos = 0;
  int? _picked;
  Timer? _timer;

  String get _leftCover => _covers[_deckPos % _covers.length];
  String get _rightCover => _covers[(_deckPos + 1) % _covers.length];

  void _pick(int side) {
    if (_picked != null) return;
    setState(() => _picked = side);
    _timer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _deckPos += 2;
        _picked = null;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final lang = ref.watch(localeProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'PAIRWISE RATING',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.4,
                color: p.accentText,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              I18n.get('onb_duel_headline', lang),
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontFamilyFallback: AppFonts.fallback,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: p.text,
                letterSpacing: -1.8,
                height: 1.06,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              I18n.get('onb_duel_desc', lang),
              style: TextStyle(
                fontSize: 15,
                height: 1.55,
                color: p.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(child: _card(0)),
                const SizedBox(width: 12),
                Expanded(child: _card(1)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  I18n.get('onb_duel_prompt', lang),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                Text(
                  I18n.get('onb_duel_hint', lang),
                  style: TextStyle(fontSize: 12, color: p.faint),
                ),
              ],
            ),
            const Spacer(),
            _cta(p, I18n.get('onb_next', lang), widget.onNext),
          ],
        ),
      ),
    );
  }

  Widget _card(int side) {
    final p = widget.p;
    final cover = side == 0 ? _leftCover : _rightCover;
    final isPicked = _picked == side;
    final isDimmed = _picked != null && _picked != side;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: isDimmed ? 0.35 : 1,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        scale: isPicked ? 1.03 : (isDimmed ? 0.97 : 1.0),
        child: GestureDetector(
          onTap: () => _pick(side),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(
                  color: isPicked ? p.accent : p.line,
                  width: isPicked ? 2 : 1,
                ),
                image: DecorationImage(
                  image: AssetImage(cover),
                  fit: BoxFit.cover,
                ),
              ),
              child: isPicked
                  ? Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: p.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Page 2: The rank ─────────────────────────────────────────────────────────

class _RankPage extends ConsumerStatefulWidget {
  const _RankPage({required this.p, required this.onNext});
  final AppPalette p;
  final VoidCallback onNext;

  @override
  ConsumerState<_RankPage> createState() => _RankPageState();
}

class _RankPageState extends ConsumerState<_RankPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final lang = ref.watch(localeProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'PERSONAL RANKING',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.4,
                color: p.accentText,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              I18n.get('onb_rank_headline', lang),
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontFamilyFallback: AppFonts.fallback,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: p.text,
                letterSpacing: -1.8,
                height: 1.06,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              I18n.get('onb_rank_desc', lang),
              style: TextStyle(
                fontSize: 15,
                height: 1.55,
                color: p.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            ...List.generate(_rankData.length, (i) {
              final delay = i * 0.15;
              final anim = CurvedAnimation(
                parent: _anim,
                curve: Interval(
                  delay,
                  (delay + 0.5).clamp(0.0, 1.0),
                  curve: Curves.easeOutCubic,
                ),
              );
              return AnimatedBuilder(
                animation: anim,
                builder: (context, _) {
                  return Opacity(
                    opacity: anim.value,
                    child: Transform.translate(
                      offset: Offset(0, 16 * (1 - anim.value)),
                      child: _rankRow(p, i, _rankData[i]),
                    ),
                  );
                },
              );
            }),
            const Spacer(),
            _cta(p, I18n.get('onb_next', lang), widget.onNext),
          ],
        ),
      ),
    );
  }

  Widget _rankRow(AppPalette p, int rank,
      (String, String, double, String) data) {
    final (title, artist, score, cover) = data;
    final barWidth = score / 10;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '${rank + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: rank == 0 ? p.accentText : p.faint,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(cover, width: 44, height: 44, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 3,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (barWidth * 100).round(),
                          child: ColoredBox(
                            color: rank == 0 ? p.accent : p.muted,
                          ),
                        ),
                        Expanded(
                          flex: ((1 - barWidth) * 100).round(),
                          child: ColoredBox(color: p.line),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: rank == 0 ? p.accentText : p.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 3: The share ─────────────────────────────────────────────────────────

class _SharePage extends ConsumerStatefulWidget {
  const _SharePage({required this.p, required this.onNext});
  final AppPalette p;
  final VoidCallback onNext;

  @override
  ConsumerState<_SharePage> createState() => _SharePageState();
}

class _SharePageState extends ConsumerState<_SharePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final lang = ref.watch(localeProvider);
    final fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'SHARE & COMPARE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.4,
                color: p.accentText,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              I18n.get('onb_share_headline', lang),
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontFamilyFallback: AppFonts.fallback,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: p.text,
                letterSpacing: -1.8,
                height: 1.06,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              I18n.get('onb_share_desc', lang),
              style: TextStyle(
                fontSize: 15,
                height: 1.55,
                color: p.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: fade,
              builder: (context, child) => Opacity(
                opacity: fade.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - fade.value)),
                  child: child,
                ),
              ),
              child: _topsterPreview(p, lang),
            ),
            const Spacer(),
            _cta(p, I18n.get('onb_start', lang), widget.onNext),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _topsterPreview(AppPalette p, AppLanguage lang) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: p.line),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MY TOP 6',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: p.faint,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: _covers.take(6).map((c) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(c, fit: BoxFit.cover),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: p.accentSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.accent, width: 1.5),
                ),
                child: Icon(Icons.person_rounded, size: 16, color: p.accentText),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      I18n.get('onb_share_match_label', lang),
                      style: TextStyle(
                          fontSize: 12, color: p.muted, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '74%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: p.accentText,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared CTA button ─────────────────────────────────────────────────────────

Widget _cta(AppPalette p, String label, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 17),
      decoration: BoxDecoration(
        color: p.accent,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppFonts.display,
          fontFamilyFallback: AppFonts.fallback,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: Colors.black,
        ),
      ),
    ),
  );
}
