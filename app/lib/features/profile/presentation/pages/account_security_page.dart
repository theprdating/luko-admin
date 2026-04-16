import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/luko_button.dart';
import '../../../../l10n/app_localizations.dart';

/// 帳號安全頁
///
/// 路由：/settings/security（從設定頁底部小字入口 push）
/// 這是刪除帳號前的最後一個緩衝頁。以大量說明文字和視覺分隔增加操作門檻，
/// 並讓刪除按鈕盡量靠近頁面底部，需要主動滾動才看得到。
class AccountSecurityPage extends ConsumerWidget {
  const AccountSecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: colors.backgroundWarm,
        surfaceTintColor: colors.backgroundWarm,
        elevation: 0,
        title: Text(
          l10n.accountSecurityTitle,
          style: textTheme.titleMedium?.copyWith(
            color: colors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding, AppSpacing.md,
          AppSpacing.pagePadding, AppSpacing.xxxl,
        ),
        children: [
          // ── 說明橫幅 ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_outlined,
                    color: colors.warning, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.accountSecurityBody,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.primaryText,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── 刪除帳號區塊 ──────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: colors.cardSurface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: colors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 標題
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md,
                    AppSpacing.md, AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever_outlined,
                          color: colors.error, size: 22),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        l10n.accountSecurityDeleteTitle,
                        style: textTheme.titleSmall?.copyWith(
                          color: colors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, thickness: 1, color: colors.divider),

                // 說明文字
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l10n.accountSecurityDeleteDesc,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.primaryText,
                      height: 1.7,
                    ),
                  ),
                ),

                // 要點提醒清單
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      _BulletRow(
                        text: '所有配對與聊天紀錄',
                        colors: colors,
                      ),
                      _BulletRow(
                        text: '個人資料與照片',
                        colors: colors,
                      ),
                      _BulletRow(
                        text: '帳號無法復原',
                        colors: colors,
                        isRed: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxxl),
          const SizedBox(height: AppSpacing.xxxl),

          // ── 刪除按鈕（頁面最底部）─────────────────────────────────────
          // 刻意放在長篇說明文字之後、頁面末端，需要主動滾動才能到達。
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: colors.error.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '⚠️ 確認刪除前請先閱讀以上所有說明',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.error,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                LukoButton.primary(
                  label: l10n.accountSecurityDeleteButton,
                  onPressed: () => context.push('/settings/delete'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 要點條列 ─────────────────────────────────────────────────────────────────

class _BulletRow extends StatelessWidget {
  const _BulletRow({
    required this.text,
    required this.colors,
    this.isRed = false,
  });
  final String text;
  final AppColors colors;
  final bool isRed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isRed ? colors.error : colors.secondaryText,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: isRed ? colors.error : colors.secondaryText,
              fontWeight: isRed ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
