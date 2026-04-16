import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/exit_on_double_back_scope.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../pages/legal_scaffold.dart';

/// 等待審核頁
///
/// 路由：/review/pending（正式）或 /dev/pending（開發測試）
/// 顯示三段式狀態時間軸（申請已送出 → 審核中 → 通知發送）
/// GoRouter redirect 監聽 appUserStatusProvider：
/// 審核通過後狀態變 approved → 自動跳轉 /discover
///
/// Beta 用戶：betaPendingProvider = true 時，2.5 秒後自動轉 approved
class PendingPage extends ConsumerStatefulWidget {
  const PendingPage({super.key, this.isDevMode = false});

  /// true → 顯示左上返回箭頭回到 /dev/state-picker（僅開發用）
  final bool isDevMode;

  @override
  ConsumerState<PendingPage> createState() => _PendingPageState();
}

class _PendingPageState extends ConsumerState<PendingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    // 「審核中」的呼吸燈效果
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Beta 用戶：送出後暫時顯示 pending 動畫 2.5 秒，再自動轉 approved
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isBetaPending = ref.read(betaPendingProvider);
      if (isBetaPending) {
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (!mounted) return;
          ref.read(betaPendingProvider.notifier).state = false;
          // 讓 router 重新評估狀態，status 為 phoneVerificationRequired
          // → router 放行 /review/approved（因 betaPendingProvider 已 false）
          // 但 claim_beta_approval 已建立 approved 的 applications 記錄，
          // 所以 appUserStatusProvider 重算後 status = phoneVerificationRequired
          ref.invalidate(appUserStatusProvider);
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return ExitOnDoubleBackScope(
      child: Scaffold(
        backgroundColor: colors.backgroundWarm,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Dev 返回箭頭 ──────────────────────────────────────
                if (widget.isDevMode) ...[
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
                const Spacer(flex: 2),

                // ── 圖示 ─────────────────────────────────────────────
                Center(
                  child: _PendingIcon(colors: colors, pulse: _pulse),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── 標題 ─────────────────────────────────────────────
                Text(
                  l10n.reviewPendingTitle,
                  style: textTheme.headlineMedium?.copyWith(
                    color: colors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.reviewPendingBody,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.secondaryText,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 2),

                // ── 狀態時間軸 ────────────────────────────────────────
                _StatusTimeline(colors: colors, pulse: _pulse, l10n: l10n),

                const Spacer(flex: 3),

                // ── 聯繫我們（極小字，不放刪除按鈕）────────────────────
                // 等待審核中的用戶仍有機會通過，刻意不放刪除入口避免誘導。
                // 如需刪除請聯繫信箱，由人工處理。
                _PendingContactUs(colors: colors, l10n: l10n),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingContactUs extends StatelessWidget {
  const _PendingContactUs({required this.colors, required this.l10n});
  final AppColors colors;
  final AppLocalizations l10n;

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: kLegalEmail));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.reviewPendingEmailCopied),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _copyEmail(context),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            l10n.reviewPendingContactUs,
            style: TextStyle(
              fontSize: 12,
              color: colors.secondaryText.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            kLegalEmail,
            style: TextStyle(
              fontSize: 11,
              color: colors.secondaryText.withValues(alpha: 0.35),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── 呼吸燈圖示 ──────────────────────────────────────────────────────────────

class _PendingIcon extends StatelessWidget {
  const _PendingIcon({required this.colors, required this.pulse});
  final AppColors colors;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) => Stack(
        alignment: Alignment.center,
        children: [
          // 外暈光
          Container(
            width: 96 + 24 * pulse.value,
            height: 96 + 24 * pulse.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.forestGreen.withValues(alpha: 0.06 * pulse.value),
            ),
          ),
          // 主圓
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.forestGreenSubtle,
            ),
            child: Icon(
              Icons.hourglass_top_rounded,
              size: 36,
              color: colors.forestGreen,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 三段式狀態時間軸 ─────────────────────────────────────────────────────────

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.colors, required this.pulse, required this.l10n});
  final AppColors colors;
  final Animation<double> pulse;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        children: [
          _TimelineStep(
            colors: colors,
            label: l10n.reviewPendingStep1Label,
            sublabel: l10n.reviewPendingStep1Sub,
            state: _StepState.done,
            pulse: pulse,
          ),
          _TimelineConnector(colors: colors, filled: true),
          _TimelineStep(
            colors: colors,
            label: l10n.reviewPendingStep2Label,
            sublabel: l10n.reviewPendingStep2Sub,
            state: _StepState.active,
            pulse: pulse,
          ),
          _TimelineConnector(colors: colors, filled: false),
          _TimelineStep(
            colors: colors,
            label: l10n.reviewPendingStep3Label,
            sublabel: l10n.reviewPendingStep3Sub,
            state: _StepState.pending,
            pulse: pulse,
          ),
        ],
      ),
    );
  }
}

enum _StepState { done, active, pending }

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.colors,
    required this.label,
    required this.sublabel,
    required this.state,
    required this.pulse,
  });

  final AppColors colors;
  final String label;
  final String sublabel;
  final _StepState state;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        // ── 指示點 ─────────────────────────────────────────────
        AnimatedBuilder(
          animation: pulse,
          builder: (context, _) {
            final isActive = state == _StepState.active;
            return Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: switch (state) {
                  _StepState.done    => colors.forestGreen,
                  _StepState.active  => colors.forestGreen
                      .withValues(alpha: 0.4 + 0.6 * pulse.value),
                  _StepState.pending => colors.divider,
                },
                border: isActive ? Border.all(
                  color: colors.forestGreen.withValues(alpha: 0.3),
                  width: 2,
                ) : null,
              ),
              child: Icon(
                switch (state) {
                  _StepState.done    => Icons.check_rounded,
                  _StepState.active  => Icons.access_time_rounded,
                  _StepState.pending => Icons.radio_button_unchecked,
                },
                size: 14,
                color: switch (state) {
                  _StepState.done    => Colors.white,
                  _StepState.active  => Colors.white,
                  _StepState.pending => colors.secondaryText,
                },
              ),
            );
          },
        ),
        const SizedBox(width: AppSpacing.md),

        // ── 文字 ───────────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  color: state == _StepState.pending
                      ? colors.secondaryText
                      : colors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                sublabel,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector({required this.colors, required this.filled});
  final AppColors colors;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 13, top: 2, bottom: 2),
      child: Container(
        width: 2,
        height: AppSpacing.lg,
        color: filled
            ? colors.forestGreen.withValues(alpha: 0.4)
            : colors.divider,
      ),
    );
  }
}
