import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../../i18n.dart';

/// First-launch landing. Mirrors the web landing: a true-black hero built around
/// an interactive duel — tap a card to pick, per-song win/loss streaks surface
/// as a transient nudge (same rule as the in-app Rate tab).
class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _Song {
  const _Song(this.title, this.artist, this.cover);
  final String title;
  final String artist;
  final String cover;
}

const _deck = <_Song>[
  _Song('Idioteque', 'Radiohead', 'assets/landing/covers/idioteque.jpg'),
  _Song('Space Song', 'Beach House', 'assets/landing/covers/spacesong.jpg'),
  _Song('Just', 'Radiohead', 'assets/landing/covers/just.jpg'),
  _Song('Sugar for the Pill', 'Slowdive', 'assets/landing/covers/sugar.jpg'),
  _Song('The Less I Know the Better', 'Tame Impala', 'assets/landing/covers/lessiknow.jpg'),
  _Song('The Spirit of Radio', 'Rush', 'assets/landing/covers/spiritradio.jpg'),
  _Song('Reptilia', 'The Strokes', 'assets/landing/covers/reptilia.jpg'),
  _Song('Innuendo', 'Queen', 'assets/landing/covers/innuendo.jpg'),
];

class _LandingScreenState extends ConsumerState<LandingScreen> {
  int _deckPos = 0;
  int? _picked; // 0 | 1 | null
  final Map<String, int> _streaks = {}; // +win streak / -loss streak per title
  String? _nudge;
  bool _nudgeLoss = false;
  Timer? _advanceTimer;
  Timer? _hideTimer;

  _Song get _left => _deck[_deckPos % _deck.length];
  _Song get _right => _deck[(_deckPos + 1) % _deck.length];

  @override
  void initState() {
    super.initState();
    // Warm the first two covers so the duel never flashes empty.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(AssetImage(_left.cover), context);
      precacheImage(AssetImage(_right.cover), context);
    });
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _pick(int side) {
    if (_picked != null) return;
    setState(() => _picked = side);

    final winner = side == 0 ? _left : _right;
    final loser = side == 0 ? _right : _left;
    final ws = (_streaks[winner.title] ?? 0) > 0 ? _streaks[winner.title]! + 1 : 1;
    final ls = (_streaks[loser.title] ?? 0) < 0 ? _streaks[loser.title]! - 1 : -1;
    _streaks[winner.title] = ws;
    _streaks[loser.title] = ls;

    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _deckPos += 2;
        _picked = null;
        if (ws >= 2) {
          _nudge = context.t('duel_win_streak', args: [winner.title, '$ws'], ref: ref);
          _nudgeLoss = false;
        } else if (ls <= -2) {
          _nudge = context.t('duel_loss_streak', args: [loser.title, '${-ls}'], ref: ref);
          _nudgeLoss = true;
        }
      });
      if (_nudge != null) {
        _hideTimer?.cancel();
        _hideTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _nudge = null);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Headline scales down on narrow phones; content is capped and
            // centered on wide windows (tablet / desktop macOS). Scroll +
            // minHeight + IntrinsicHeight lets the Spacers breathe when there's
            // room and gracefully scrolls when there isn't (short heights, large
            // text-scale) instead of overflowing.
            final headlineSize = constraints.maxWidth < 340
                ? 32.0
                : constraints.maxWidth < 400
                    ? 36.0
                    : 40.0;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxl, vertical: AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                'Athens',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontFamilyFallback: AppFonts.fallback,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: p.text,
                  letterSpacing: -0.5,
                ),
              ),

              const Spacer(flex: 2),

              // eyebrow + headline + sub
              Text(
                'PAIRWISE MUSIC RATING',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.4,
                  color: p.accentText,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                "Don't rate music.\nChoose it.",
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontFamilyFallback: AppFonts.fallback,
                  fontSize: headlineSize,
                  fontWeight: FontWeight.w800,
                  color: p.text,
                  letterSpacing: -1.6,
                  height: 1.04,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.t('landing_desc', ref: ref),
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.5,
                  color: p.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(flex: 2),

              // streak nudge — transient, per-song
              SizedBox(
                height: 34,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0, -0.4), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _nudge == null
                        ? const SizedBox.shrink()
                        : Container(
                            key: ValueKey(_nudge),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              color: _nudgeLoss ? p.surface2 : p.accentSoft,
                              borderRadius: BorderRadius.circular(999),
                              border: _nudgeLoss ? Border.all(color: p.line) : null,
                            ),
                            child: Text(
                              _nudge!,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: _nudgeLoss ? p.muted : p.accentText,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // the duel
              Row(
                children: [
                  Expanded(child: _duelCard(0)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _duelCard(1)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.t('landing_question', ref: ref),
                      style: TextStyle(fontSize: 14, color: p.text, fontWeight: FontWeight.w700)),
                  Text(context.t('landing_tap_hint', ref: ref),
                      style: TextStyle(fontSize: 12.5, color: p.faint)),
                ],
              ),

              // Guaranteed breathing room before the CTA even when the flex
              // Spacers collapse to 0 (content ≈ viewport height under the
              // responsive scroll layout) — keeps 시작하기 from hugging the duel.
              const Spacer(flex: 3),
              const SizedBox(height: AppSpacing.xxxl),

              // CTA
              ElevatedButton(
                onPressed: () => context.go('/auth'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: p.accent,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
                  elevation: 0,
                ),
                child: Text(
                  context.t('landing_start', ref: ref),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: () => context.go('/auth'),
                child: Text(context.t('landing_have_account', ref: ref),
                    style: TextStyle(fontSize: 14, color: p.muted, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: AppSpacing.md),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _duelCard(int side) {
    final p = context.palette;
    final song = side == 0 ? _left : _right;
    final isPicked = _picked == side;
    final isDimmed = _picked != null && _picked != side;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 450),
      opacity: isDimmed ? 0.38 : 1,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 450),
        scale: isDimmed ? 0.97 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, isPicked ? -6 : 0, 0),
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
                    width: isPicked ? 1.5 : 1,
                  ),
                  image: DecorationImage(image: AssetImage(song.cover), fit: BoxFit.cover),
                  boxShadow: isPicked
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 16))]
                      : null,
                ),
                child: Stack(
                  children: [
                    // scrim
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black.withValues(alpha: 0.05), Colors.black.withValues(alpha: 0.82)],
                            stops: const [0.3, 1.0],
                          ),
                        ),
                      ),
                    ),
                    if (isPicked)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, size: 16, color: Colors.black),
                        ),
                      ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontFamilyFallback: AppFonts.fallback,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.72)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
