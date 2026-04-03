import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 對方個人檔案頁
///
/// 路由：/profile/:userId（push，全螢幕）
/// 接收 [userId] 參數
/// TODO: 顯示對方的照片、名稱、Bio，提供封鎖 / 檢舉入口
class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: colors.backgroundWarm,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {
              // TODO: 封鎖 / 檢舉選單
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Text('UserProfilePage — userId: $userId — TODO'),
        ),
      ),
    );
  }
}
