import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Elegant Gradient Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    p.bg,
                    isDark 
                        ? p.accentSoft.withValues(alpha: 0.15) 
                        : p.accentSoft.withValues(alpha: 0.3),
                    p.bg,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  
                  // App Brand Logo & Title
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: p.accentSoft.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: p.accent.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Icon(
                        Icons.insights_rounded,
                        size: 64,
                        color: p.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Text(
                      'Athens',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: p.text,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '마음에 드는 곡으로 만드는 실시간 랭킹',
                      style: TextStyle(
                        fontSize: 16,
                        color: p.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const Spacer(flex: 2),
                  
                  // Horizontal Feature Showcase Cards
                  SizedBox(
                    height: 180,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildFeatureCard(
                          context: context,
                          icon: Icons.swap_calls_rounded,
                          title: '곡 대 곡 듀얼',
                          description: '두 노래 중 무엇이 더 내 취향인지 가볍게 월드컵식 토너먼트로 골라봅니다.',
                        ),
                        _buildFeatureCard(
                          context: context,
                          icon: Icons.analytics_rounded,
                          title: '나만의 점수와 랭킹',
                          description: '듀얼 결과에 따라 점수가 정밀하게 매겨지고, 내 음악 순위가 실시간으로 바뀝니다.',
                        ),
                        _buildFeatureCard(
                          context: context,
                          icon: Icons.pie_chart_rounded,
                          title: '디테일한 취향 분석',
                          description: '보관한 곡들의 태그를 쪼개어 내가 정말 선호하는 장르와 세부 감성을 찾아냅니다.',
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(flex: 3),
                  
                  // Get Started Action Buttons
                  ElevatedButton(
                    onPressed: () => context.go('/auth'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.accent,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.card),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      '내 음악 서재 만들기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  Center(
                    child: Text(
                      '지금 가입하고 내 음악 데이터를 안전하게 보관하세요',
                      style: TextStyle(
                        fontSize: 12,
                        color: p.faint,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final p = context.palette;
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: p.accent, size: 28),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: p.text,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: p.muted,
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
