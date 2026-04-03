import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';

/// Luko 統一輸入框元件
///
/// 設計特點：
/// - label 靜態置於輸入框上方（非 Material floating label）
/// - focused 時邊框變為 forestGreen
/// - 錯誤狀態（[errorText] 非 null）時邊框與 label 變紅
/// - 支援 helper text、prefix/suffix icon、obscure、多行
///
/// 使用範例：
/// ```dart
/// // 基本用法
/// LukoTextField(
///   label: '顯示名稱',
///   hint: '輸入你的名稱',
///   controller: _nameController,
///   onChanged: (v) => setState(() => _name = v),
/// )
///
/// // 錯誤狀態
/// LukoTextField(
///   label: '手機號碼',
///   errorText: '請輸入正確的手機號碼',
///   keyboardType: TextInputType.phone,
/// )
///
/// // 密碼（obscure）
/// LukoTextField(
///   label: '密碼',
///   obscureText: true,
///   suffixIcon: Icon(Icons.visibility_outlined),
/// )
///
/// // 多行（Bio 輸入）
/// LukoTextField(
///   label: '自我介紹',
///   maxLines: 4,
///   maxLength: 150,
///   helperText: '選填，最多 150 字',
/// )
/// ```
class LukoTextField extends StatelessWidget {
  const LukoTextField({
    super.key,
    this.controller,
    this.focusNode,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// 輸入框上方的靜態 label（必填）
  final String label;

  /// placeholder 文字
  final String? hint;

  /// label 下方的說明文字（與 [errorText] 互斥，errorText 優先）
  final String? helperText;

  /// 錯誤訊息（非 null 時顯示紅色邊框與錯誤文字）
  final String? errorText;

  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool readOnly;

  /// maxLines = 1（單行），> 1（多行），null（不限）
  final int? maxLines;

  /// 最大字數限制（超過後阻止輸入）
  final int? maxLength;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Label ─────────────────────────────────────────────────────
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: hasError ? colors.error : colors.secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // ── TextField ─────────────────────────────────────────────────
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: [
            if (maxLength != null)
              LengthLimitingTextInputFormatter(maxLength),
            ...?inputFormatters,
          ],
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          autofocus: autofocus,
          readOnly: readOnly,
          // obscureText 強制單行；否則使用傳入值
          maxLines: obscureText ? 1 : maxLines,
          enabled: enabled,
          style: textTheme.bodyLarge?.copyWith(
            color: colors.primaryText,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: textTheme.bodyLarge?.copyWith(
              color: colors.secondaryText.withValues(alpha: 0.6),
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            // counterText: '' 隱藏右下角預設字數計數
            // 若需要顯示字數，請自行在外部加自訂 widget
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + AppSpacing.xs, // 12
            ),
            filled: true,
            fillColor: enabled
                ? colors.cardSurface
                : colors.backgroundWarm,

            // 正常狀態邊框
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(
                color: hasError ? colors.error : colors.divider,
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            // 聚焦狀態邊框
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(
                color: hasError ? colors.error : colors.forestGreen,
                width: 1.5,
              ),
            ),
            // 停用狀態邊框
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(
                color: colors.divider.withValues(alpha: 0.5),
              ),
            ),
            // 以下兩個給 Form + validator 用（LukoTextField 目前用 errorText 手動控制）
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(color: colors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(color: colors.error, width: 1.5),
            ),
          ),
        ),

        // ── Helper / Error Text ────────────────────────────────────────
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: textTheme.bodySmall?.copyWith(color: colors.error),
          ),
        ] else if (helperText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            helperText!,
            style: textTheme.bodySmall?.copyWith(color: colors.secondaryText),
          ),
        ],
      ],
    );
  }
}
