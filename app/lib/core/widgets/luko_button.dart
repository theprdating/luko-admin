import 'package:flutter/material.dart';

import '../constants/app_radius.dart';
import '../theme/app_colors.dart';

/// Luko 主要按鈕元件
///
/// 三種 variant，透過 Named Constructor 建立：
/// - [LukoButton.primary]   — 填滿主色背景，用於主要 CTA（如「下一步」「送出」）
/// - [LukoButton.secondary] — 透明背景 + 主色邊框，用於次要動作（如「查看資料」）
/// - [LukoButton.ghost]     — 純文字，用於低優先級動作（如「略過」「取消」）
///
/// 使用範例：
/// ```dart
/// LukoButton.primary(label: '下一步', onPressed: _onNext)
/// LukoButton.secondary(label: '查看資料', onPressed: _onView)
/// LukoButton.ghost(label: '略過', onPressed: _onSkip)
///
/// // 載入狀態（禁用點擊 + 顯示 spinner）
/// LukoButton.primary(label: '送出', onPressed: _submit, isLoading: true)
///
/// // 非全寬（ghost 預設 false，其他預設 true）
/// LukoButton.secondary(label: '取消', onPressed: _cancel, isFullWidth: false)
/// ```
class LukoButton extends StatelessWidget {
  /// 主要 CTA 按鈕：填滿 forestGreen 背景
  const LukoButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
  }) : _variant = _ButtonVariant.primary;

  /// 次要按鈕：透明背景 + forestGreen 邊框
  const LukoButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
  }) : _variant = _ButtonVariant.secondary;

  /// 幽靈按鈕：純文字，用於低優先級動作
  const LukoButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : _variant = _ButtonVariant.ghost;

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final _ButtonVariant _variant;

  static const double _height = 52.0;
  static const double _spinnerSize = 20.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Widget button = switch (_variant) {
      _ButtonVariant.primary   => _PrimaryButton(
          colors: colors, label: label,
          onPressed: isLoading ? null : onPressed,
          isLoading: isLoading,
        ),
      _ButtonVariant.secondary => _SecondaryButton(
          colors: colors, label: label,
          onPressed: isLoading ? null : onPressed,
          isLoading: isLoading,
        ),
      _ButtonVariant.ghost     => _GhostButton(
          colors: colors, label: label,
          onPressed: isLoading ? null : onPressed,
        ),
    };

    if (isFullWidth) {
      return SizedBox(width: double.infinity, height: _height, child: button);
    }
    return SizedBox(height: _height, child: button);
  }
}

// ── Variant Implementations ──────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.colors,
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  final AppColors colors;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.forestGreen,
        foregroundColor: Colors.white,
        disabledBackgroundColor: colors.forestGreen.withValues(alpha: 0.5),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
        ),
      ),
      child: _ButtonContent(
        label: label,
        isLoading: isLoading,
        contentColor: Colors.white,
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.colors,
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  final AppColors colors;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.forestGreen,
        side: BorderSide(color: colors.forestGreen, width: 1.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
        ),
      ),
      child: _ButtonContent(
        label: label,
        isLoading: isLoading,
        contentColor: colors.forestGreen,
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.colors,
    required this.label,
    required this.onPressed,
  });

  final AppColors colors;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: colors.secondaryText,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colors.secondaryText,
        ),
      ),
    );
  }
}

// ── Shared Loading Content ───────────────────────────────────────────────────

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.isLoading,
    required this.contentColor,
  });

  final String label;
  final bool isLoading;
  final Color contentColor;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: LukoButton._spinnerSize,
        height: LukoButton._spinnerSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(contentColor),
        ),
      );
    }

    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: contentColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

enum _ButtonVariant { primary, secondary, ghost }
