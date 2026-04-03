import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';

/// 全頁載入遮罩
///
/// 在 isLoading 為 true 時覆蓋整個畫面，並透過 [AbsorbPointer]
/// 阻擋所有觸控事件，防止用戶在非同步操作進行中重複觸發動作。
///
/// 使用範例：
/// ```dart
/// LukoLoadingOverlay(
///   isLoading: _isUploading,
///   message: '上傳照片中...',
///   child: YourPageContent(),
/// )
/// ```
class LukoLoadingOverlay extends StatelessWidget {
  const LukoLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  final bool isLoading;
  final Widget child;

  /// 顯示在 spinner 下方的說明文字（可省略）
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          // AbsorbPointer：吸收所有觸控事件，讓底層 child 無法互動
          AbsorbPointer(
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                  if (message != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      message!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
