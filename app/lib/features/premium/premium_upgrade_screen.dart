import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/billing/billing_providers.dart';
import '../../api/billing/billing_service.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_service.dart';
import '../../dev_seed.dart';

const String _sponsorUrl = String.fromEnvironment(
  'SPONSOR_URL',
  defaultValue: 'https://ko-fi.com/C3V820LKKR',
);

class PremiumUpgradeScreen extends ConsumerStatefulWidget {
  const PremiumUpgradeScreen({super.key});

  @override
  ConsumerState<PremiumUpgradeScreen> createState() => _PremiumUpgradeScreenState();
}

class _PremiumUpgradeScreenState extends ConsumerState<PremiumUpgradeScreen> {
  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  bool _isPurchasing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeemCode(String code) async {
    if (code.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final success = await ref.read(profileServiceProvider).redeemPromoCode(code);
      if (success) {
        ref.invalidate(myProfileProvider);
        if (mounted) {
          // Success Feedback
          Navigator.of(context).pop(); // Close code dialog
          Navigator.of(context).pop(); // Close premium screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: context.palette.accent,
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.black),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Premium 기능이 성공적으로 활성화되었습니다!',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = '올바르지 않거나 이미 사용된 코드입니다.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '코드 확인 중 오류가 발생했습니다: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showCodeDialog() {
    _codeController.clear();
    _errorMessage = null;
    _isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final p = context.palette;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(top: BorderSide(color: p.line)),
              ),
              padding: EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                top: AppSpacing.xl,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '프로모션 코드 등록',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: p.muted),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '후원 리워드 등으로 받은 프로모션 코드를 입력하세요. 대소문자를 구분하지 않습니다.',
                    style: TextStyle(color: p.muted, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _codeController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: '예: ATHENS_VIP_PASS',
                      hintStyle: TextStyle(color: p.faint),
                      filled: true,
                      fillColor: p.surface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: p.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: p.accent, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    onSubmitted: _isSubmitting ? null : (val) async {
                      setModalState(() {
                        _isSubmitting = true;
                        _errorMessage = null;
                      });
                      await _redeemCode(val);
                      setModalState(() {
                        _isSubmitting = false;
                      });
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            setModalState(() {
                              _isSubmitting = true;
                              _errorMessage = null;
                            });
                            await _redeemCode(_codeController.text);
                            setModalState(() {
                              _isSubmitting = false;
                            });
                          },
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Text(
                            '코드 등록하기',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _launchSponsor() async {
    final url = Uri.parse(_sponsorUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _purchaseWithGooglePlay() async {
    if (_isPurchasing) return;
    setState(() => _isPurchasing = true);

    try {
      final billing = ref.read(billingServiceProvider);
      final result = await billing.purchasePremium();

      if (!mounted) return;

      switch (result) {
        case PurchaseResult.success:
          // Edge Fn already set is_premium=true; confirm locally and refresh.
          await ref.read(profileServiceProvider).grantPremiumViaIap();
          ref.invalidate(myProfileProvider);
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: context.palette.accent,
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.black),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'Athens Premium이 활성화되었습니다! 🎉',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        case PurchaseResult.cancelled:
          // Nothing — user backed out.
          break;
        case PurchaseResult.error:
        case PurchaseResult.notSupported:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('결제 중 문제가 발생했습니다. 다시 시도해 주세요.'),
              ),
            );
          }
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restorePurchases() async {
    if (_isPurchasing) return;
    setState(() => _isPurchasing = true);
    try {
      final billing = ref.read(billingServiceProvider);
      final restored = await billing.restorePurchases();
      if (!mounted) return;
      if (restored) {
        await ref.read(profileServiceProvider).grantPremiumViaIap();
        ref.invalidate(myProfileProvider);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: context.palette.accent,
              content: const Text(
                '이전 구매가 복원되었습니다!',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('복원할 구매 내역이 없습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: p.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 👑 Logo & Header
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [p.accentSoft.withValues(alpha: 0.15), p.accent.withValues(alpha: 0.3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: p.accent.withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Icon(Icons.workspace_premium_rounded, size: 56, color: p.accentText),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [p.accentText, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'ATHENS PREMIUM',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: Colors.white,
                            ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '당신의 음악 취향을 더욱 깊이 있게 들여다보세요.',
                      style: TextStyle(color: p.muted, fontSize: 13.5, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ✨ Premium Features List
              Text(
                '프리미엄 혜택',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildFeatureRow(
                context,
                Icons.analytics_rounded,
                '상세 취향 분석',
                '장르/무드 선호도 변화 차트와 상세 통계 보고서를 잠금 해제합니다.',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildFeatureRow(
                context,
                Icons.compare_arrows_rounded,
                '곡별 대조 리포트',
                '친구와의 공통 최애, 취향 충돌 곡 등의 비교 리포트를 카테고리별로 전부 확인합니다.',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildFeatureRow(
                context,
                Icons.workspace_premium_rounded,
                '후원자 전용 배지',
                '내 프로필과 공유 카드에 표시되는 영구 골드 후원 배지를 얻습니다.',
              ),
              
              const SizedBox(height: AppSpacing.xxl),

              // 💳 Plan Section
              Text(
                '멤버십 활성화',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),

              // Card 0: Google Play (Store builds only)
              if (kStoreBuild) ...[
                _buildGooglePlayCard(context),
                const SizedBox(height: AppSpacing.md),
              ],

              // Card 1: Promo Code
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: p.surface2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.accent.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.confirmation_num_rounded, color: p.accentText),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '프로모션 코드로 등록',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '텀블벅 후원 또는 직접 후원자분들께 발급해 드린 코드로 즉시 활성화할 수 있습니다.',
                      style: TextStyle(color: p.muted, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _showCodeDialog,
                      child: const Text(
                        '프로모션 코드 입력',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Card 2: Support link
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: p.surface2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.favorite_rounded, color: Colors.pinkAccent.withValues(alpha: 0.8)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Athens 후원하기',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Athens 프로젝트의 독립적 개발과 운영을 후원하고 프로모션 코드를 받으실 수 있습니다.',
                      style: TextStyle(color: p.muted, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: p.text,
                        side: BorderSide(color: p.line),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _launchSponsor,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '후원 및 상세 정보 보기',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.open_in_new_rounded, size: 14, color: p.muted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Developer bypass card
              if (kDebugMode || kDevSeed) ...[
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bug_report_rounded, color: Colors.redAccent),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Text(
                          '[개발자 우회] 프리미엄 즉시 활성화',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(60, 32),
                        ),
                        onPressed: () async {
                          try {
                            await ref.read(profileServiceProvider).togglePremium(true);
                            ref.invalidate(myProfileProvider);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('개발용 프리미엄 활성화 완료')),
                              );
                            }
                          } catch (_) {}
                        },
                        child: const Text('활성화', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, IconData icon, String title, String description) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: p.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.line),
          ),
          child: Icon(icon, size: 20, color: p.accentText),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Google Play 결제 카드 — kStoreBuild == true 일 때만 렌더됨.
  Widget _buildGooglePlayCard(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            p.accent.withValues(alpha: 0.12),
            p.accentSoft.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.accent.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.shopping_bag_rounded, color: p.accentText, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Athens Premium',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '일회성 구매 · 영구 소유',
                      style: TextStyle(color: p.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Price badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: p.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '\$4.99',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '한 번만 결제하면 모든 프리미엄 기능을 영구적으로 사용할 수 있습니다. 기기 변경 시에도 구매 복원이 가능합니다.',
            style: TextStyle(color: p.muted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Purchase button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: p.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: _isPurchasing ? null : _purchaseWithGooglePlay,
            child: _isPurchasing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : const Text(
                    'Google Play로 구매하기',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Restore purchases
          TextButton(
            onPressed: _isPurchasing ? null : _restorePurchases,
            child: Text(
              '이전 구매 복원',
              style: TextStyle(
                color: p.muted,
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
