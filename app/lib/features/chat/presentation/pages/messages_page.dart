import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 訊息列表頁
///
/// 路由：/messages（ShellRoute tab 2）
/// TODO: 列出所有進行中的對話，顯示最後一則訊息和時間
class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: colors.backgroundWarm,
        elevation: 0,
        title: const Text('訊息'),
      ),
      body: const SafeArea(
        child: Center(child: Text('MessagesPage — TODO')),
      ),
    );
  }
}
