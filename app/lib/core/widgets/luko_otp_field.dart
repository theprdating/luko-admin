import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_radius.dart';
import '../theme/app_colors.dart';

/// 6 格 OTP 輸入元件
///
/// 功能：
/// - 自動移焦：輸入一位後自動跳到下一格
/// - 退格移焦：當前格為空時按 Backspace，自動跳回上一格
/// - 貼上支援：貼入 6 位數字時自動填滿所有格
/// - 6 格全填後自動觸發 [onCompleted]
///
/// 使用範例：
/// ```dart
/// LukoOtpField(
///   onCompleted: (code) => _verify(code),
/// )
/// ```
class LukoOtpField extends StatefulWidget {
  const LukoOtpField({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.autoFocus = true,
    this.enabled = true,
  });

  final int length;

  /// 6 格全部填完後觸發，帶入完整 OTP 字串
  final ValueChanged<String>? onCompleted;

  /// 任意格內容改變時觸發
  final ValueChanged<String>? onChanged;

  /// 是否在 widget 建立時自動對第一格聚焦
  final bool autoFocus;

  final bool enabled;

  @override
  State<LukoOtpField> createState() => LukoOtpFieldState();
}

class LukoOtpFieldState extends State<LukoOtpField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (i) {
      final node = FocusNode();
      // Flutter 3.x：用 onKeyEvent 攔截退格鍵
      node.onKeyEvent = (_, event) => _handleKeyEvent(i, event);
      return node;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  // ── 公開方法 ────────────────────────────────────────────────────────────────

  /// 清空所有格並聚焦第一格（OTP 驗證失敗後呼叫）
  void clear() {
    for (final c in _controllers) { c.clear(); }
    if (widget.autoFocus) _focusNodes.first.requestFocus();
    widget.onChanged?.call('');
  }

  // ── 私有邏輯 ────────────────────────────────────────────────────────────────

  KeyEventResult _handleKeyEvent(int index, KeyEvent event) {
    // 只處理 KeyDown 事件
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      // 當前格已空 + 按退格 → 清上一格並移焦
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      _notify();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onChanged(int index, String value) {
    // ── 貼上整串 OTP（通常 6 位）──────────────────────────────────────
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= widget.length) {
        for (int i = 0; i < widget.length; i++) {
          _controllers[i].text = digits[i];
        }
        _focusNodes.last.requestFocus();
        _notify();
        _checkCompleted();
        return;
      }
    }

    // ── 正常單格輸入 ──────────────────────────────────────────────────
    if (value.isEmpty) {
      // 已透過 _handleKeyEvent 處理退格，這裡只更新通知
      _notify();
      return;
    }

    // 萬一輸入超過 1 字元（快速連打），只保留最後一個
    if (value.length > 1) {
      _controllers[index].text = value[value.length - 1];
      _controllers[index].selection =
          const TextSelection.collapsed(offset: 1);
    }

    // 移焦到下一格
    if (index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus(); // 最後一格填完，收起鍵盤
    }

    _notify();
    _checkCompleted();
  }

  void _notify() {
    final otp = _controllers.map((c) => c.text).join();
    widget.onChanged?.call(otp);
  }

  void _checkCompleted() {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == widget.length) {
      widget.onCompleted?.call(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        widget.length,
        (i) => _OtpBox(
          controller: _controllers[i],
          focusNode: _focusNodes[i],
          colors: colors,
          autofocus: widget.autoFocus && i == 0,
          enabled: widget.enabled,
          onChanged: (v) => _onChanged(i, v),
        ),
      ),
    );
  }
}

// ── 單格 ──────────────────────────────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.colors,
    required this.onChanged,
    this.autofocus = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final AppColors colors;
  final ValueChanged<String> onChanged;
  final bool autofocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 54,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        enabled: enabled,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        onChanged: onChanged,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: colors.primaryText,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          counterText: '', // 隱藏預設字數計數
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: enabled ? colors.cardSurface : colors.backgroundWarm,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colors.forestGreen, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(
              color: colors.divider.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
