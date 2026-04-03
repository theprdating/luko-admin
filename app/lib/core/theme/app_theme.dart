import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_theme.dart';

/// Luko Theme 統一入口
///
/// 使用方式（main.dart）：
/// ```dart
/// MaterialApp(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
/// )
/// ```
class AppTheme {
  AppTheme._();

  // ─── Light Mode ───────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary:          Color(0xFF3D6B4F),
      onPrimary:        Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFB8D8C5),
      secondary:        Color(0xFF748070),
      onSecondary:      Color(0xFFFFFFFF),
      surface:          Color(0xFFF4F7F4),
      onSurface:        Color(0xFF1A2219),
      error:            Color(0xFFB3261E),
      onError:          Color(0xFFFFFFFF),
    ),
    scaffoldBackgroundColor: const Color(0xFFF4F7F4),
    textTheme: AppTextTheme.textTheme,
    extensions: const [AppColors.light],
    splashFactory: NoSplash.splashFactory,      // 移除 Material 點擊水波，換成自訂動畫
    highlightColor: Colors.transparent,
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE8EDE8),
      thickness: 1,
      space: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF4F7F4),
      foregroundColor: Color(0xFF1A2219),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,   // 淺色頁面 → 深色圖示
        statusBarBrightness: Brightness.light,       // iOS
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      selectedItemColor: Color(0xFF3D6B4F),
      unselectedItemColor: Color(0xFF748070),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
  );

  // ─── Dark Mode ────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary:          Color(0xFF5A8F6D),
      onPrimary:        Color(0xFFFFFFFF),
      primaryContainer: Color(0xFF2A4F38),
      secondary:        Color(0xFF8A9E89),
      onSecondary:      Color(0xFF111614),
      surface:          Color(0xFF111614),
      onSurface:        Color(0xFFF0F4F0),
      error:            Color(0xFFCF6679),
      onError:          Color(0xFF111614),
    ),
    scaffoldBackgroundColor: const Color(0xFF111614),
    textTheme: AppTextTheme.textTheme,
    extensions: const [AppColors.dark],
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2A352A),
      thickness: 1,
      space: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF111614),
      foregroundColor: Color(0xFFF0F4F0),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,  // 深色頁面 → 白色圖示
        statusBarBrightness: Brightness.dark,        // iOS
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1C2420),
      selectedItemColor: Color(0xFF5A8F6D),
      unselectedItemColor: Color(0xFF8A9E89),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
