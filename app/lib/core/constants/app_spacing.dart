/// Luko 間距常數
///
/// 所有 padding / margin / SizedBox 必須使用這裡的常數，
/// 禁止直接寫數字（如 SizedBox(height: 16)）
///
/// 使用：
/// ```dart
/// SizedBox(height: AppSpacing.md)
/// Padding(padding: EdgeInsets.all(AppSpacing.lg))
/// ```
class AppSpacing {
  AppSpacing._();

  static const double xxs =  2.0;
  static const double xs  =  4.0;
  static const double sm  =  8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  /// 頁面左右標準邊距
  static const double pagePadding = md;

  /// 卡片內部標準邊距
  static const double cardPadding = md;

  /// 元件之間的標準間距
  static const double itemGap = sm;

  /// section 之間的間距
  static const double sectionGap = xl;
}
