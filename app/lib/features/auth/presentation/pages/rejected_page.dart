import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/exit_on_double_back_scope.dart';
import '../../../../core/widgets/luko_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';

const _kMaxAttempts = 3;

/// 審核未通過頁
///
/// 路由：/review/rejected
/// 根據 applications.rejection_type 顯示不同內容：
///   soft / null → 一般拒絕畫面
///   hard        → 後台靜默封鎖，不會到達此頁
///
/// 重新申請規則：
///   - 無等待期，拒絕後可立即重新申請
///   - 每個帳號最多 3 次機會（application_count >= 3 時停用按鈕）
class RejectedPage extends ConsumerStatefulWidget {
  const RejectedPage({super.key, this.devRejectionType});

  /// Dev 模式覆寫：傳入 'soft' 可繞過 DB 查詢直接渲染對應畫面
  final String? devRejectionType;

  @override
  ConsumerState<RejectedPage> createState() => _RejectedPageState();
}

class _RejectedPageState extends ConsumerState<RejectedPage> {
  String? _rejectionType;    // 'soft' | 'hard' | null
  String? _reviewNote;
  int _applicationCount = 1; // 目前第幾次申請（1–3）
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Dev 模式：直接套用覆寫類型，跳過 DB 查詢
    if (widget.devRejectionType != null) {
      setState(() {
        _rejectionType    = widget.devRejectionType;
        _applicationCount = 1;
        _isLoading        = false;
      });
      return;
    }

    try {
      final supabase = ref.read(supabaseProvider);
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final row = await supabase
          .from('applications')
          .select('rejection_type, review_note, application_count')
          .eq('user_id', userId)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _rejectionType    = row?['rejection_type'] as String?;
        _reviewNote       = row?['review_note'] as String?;
        _applicationCount = (row?['application_count'] as int?) ?? 1;
        _isLoading        = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reapply() async {
    final supabase = ref.read(supabaseProvider);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase
          .from('applications')
          .update({'status': 'pending', 'reapply_after': null})
          .eq('user_id', userId);

      ref.invalidate(appUserStatusProvider);
      if (mounted) context.go('/apply/photos');
    } on PostgrestException {
      // 靜默失敗，讓用戶再試一次
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors    = Theme.of(context).extension<AppColors>()!;
    final l10n      = AppLocalizations.of(context)!;
    final isPotential = _rejectionType == 'soft';

    return ExitOnDoubleBackScope(
      child: Scaffold(
        backgroundColor: colors.backgroundWarm,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Dev 返回箭頭 ──────────────────────────────────────
                if (widget.devRejectionType != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  GestureDetector(
                    onTap: () => context.go('/dev/state-picker'),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8, right: 20),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: colors.secondaryText,
                        size: 20,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),

                // ── 圖示 ──────────────────────────────────────────────
                Center(
                  child: _RejectedIcon(colors: colors, isPotential: isPotential),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── 標題 ──────────────────────────────────────────────
                Text(
                  isPotential
                      ? l10n.reviewRejectedTitlePotential
                      : l10n.reviewRejectedTitleSoft,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),

                // ── 說明文字 ───────────────────────────────────────────
                Text(
                  isPotential
                      ? l10n.reviewRejectedBodyPotential
                      : l10n.reviewRejectedBodySoft,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.secondaryText,
                    height: 1.65,
                  ),
                  textAlign: TextAlign.center,
                ),

                // ── 改善建議 ───────────────────────────────────────────
                // soft（差一點）：顯示個人化建議 + 通用改善 tips
                // hard（不通過）：顯示中性通用建議（不涉及外貌評論）
                if (isPotential) ...[
                  const SizedBox(height: AppSpacing.xl),
                  if (_reviewNote != null && _reviewNote!.isNotEmpty) ...[
                    _AdminFeedbackCard(
                      reviewNote: _reviewNote!,
                      colors: colors,
                      l10n: l10n,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _ImprovementTips(colors: colors, l10n: l10n),
                ] else ...[
                  const SizedBox(height: AppSpacing.xl),
                  _ImprovementTips(colors: colors, l10n: l10n, isHard: true),
                ],

                const SizedBox(height: AppSpacing.xl),

                // ── 重申請卡片 ─────────────────────────────────────────
                if (!_isLoading)
                  _ReapplyCard(
                    colors: colors,
                    l10n: l10n,
                    applicationCount: _applicationCount,
                    onReapply: _reapply,
                  )
                else
                  const Center(child: CircularProgressIndicator()),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 圖示 ─────────────────────────────────────────────────────────────────────

class _RejectedIcon extends StatelessWidget {
  const _RejectedIcon({required this.colors, required this.isPotential});
  final AppColors colors;
  final bool isPotential;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPotential
            ? colors.forestGreenSubtle
            : colors.warning.withValues(alpha: 0.12),
      ),
      child: Icon(
        isPotential ? Icons.auto_awesome_rounded : Icons.schedule_rounded,
        size: 36,
        color: isPotential ? colors.forestGreen : colors.warning,
      ),
    );
  }
}

// ── 審核員個人化建議卡片 ──────────────────────────────────────────────────────

class _AdminFeedbackCard extends StatelessWidget {
  const _AdminFeedbackCard({
    required this.reviewNote,
    required this.colors,
    required this.l10n,
  });

  final String reviewNote;
  final AppColors colors;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.forestGreenSubtle,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.forestGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rate_review_rounded, size: 16, color: colors.forestGreen),
              const SizedBox(width: 6),
              Text(
                l10n.reviewAdminFeedbackTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.forestGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            reviewNote,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.primaryText,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 改善建議卡片 ──────────────────────────────────────────────────────────────
//
// isHard = false（soft / 差一點）：使用針對性改善建議（照片光線、清晰度等）
// isHard = true（hard / 不通過）：使用中性建議，避免讓用戶感覺被評論外貌

class _ImprovementTips extends StatelessWidget {
  const _ImprovementTips({required this.colors, required this.l10n, this.isHard = false});
  final AppColors colors;
  final AppLocalizations l10n;
  final bool isHard;

  @override
  Widget build(BuildContext context) {
    final tips = isHard
        ? [
            l10n.reviewRejectedHardTip1,
            l10n.reviewRejectedHardTip2,
            l10n.reviewRejectedHardTip3,
          ]
        : [
            l10n.reviewRejectedTip1,
            l10n.reviewRejectedTip2,
            l10n.reviewRejectedTip3,
          ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tips.asMap().entries.map((entry) {
          final isLast = entry.key == tips.length - 1;
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.forestGreenSubtle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.forestGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.primaryText,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isLast) const SizedBox(height: AppSpacing.md),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── 重申請卡片 ───────────────────────────────────────────────────────────────

class _ReapplyCard extends StatelessWidget {
  const _ReapplyCard({
    required this.colors,
    required this.l10n,
    required this.applicationCount,
    required this.onReapply,
  });

  final AppColors colors;
  final AppLocalizations l10n;
  final int applicationCount;
  final VoidCallback onReapply;

  bool get _attemptsExhausted => applicationCount >= _kMaxAttempts;
  int get _attemptsRemaining  => (_kMaxAttempts - applicationCount).clamp(0, _kMaxAttempts);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.divider),
      ),
      child: _attemptsExhausted
          ? _ExhaustedState(colors: colors, l10n: l10n, textTheme: textTheme)
          : _ReapplyAvailableState(
              colors: colors,
              l10n: l10n,
              textTheme: textTheme,
              attemptsRemaining: _attemptsRemaining,
              onReapply: onReapply,
            ),
    );
  }
}

// 已用完所有機會
class _ExhaustedState extends StatelessWidget {
  const _ExhaustedState({
    required this.colors,
    required this.l10n,
    required this.textTheme,
  });

  final AppColors colors;
  final AppLocalizations l10n;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.block_rounded, size: 32, color: colors.secondaryText),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.reviewReapplyExhaustedTitle,
          style: textTheme.labelLarge?.copyWith(
            color: colors.primaryText,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.reviewReapplyExhaustedBody,
          style: textTheme.bodySmall?.copyWith(
            color: colors.secondaryText,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// 可以重新申請
class _ReapplyAvailableState extends StatelessWidget {
  const _ReapplyAvailableState({
    required this.colors,
    required this.l10n,
    required this.textTheme,
    required this.attemptsRemaining,
    required this.onReapply,
  });

  final AppColors colors;
  final AppLocalizations l10n;
  final TextTheme textTheme;
  final int attemptsRemaining;
  final VoidCallback onReapply;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.refresh_rounded, size: 32, color: colors.forestGreen),
        const SizedBox(height: AppSpacing.sm),
        LukoButton.primary(
          label: l10n.reviewReapplyButton,
          onPressed: onReapply,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.reviewReapplyAttemptsLeft(attemptsRemaining),
          style: textTheme.bodySmall?.copyWith(
            color: colors.secondaryText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
