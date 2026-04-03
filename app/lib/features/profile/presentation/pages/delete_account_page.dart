import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/luko_button.dart';

/// 刪除帳號確認頁
///
/// 路由：/settings/delete
/// Apple 強制要求：App 內必須提供刪除帳號功能
/// TODO: 確認後執行 Supabase Auth 刪除 + soft delete profiles
class DeleteAccountPage extends StatelessWidget {
  const DeleteAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: colors.backgroundWarm,
        elevation: 0,
        title: const Text('刪除帳號'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                '確定要刪除帳號？',
                style: textTheme.headlineSmall?.copyWith(color: colors.primaryText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '刪除帳號後，您的所有資料、配對及訊息將永久無法復原。',
                style: textTheme.bodyMedium?.copyWith(color: colors.secondaryText),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // TODO: 實作刪除邏輯
              LukoButton.primary(
                label: '確認刪除帳號',
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.sm),
              LukoButton.ghost(
                label: '取消',
                onPressed: () => Navigator.of(context).pop(),
                isFullWidth: true,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
