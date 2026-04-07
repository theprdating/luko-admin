import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// 審核通過告知頁
///
/// 路由：/review/approved
/// 狀態：phoneVerificationRequired（審核通過，手機尚未綁定）
///
/// 流程：pending → [此頁] → /verify/phone → /discover
///
/// 設計：深色品牌底（brandBg #0F1E15）+ 金色徽章，呈現「入選時刻」的儀式感。
/// 背景色刻意沿用 /verify/phone 的 brandBg，讓整段手機綁定流程視覺連貫。
class ApprovedGatePage extends ConsumerStatefulWidget {
  const ApprovedGatePage({super.key});

  @override
  ConsumerState<ApprovedGatePage> createState() => _ApprovedGatePageState();
}

class _ApprovedGatePageState extends ConsumerState<ApprovedGatePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _badgeFade;
  late final Animation<double> _badgeScale;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _buttonFade;

  String? _qualityTier; // 'top' | 'standard' | null（載入中或未知）

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _badgeFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    // elasticOut 給 badge 一個「彈入」感，強調入選時刻
    _badgeScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );
    _contentFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOut),
    ));
    _buttonFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    );

    _loadTier();
  }

  Future<void> _loadTier() async {
    try {
      final supabase = ref.read(supabaseProvider);
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final row = await supabase
          .from('applications')
          .select('quality_tier')
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() => _qualityTier = row?['quality_tier'] as String?);
      }
    } catch (_) {
      // 靜默失敗，保持 null → 顯示通用說明文字
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors  = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n    = AppLocalizations.of(context)!;
    final bottom  = MediaQuery.paddingOf(context).bottom;

    // 根據 quality_tier 選擇說明文字
    final bodyText = switch (_qualityTier) {
      'top'      => l10n.approvedGateBodyTop,
      'standard' => l10n.approvedGateBodyStandard,
      _          => l10n.approvedGateBody,
    };

    return Scaffold(
      backgroundColor: colors.backgroundWarm,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            0,
            AppSpacing.pagePadding,
            bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),

              // ── 徽章 ─────────────────────────────────────────────
              FadeTransition(
                opacity: _badgeFade,
                child: ScaleTransition(
                  scale: _badgeScale,
                  child: Center(
                    child: _ApprovalBadge(colors: colors),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── 標題 + 說明文字 ───────────────────────────────────
              FadeTransition(
                opacity: _contentFade,
                child: SlideTransition(
                  position: _contentSlide,
                  child: Column(
                    children: [
                      // 小徽章標籤
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.forestGreenSubtle,
                          border: Border.all(
                            color: colors.forestGreen.withValues(alpha: 0.35),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l10n.approvedGateBadge,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.forestGreen,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 主標題
                      Text(
                        l10n.approvedGateTitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: colors.primaryText,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 說明文字（依 quality_tier 顯示不同內容）
                      Text(
                        bodyText,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.secondaryText,
                          height: 1.7,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // ── 方案標籤（有 tier 時才顯示）──────────────
                      if (_qualityTier != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _TierBadge(qualityTier: _qualityTier!, colors: colors, l10n: l10n),
                      ],
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 4),

              // ── CTA ───────────────────────────────────────────────
              FadeTransition(
                opacity: _buttonFade,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/verify/phone'),
                      child: Container(
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.forestGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          l10n.approvedGateCta,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.brandOnDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.approvedGateNote,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: colors.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: bottom > 0 ? 0 : 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 方案標籤 ─────────────────────────────────────────────────────────────────
//
// top     → 綠色 badge「創始成員 · 終生免費」
// standard → 琥珀色 badge「5 天免費體驗」

class _TierBadge extends StatelessWidget {
  const _TierBadge({
    required this.qualityTier,
    required this.colors,
    required this.l10n,
  });

  final String qualityTier;
  final AppColors colors;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isTop = qualityTier == 'top';
    final bgColor = isTop
        ? colors.forestGreenSubtle
        : colors.warning.withValues(alpha: 0.1);
    final borderColor = isTop
        ? colors.forestGreen.withValues(alpha: 0.35)
        : colors.warning.withValues(alpha: 0.4);
    final textColor = isTop ? colors.forestGreen : colors.warning;
    final label = isTop
        ? l10n.approvedGateTierLabelTop
        : l10n.approvedGateTierLabelStandard;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.3,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── 金色通過徽章 ─────────────────────────────────────────────────────────────
//
// 雙層圓圈：外圈淡金暈光、內圈金框 + 勾勾圖示
// 視覺語言與 WelcomeInPage 的白色 check circle 相呼應，但用金色表達「入選」

class _ApprovalBadge extends StatelessWidget {
  const _ApprovalBadge({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 外圈暈光
        Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.forestGreen.withValues(alpha: 0.07),
            border: Border.all(
              color: colors.forestGreen.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
        ),
        // 內圈主體
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.forestGreenSubtle,
            border: Border.all(
              color: colors.forestGreen.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.check_rounded,
            size: 40,
            color: colors.forestGreen,
          ),
        ),
      ],
    );
  }
}
