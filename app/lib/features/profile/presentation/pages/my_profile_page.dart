import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

/// 我的個人檔案頁
///
/// 路由：/me（ShellRoute tab 3）
/// TODO: 顯示自己的公開檔案樣式，提供編輯和設定入口
class MyProfilePage extends StatelessWidget {
  const MyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: colors.backgroundWarm,
        elevation: 0,
        title: const Text('我的'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: TextButton(
            onPressed: () => context.push('/me/edit'),
            child: const Text('編輯資料（TODO）'),
          ),
        ),
      ),
    );
  }
}
