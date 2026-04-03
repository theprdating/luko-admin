import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 編輯個人檔案頁
///
/// 路由：/me/edit（push，全螢幕 form）
/// TODO: 修改顯示名稱、Bio、城市，更換照片
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: colors.backgroundWarm,
        elevation: 0,
        title: const Text('編輯資料'),
      ),
      // resizeToAvoidBottomInset 確保鍵盤彈出時 body 上移
      resizeToAvoidBottomInset: true,
      body: const SafeArea(
        child: Center(child: Text('EditProfilePage — TODO')),
      ),
    );
  }
}
