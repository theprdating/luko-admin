import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 雙按退出包裝器
///
/// 包裝在無上一頁的末端頁面（/welcome、/review/pending、/review/rejected）。
/// 使用者按下 Android 返回鍵時：
///   第一次 → 底部 SnackBar「再按一次退出程式」（2 秒計時）
///   2 秒內再按 → 呼叫 SystemNavigator.pop() 退出 APP
class ExitOnDoubleBackScope extends StatefulWidget {
  const ExitOnDoubleBackScope({super.key, required this.child});

  final Widget child;

  @override
  State<ExitOnDoubleBackScope> createState() => _ExitOnDoubleBackScopeState();
}

class _ExitOnDoubleBackScopeState extends State<ExitOnDoubleBackScope> {
  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress != null &&
            now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
        } else {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('再按一次退出程式'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: widget.child,
    );
  }
}
