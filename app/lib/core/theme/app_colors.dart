import 'package:flutter/material.dart';

/// Luko 品牌色彩系統
///
/// 使用方式：
/// ```dart
/// final colors = Theme.of(context).extension<AppColors>()!;
/// Container(color: colors.forestGreen)
/// ```
///
/// 透明度規範：
/// ```dart
/// // ✅ 正確
/// colors.forestGreen.withValues(alpha: 0.5)
/// // ❌ 禁止（已棄用）
/// colors.forestGreen.withOpacity(0.5)
/// ```
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.forestGreen,
    required this.forestGreenSubtle,
    required this.forestDeep,
    required this.backgroundWarm,
    required this.primaryText,
    required this.secondaryText,
    required this.cardSurface,
    required this.divider,
    required this.success,
    required this.error,
    required this.warning,
    required this.brandBg,
    required this.brandSpot,
    required this.brandGold,
    required this.brandOnDark,
    required this.brandCaption,
    required this.brandButtonBg,
  });

  /// 主強調色 — Forest Green
  final Color forestGreen;

  /// 強調色淡版 — 用於背景 badge、highlight
  final Color forestGreenSubtle;

  /// 深森林面 — 介於 backgroundWarm 與 forestGreen 之間的中間層
  ///
  /// 用途：全綠螢幕的次要表面、遮罩層、分隔線填色
  /// Dark:  #162E24（ = onboarding/welcome 的次層）
  /// Light: #DFF0E7（極淡薄荷，用於 badge 背景等）
  final Color forestDeep;

  /// 頁面底色
  final Color backgroundWarm;

  /// 主文字色
  final Color primaryText;

  /// 次要文字色（副標、說明文字）
  final Color secondaryText;

  /// 卡片背景色
  final Color cardSurface;

  /// 分隔線色
  final Color divider;

  /// 成功狀態色
  final Color success;

  /// 錯誤狀態色
  final Color error;

  /// 警告狀態色
  final Color warning;

  // ─── 品牌沉浸式畫面色（Welcome、Login、Apply Phone、Onboarding）
  // 這些畫面永遠是深色，與系統 Light/Dark 模式無關。
  // 放入 AppColors 統一管理，避免各檔案散落硬寫色碼。

  /// 品牌沉浸頁底色（#0F1E15，最深森林色）
  final Color brandBg;

  /// 品牌 Spotlight 色（#1E3D2F，icon 背後放射漸層中心）
  final Color brandSpot;

  /// 品牌金色（#C9A96E，金線、強調文字、連結）
  final Color brandGold;

  /// 品牌沉浸頁主文字色（#F0FDF4，近白綠，用於標題）
  final Color brandOnDark;

  /// 品牌沉浸頁次要文字色（38% 白，用於說明文字）
  final Color brandCaption;

  /// 品牌沉浸頁按鈕背景色（#EDF7F0，淡薄荷，用於暗底 CTA）
  final Color brandButtonBg;

  // ─── Light Mode ───────────────────────────────────────
  static const light = AppColors(
    forestGreen:       Color(0xFF3D6B4F),
    forestGreenSubtle: Color(0x1F3D6B4F), // 12% alpha
    forestDeep:        Color(0xFFDFF0E7), // 極淡薄荷（同色族高亮度）
    backgroundWarm:    Color(0xFFF4F7F4),
    primaryText:       Color(0xFF1A2219),
    secondaryText:     Color(0xFF748070),
    cardSurface:       Color(0xFFFFFFFF),
    divider:           Color(0xFFE8EDE8),
    success:           Color(0xFF3D6B4F),
    error:             Color(0xFFB3261E),
    warning:           Color(0xFFC47A1E),
    brandBg:           Color(0xFF0F1E15),
    brandSpot:         Color(0xFF1E3D2F),
    brandGold:         Color(0xFFC9A96E),
    brandOnDark:       Color(0xFFF0FDF4),
    brandCaption:      Color(0x61FFFFFF),
    brandButtonBg:     Color(0xFFEDF7F0),
  );

  // ─── Dark Mode ────────────────────────────────────────
  static const dark = AppColors(
    forestGreen:       Color(0xFF5A8F6D),
    forestGreenSubtle: Color(0x1F5A8F6D), // 12% alpha
    forestDeep:        Color(0xFF162E24), // 深森林中間層
    backgroundWarm:    Color(0xFF111614),
    primaryText:       Color(0xFFF0F4F0),
    secondaryText:     Color(0xFF8A9E89),
    cardSurface:       Color(0xFF1C2420),
    divider:           Color(0xFF2A352A),
    success:           Color(0xFF5A8F6D),
    error:             Color(0xFFCF6679),
    warning:           Color(0xFFE6A830),
    brandBg:           Color(0xFF0F1E15),
    brandSpot:         Color(0xFF1E3D2F),
    brandGold:         Color(0xFFC9A96E),
    brandOnDark:       Color(0xFFF0FDF4),
    brandCaption:      Color(0x61FFFFFF),
    brandButtonBg:     Color(0xFFEDF7F0),
  );

  // ─── ThemeExtension 必要實作 ──────────────────────────

  @override
  AppColors copyWith({
    Color? forestGreen,
    Color? forestGreenSubtle,
    Color? forestDeep,
    Color? backgroundWarm,
    Color? primaryText,
    Color? secondaryText,
    Color? cardSurface,
    Color? divider,
    Color? success,
    Color? error,
    Color? warning,
    Color? brandBg,
    Color? brandSpot,
    Color? brandGold,
    Color? brandOnDark,
    Color? brandCaption,
    Color? brandButtonBg,
  }) {
    return AppColors(
      forestGreen:       forestGreen       ?? this.forestGreen,
      forestGreenSubtle: forestGreenSubtle ?? this.forestGreenSubtle,
      forestDeep:        forestDeep        ?? this.forestDeep,
      backgroundWarm:    backgroundWarm    ?? this.backgroundWarm,
      primaryText:       primaryText       ?? this.primaryText,
      secondaryText:     secondaryText     ?? this.secondaryText,
      cardSurface:       cardSurface       ?? this.cardSurface,
      divider:           divider           ?? this.divider,
      success:           success           ?? this.success,
      error:             error             ?? this.error,
      warning:           warning           ?? this.warning,
      brandBg:           brandBg           ?? this.brandBg,
      brandSpot:         brandSpot         ?? this.brandSpot,
      brandGold:         brandGold         ?? this.brandGold,
      brandOnDark:       brandOnDark       ?? this.brandOnDark,
      brandCaption:      brandCaption      ?? this.brandCaption,
      brandButtonBg:     brandButtonBg     ?? this.brandButtonBg,
    );
  }

  /// lerp 讓 Light/Dark 切換時顏色平滑過渡（AnimatedTheme 會呼叫此方法）
  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      forestGreen:       Color.lerp(forestGreen,       other.forestGreen,       t)!,
      forestGreenSubtle: Color.lerp(forestGreenSubtle, other.forestGreenSubtle, t)!,
      forestDeep:        Color.lerp(forestDeep,        other.forestDeep,        t)!,
      backgroundWarm:    Color.lerp(backgroundWarm,    other.backgroundWarm,    t)!,
      primaryText:       Color.lerp(primaryText,       other.primaryText,       t)!,
      secondaryText:     Color.lerp(secondaryText,     other.secondaryText,     t)!,
      cardSurface:       Color.lerp(cardSurface,       other.cardSurface,       t)!,
      divider:           Color.lerp(divider,           other.divider,           t)!,
      success:           Color.lerp(success,           other.success,           t)!,
      error:             Color.lerp(error,             other.error,             t)!,
      warning:           Color.lerp(warning,           other.warning,           t)!,
      brandBg:           Color.lerp(brandBg,           other.brandBg,           t)!,
      brandSpot:         Color.lerp(brandSpot,         other.brandSpot,         t)!,
      brandGold:         Color.lerp(brandGold,         other.brandGold,         t)!,
      brandOnDark:       Color.lerp(brandOnDark,       other.brandOnDark,       t)!,
      brandCaption:      Color.lerp(brandCaption,      other.brandCaption,      t)!,
      brandButtonBg:     Color.lerp(brandButtonBg,     other.brandButtonBg,     t)!,
    );
  }
}
