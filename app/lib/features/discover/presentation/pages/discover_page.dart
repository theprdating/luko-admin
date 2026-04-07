import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 探索頁 — 卡片滑動配對
///
/// 路由：/discover（ShellRoute tab 0）
/// TODO: 實作卡片堆疊、右滑 Like / 左滑 Pass、預載 Queue
class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: colors.backgroundWarm,
        elevation: 0,
        title: Text(
          'PR Dating',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colors.forestGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: const SafeArea(
        child: Center(child: Text('DiscoverPage — TODO')),
      ),
    );
  }
}
