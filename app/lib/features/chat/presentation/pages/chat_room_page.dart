import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 聊天室頁
///
/// 路由：/messages/:matchId（在 Shell 外，全螢幕）
/// 接收 [matchId] 參數
/// TODO: 載入最後 50 筆訊息 + Supabase Realtime 新訊息接收
class ChatRoomPage extends StatelessWidget {
  const ChatRoomPage({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: colors.backgroundWarm,
        elevation: 0,
        title: const Text('聊天室'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {
              // TODO: 顯示封鎖 / 檢舉選單
            },
          ),
        ],
      ),
      // resizeToAvoidBottomInset: true 確保鍵盤彈出時輸入列上移
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Text('ChatRoomPage — matchId: $matchId — TODO'),
              ),
            ),
          ),
          // 底部輸入列：SafeArea(top: false) 只保護底部安全區域
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '輸入訊息...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      // TODO: 送出訊息
                    },
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
