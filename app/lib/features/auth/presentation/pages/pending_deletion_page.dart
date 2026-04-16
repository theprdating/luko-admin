import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/sign_out.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/exit_on_double_back_scope.dart';
import '../../../../core/widgets/luko_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';

/// 帳號刪除排程頁
///
/// 路由：/review/deletion-pending
/// 當用戶提交刪除申請後（deletion_requests 有未取消的記錄），自動導至此頁。
/// 顯示預計刪除日期，並提供：
///   - 取消刪除申請（恢復原本狀態）
///   - 登出
class PendingDeletionPage extends ConsumerStatefulWidget {
  const PendingDeletionPage({super.key});

  @override
  ConsumerState<PendingDeletionPage> createState() => _PendingDeletionPageState();
}

class _PendingDeletionPageState extends ConsumerState<PendingDeletionPage> {
  DateTime? _scheduledFor;
  bool _isLoading = true;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadScheduledDate();
  }

  Future<void> _loadScheduledDate() async {
    try {
      final supabase = ref.read(supabaseProvider);
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final row = await supabase
          .from('deletion_requests')
          .select('scheduled_for')
          .eq('user_id', userId)
          .filter('cancelled_at', 'is', null)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _scheduledFor = row != null
            ? DateTime.tryParse(row['scheduled_for'] as String)
            : null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[PendingDeletionPage] _loadScheduledDate failed: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelDeletion() async {
    setState(() => _isCancelling = true);

    try {
      final supabase = ref.read(supabaseProvider);
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase
          .from('deletion_requests')
          .update({'cancelled_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId);

      if (!mounted) return;

      // 讓 Router 重新判斷狀態（回到 rejected 或 pending）
      ref.invalidate(appUserStatusProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pendingDeletionCancelSuccess),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('[PendingDeletionPage] _cancelDeletion failed: $e');
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'zh') {
      return '${date.year}年${date.month}月${date.day}日';
    }
    return DateFormat('MMMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return ExitOnDoubleBackScope(
      child: Scaffold(
        backgroundColor: colors.backgroundWarm,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),

                // ── 圖示 ─────────────────────────────────────────────
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.warning.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      Icons.hourglass_bottom_rounded,
                      size: 36,
                      color: colors.warning,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── 標題 ─────────────────────────────────────────────
                Text(
                  l10n.pendingDeletionTitle,
                  style: textTheme.headlineMedium?.copyWith(
                    color: colors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.pendingDeletionBody,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.secondaryText,
                    height: 1.65,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── 日期卡片 ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: colors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.divider),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.pendingDeletionDateLabel,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _scheduledFor != null
                                  ? _formatDate(context, _scheduledFor!)
                                  : '—',
                              style: textTheme.titleMedium?.copyWith(
                                color: colors.primaryText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // ── 動作區 ────────────────────────────────────────────
                LukoButton.secondary(
                  label: l10n.pendingDeletionCancelButton,
                  onPressed: _isCancelling ? null : _cancelDeletion,
                  isLoading: _isCancelling,
                ),
                const SizedBox(height: AppSpacing.md),
                LukoButton.ghost(
                  label: l10n.pendingDeletionSignOut,
                  onPressed: signOutAll,
                  isFullWidth: true,
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
