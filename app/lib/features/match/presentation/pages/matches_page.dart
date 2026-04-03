import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 配對列表頁
///
/// 路由：/matches（ShellRoute tab 1）
/// TODO: 列出所有配對，新配對顯示在最上方並有光環效果
class MatchesPage extends StatelessWidget {
  const MatchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: colors.backgroundWarm,
        elevation: 0,
        title: const Text('配對'),
      ),
      body: const SafeArea(
        child: Center(child: Text('MatchesPage — TODO')),
      ),
    );
  }
}
