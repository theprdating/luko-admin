import 'package:flutter/material.dart';

/// Luko 圓角常數
///
/// 使用：
/// ```dart
/// BorderRadius.circular(AppRadius.card)
/// BorderRadius.circular(AppRadius.button)
/// ```
class AppRadius {
  AppRadius._();

  static const double xs     =  4.0;
  static const double sm     =  8.0;
  static const double md     = 12.0;
  static const double lg     = 16.0;
  static const double xl     = 24.0;
  static const double full   = 999.0; // 完全圓形（膠囊形按鈕、頭像）

  /// 卡片圓角
  static const double card   = lg;

  /// 按鈕圓角（主要 CTA）
  static const double button = full;

  /// 輸入框圓角
  static const double input  = md;

  /// 底部彈窗圓角（top-left, top-right）
  static BorderRadius get bottomSheet => const BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}
