import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/sign_out.dart';
import '../../../../core/theme/app_colors.dart';

/// 設定頁
///
/// 路由：/settings（push）
/// TODO: 語言切換、隱私政策、服務條款、聯絡客服、登出、刪除帳號
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: colors.backgroundWarm,
        elevation: 0,
        title: const Text('設定'),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              title: const Text('刪除帳號'),
              textColor: colors.error,
              leading: Icon(Icons.delete_outline, color: colors.error),
              onTap: () => context.push('/settings/delete'),
            ),
            ListTile(
              title: const Text('登出'),
              leading: const Icon(Icons.logout),
              onTap: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('登出'),
                    content: const Text('確定要登出嗎？'),
                    actions: [
                      TextButton(
                        onPressed: () => ctx.pop(false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => ctx.pop(true),
                        child: const Text('登出'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true && context.mounted) {
                  await signOutAll();
                  // GoRouter redirect 會自動導向 /welcome
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
