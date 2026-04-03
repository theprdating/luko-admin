/// Luko 動畫時間常數
///
/// 所有 AnimatedWidget / AnimationController duration 必須使用此常數
///
/// 使用：
/// ```dart
/// AnimatedOpacity(duration: AppDurations.normal, ...)
/// AnimationController(duration: AppDurations.slow, ...)
/// ```
class AppDurations {
  AppDurations._();

  /// 極快 — hover、ripple 等細微反饋
  static const Duration instant = Duration(milliseconds: 100);

  /// 快速 — 小元件出現/消失
  static const Duration fast = Duration(milliseconds: 150);

  /// 標準 — 頁面元素過渡、按鈕狀態
  static const Duration normal = Duration(milliseconds: 300);

  /// 緩慢 — 頁面轉場、大區塊動畫
  static const Duration slow = Duration(milliseconds: 500);

  /// 極慢 — 歡迎動畫、onboarding 特效
  static const Duration xSlow = Duration(milliseconds: 800);
}
