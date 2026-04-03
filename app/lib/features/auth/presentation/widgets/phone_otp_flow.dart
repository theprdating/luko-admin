import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/analytics/analytics_events.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

// ── 步驟狀態 ──────────────────────────────────────────────────────────────────
enum _Step { phoneInput, otpVerify }

/// 手機 OTP 驗證流程（apply + login 共用）
///
/// 使用方式：
/// ```dart
/// // 申請流程
/// PhoneOtpFlow(
///   title: l10n.authPhoneTitle,
///   subtitle: l10n.authPhoneSubtitle,
///   onSuccess: () => context.go('/apply/info'),
///   onBack: () => context.go('/welcome'),
/// )
///
/// // 登入流程
/// PhoneOtpFlow(
///   title: l10n.authLoginTitle,
///   subtitle: l10n.authLoginSubtitle,
///   onSuccess: null,  // GoRouter 自動導向
///   onBack: () => context.go('/welcome'),
/// )
/// ```
class PhoneOtpFlow extends ConsumerStatefulWidget {
  const PhoneOtpFlow({
    super.key,
    required this.title,
    required this.subtitle,
    this.onSuccess,
    this.onBack,
    this.debugSkipRoute,
  });

  final String title;
  final String subtitle;

  /// OTP 驗證成功後的回呼
  /// - `null`：不做任何事（讓 GoRouter redirect 處理）
  /// - 非 null：手動導航
  final VoidCallback? onSuccess;

  /// 返回按鈕 / 硬體 Back 的回呼（通常是 `() => context.go('/welcome')`）
  final VoidCallback? onBack;

  /// Debug 模式才可用：跳過 OTP 直接導向此路由（用於 UI 開發測試）
  final String? debugSkipRoute;

  @override
  ConsumerState<PhoneOtpFlow> createState() => _PhoneOtpFlowState();
}

class _PhoneOtpFlowState extends ConsumerState<PhoneOtpFlow> {
  // ── State ────────────────────────────────────────────────────────────────
  _Step _step = _Step.phoneInput;
  bool _isLoading = false;
  String _phoneDisplay = '';
  String _e164Phone = '';
  String? _phoneError;
  String? _otpError;

  Timer? _resendTimer;
  int _resendSeconds = 0;

  // _DarkOtpFieldState.clear() 用
  final GlobalKey<_DarkOtpFieldState> _otpKey = GlobalKey();

  static const String _countryCode = '+886';
  static const int _resendCooldown = 60;

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  // ── Phone Input Logic ────────────────────────────────────────────────────

  String _toE164(String localNumber) {
    final digits = localNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      return '$_countryCode${digits.substring(1)}';
    }
    return '$_countryCode$digits';
  }

  bool _isValidPhone(String digits) {
    final cleaned = digits.replaceAll(RegExp(r'\D'), '');
    return cleaned.startsWith('09') && cleaned.length == 10 ||
        cleaned.startsWith('9') && cleaned.length == 9;
  }

  Future<void> _sendOtp(String localPhone) async {
    final l10n = AppLocalizations.of(context)!;
    final cleaned = localPhone.replaceAll(RegExp(r'\D'), '');

    if (!_isValidPhone(cleaned)) {
      setState(() => _phoneError = l10n.authPhoneInvalid);
      return;
    }

    setState(() {
      _isLoading = true;
      _phoneError = null;
    });

    _e164Phone = _toE164(cleaned);
    _phoneDisplay = cleaned.startsWith('0')
        ? '+886 ${cleaned.substring(1)}'
        : '+886 $cleaned';

    try {
      await ref.read(supabaseProvider).auth.signInWithOtp(
            phone: _e164Phone,
          );
      ref.read(analyticsProvider).track(AnalyticsEvents.authPhoneSent);
      if (!mounted) return;
      setState(() {
        _step = _Step.otpVerify;
        _isLoading = false;
      });
      _startResendTimer();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _phoneError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _phoneError = AppLocalizations.of(context)!.commonError;
      });
    }
  }

  // ── OTP Verify Logic ─────────────────────────────────────────────────────

  Future<void> _verifyOtp(String code) async {
    if (code.length != 6) return;

    setState(() {
      _isLoading = true;
      _otpError = null;
    });

    try {
      await ref.read(supabaseProvider).auth.verifyOTP(
            phone: _e164Phone,
            token: code,
            type: OtpType.sms,
          );
      if (!mounted) return;
      setState(() => _isLoading = false);
      ref.read(analyticsProvider).track(AnalyticsEvents.authOtpVerified);
      widget.onSuccess?.call();
    } on AuthException catch (e) {
      if (!mounted) return;
      final errorType =
          e.message.toLowerCase().contains('expired') ? 'expired' : 'invalid';
      ref.read(analyticsProvider).authOtpFailed(errorType);
      _otpKey.currentState?.clear();
      setState(() {
        _isLoading = false;
        _otpError = _parseOtpError(e);
      });
    } catch (_) {
      if (!mounted) return;
      _otpKey.currentState?.clear();
      setState(() {
        _isLoading = false;
        _otpError = AppLocalizations.of(context)!.commonError;
      });
    }
  }

  String _parseOtpError(AuthException e) {
    final l10n = AppLocalizations.of(context)!;
    final msg = e.message.toLowerCase();
    if (msg.contains('expired') || msg.contains('过期')) {
      return l10n.authOtpExpired;
    }
    return l10n.authOtpInvalid;
  }

  // ── Resend Timer ─────────────────────────────────────────────────────────

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = _resendCooldown);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  // ── Back ─────────────────────────────────────────────────────────────────

  void _backToPhone() => setState(() {
        _step = _Step.phoneInput;
        _otpError = null;
      });

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_step == _Step.otpVerify) {
          _backToPhone();
        } else {
          widget.onBack?.call();
        }
      },
      child: switch (_step) {
        _Step.phoneInput => _PhoneInputView(
            title: widget.title,
            subtitle: widget.subtitle,
            errorText: _phoneError,
            isLoading: _isLoading,
            onSend: _sendOtp,
            onBack: widget.onBack,
            debugSkipRoute: widget.debugSkipRoute,
          ),
        _Step.otpVerify => _OtpVerifyView(
            otpKey: _otpKey,
            phoneMasked: _phoneDisplay,
            errorText: _otpError,
            isLoading: _isLoading,
            resendSeconds: _resendSeconds,
            onCompleted: _verifyOtp,
            onResend: () {
              _otpKey.currentState?.clear();
              _backToPhone();
            },
            onChangePhone: _backToPhone,
          ),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1：手機號碼輸入（全螢幕深色）
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneInputView extends StatefulWidget {
  const _PhoneInputView({
    required this.title,
    required this.subtitle,
    required this.errorText,
    required this.isLoading,
    required this.onSend,
    this.onBack,
    this.debugSkipRoute,
  });

  final String title;
  final String subtitle;
  final String? errorText;
  final bool isLoading;
  final ValueChanged<String> onSend;
  final VoidCallback? onBack;
  final String? debugSkipRoute;

  @override
  State<_PhoneInputView> createState() => _PhoneInputViewState();
}

class _PhoneInputViewState extends State<_PhoneInputView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: colors.brandBg,
      resizeToAvoidBottomInset: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── 頂部：返回按鈕 + 品牌（固定，不隨鍵盤滾動）─────────────
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.onBack != null)
                  _BackButton(onTap: widget.onBack!, colors: colors),
                const SizedBox(height: 4),
                Center(child: _DarkBrandMini(colors: colors)),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // ── 可捲動主內容 ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 標題
                  Text(
                    widget.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                      color: colors.brandOnDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 副標
                  Text(
                    widget.subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: colors.brandCaption,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── 區碼 + 手機輸入 ───────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DarkCountryBadge(colors: colors),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DarkPhoneField(
                          controller: _controller,
                          hint: l10n.authPhoneHint,
                          errorText: widget.errorText,
                          onSubmitted: (_) =>
                              widget.onSend(_controller.text),
                          colors: colors,
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ),

          // ── 固定底部：CTA + 同意告知（隨鍵盤上推）───────────────────
          AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.fromLTRB(
              28, AppSpacing.sm, 28,
              bottomInset > 0
                  ? bottomInset + AppSpacing.md
                  : bottomPadding + AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DarkCtaButton(
                  label: l10n.authSendCode,
                  onPressed: () => widget.onSend(_controller.text),
                  isLoading: widget.isLoading,
                  colors: colors,
                ),
                const SizedBox(height: 10),
                _ConsentNotice(colors: colors),
                // ── Dev 跳過（僅 debug build）─────────────────────────
                if (widget.debugSkipRoute != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => context.go(widget.debugSkipRoute!),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Center(
                        child: Text(
                          '⚙ Dev: Skip →',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: colors.brandGold.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2：OTP 驗證（全螢幕深色）
// ─────────────────────────────────────────────────────────────────────────────

class _OtpVerifyView extends StatelessWidget {
  const _OtpVerifyView({
    required this.otpKey,
    required this.phoneMasked,
    required this.errorText,
    required this.isLoading,
    required this.resendSeconds,
    required this.onCompleted,
    required this.onResend,
    required this.onChangePhone,
  });

  final GlobalKey<_DarkOtpFieldState> otpKey;
  final String phoneMasked;
  final String? errorText;
  final bool isLoading;
  final int resendSeconds;
  final ValueChanged<String> onCompleted;
  final VoidCallback onResend;
  final VoidCallback onChangePhone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: colors.brandBg,
      resizeToAvoidBottomInset: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── 頂部：返回按鈕 + 品牌 + 手機號 Badge ─────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BackButton(onTap: onChangePhone, colors: colors),
                const SizedBox(height: 4),
                Center(
                  child: _DarkBrandMini(
                    colors: colors,
                    badge: _PhoneBadge(
                      phone: phoneMasked,
                      onTap: onChangePhone,
                      colors: colors,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // ── 可捲動主內容 ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 標題
                  Text(
                    l10n.authOtpTitle,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                      color: colors.brandOnDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 副標
                  Text(
                    l10n.authOtpSentTo(phoneMasked),
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: colors.brandCaption,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── 6 格 OTP（深色樣式）────────────────────────────────
                  _DarkOtpField(
                    key: otpKey,
                    onCompleted: onCompleted,
                    enabled: !isLoading,
                    colors: colors,
                  ),

                  // 錯誤訊息
                  if (errorText != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _DarkErrorBanner(message: errorText!),
                  ],

                  const SizedBox(height: AppSpacing.xxl),

                  // 載入 / 倒數 / 重新發送
                  Center(
                    child: isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.brandGold,
                            ),
                          )
                        : resendSeconds > 0
                            ? Text(
                                l10n.authOtpResendIn(resendSeconds),
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: colors.brandCaption,
                                ),
                              )
                            : GestureDetector(
                                onTap: onResend,
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Text(
                                    l10n.authOtpResend,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: colors.brandGold,
                                      decoration: TextDecoration.underline,
                                      decorationColor:
                                          colors.brandGold.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                              ),
                  ),

                ],
              ),
            ),
          ),

          // ── 底部安全距離 ──────────────────────────────────────────────
          SizedBox(
            height: bottomInset > 0
                ? bottomInset + AppSpacing.md
                : bottomPadding + AppSpacing.md,
          ),

        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 品牌小標頭（compact，用於 Login / Apply 頁頂部）
//
// Icon(56px) + LUKO + 金線 + CURATED DATING
// [badge]：OTP 步驟才傳入手機號 badge，Phone 步驟傳 null
// ─────────────────────────────────────────────────────────────────────────────

class _DarkBrandMini extends StatelessWidget {
  const _DarkBrandMini({required this.colors, this.badge});
  final AppColors colors;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // Icon + 光暈
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.04),
                  blurRadius: 48,
                  spreadRadius: 14,
                ),
                BoxShadow(
                  color: colors.forestGreen.withValues(alpha: 0.12),
                  blurRadius: 28,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/app_icon_white.png',
              height: 56,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(height: 56),
            ),
          ),
          const SizedBox(height: 10),

          // LUKO
          Text(
            'LUKO',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w200,
              letterSpacing: 8.0,
              color: colors.brandOnDark,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          // 金線
          SizedBox(
            width: 32,
            height: 1.0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.brandGold.withValues(alpha: 0.0),
                    colors.brandGold,
                    colors.brandGold,
                    colors.brandGold.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.2, 0.8, 1.0],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // CURATED DATING
          Text(
            'CURATED  DATING',
            style: GoogleFonts.dmSans(
              fontSize: 8.0,
              fontWeight: FontWeight.w400,
              letterSpacing: 4.0,
              color: colors.brandCaption,
              height: 1.0,
            ),
          ),

          // 手機號 Badge（OTP 步驟才顯示）
          if (badge != null) ...[
            const SizedBox(height: 14),
            badge!,
          ],

        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 深色國碼徽章（🇹🇼 +886）
// ─────────────────────────────────────────────────────────────────────────────

class _DarkCountryBadge extends StatelessWidget {
  const _DarkCountryBadge({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🇹🇼', style: TextStyle(fontSize: 16)),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '+886',
            style: GoogleFonts.dmSans(
              color: colors.brandOnDark,
              fontWeight: FontWeight.w500,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 深色手機號輸入框
// ─────────────────────────────────────────────────────────────────────────────

class _DarkPhoneField extends StatelessWidget {
  const _DarkPhoneField({
    required this.controller,
    required this.colors,
    this.hint,
    this.errorText,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final AppColors colors;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;

  static const _kErrorColor = Color(0xFFCF6679);

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(
              color: hasError
                  ? _kErrorColor
                  : Colors.white.withValues(alpha: 0.15),
              width: hasError ? 1.5 : 1.0,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onSubmitted: onSubmitted,
            style: GoogleFonts.dmSans(
              color: colors.brandOnDark,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.dmSans(
                color: colors.brandOnDark.withValues(alpha: 0.28),
                fontSize: 15,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
              counterText: '',
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: _kErrorColor,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 深色 OTP 輸入（複用 LukoOtpField 邏輯，但使用深色樣式）
// ─────────────────────────────────────────────────────────────────────────────

class _DarkOtpField extends StatefulWidget {
  const _DarkOtpField({
    super.key,
    required this.colors,
    this.length = 6,
    this.onCompleted,
    this.enabled = true,
  });

  final AppColors colors;
  final int length;
  final ValueChanged<String>? onCompleted;
  final bool enabled;

  @override
  State<_DarkOtpField> createState() => _DarkOtpFieldState();
}

class _DarkOtpFieldState extends State<_DarkOtpField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers =
        List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (i) {
      final node = FocusNode();
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

  /// OTP 驗證失敗後清空並重新聚焦
  void clear() {
    for (final c in _controllers) { c.clear(); }
    _focusNodes.first.requestFocus();
  }

  KeyEventResult _handleKeyEvent(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onChanged(int index, String value) {
    // 貼上整串 OTP
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= widget.length) {
        for (int i = 0; i < widget.length; i++) {
          _controllers[i].text = digits[i];
        }
        _focusNodes.last.requestFocus();
        _checkCompleted();
        return;
      }
    }

    if (value.isEmpty) return;

    if (value.length > 1) {
      _controllers[index].text = value[value.length - 1];
      _controllers[index].selection =
          const TextSelection.collapsed(offset: 1);
    }

    if (index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
    _checkCompleted();
  }

  void _checkCompleted() {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == widget.length) {
      widget.onCompleted?.call(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        widget.length,
        (i) => _DarkOtpBox(
          controller: _controllers[i],
          focusNode: _focusNodes[i],
          autofocus: i == 0,
          enabled: widget.enabled,
          onChanged: (v) => _onChanged(i, v),
          colors: widget.colors,
        ),
      ),
    );
  }
}

// ── 單格 OTP box（深色）────────────────────────────────────────────────────────

class _DarkOtpBox extends StatelessWidget {
  const _DarkOtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.colors,
    this.autofocus = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final AppColors colors;
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
        style: GoogleFonts.dmSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colors.brandOnDark,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.07),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(
              color: colors.brandGold,
              width: 1.5,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 深色背景 CTA 按鈕（近白色背景 + 深色文字，與 WelcomePage 同設計語彙）
// ─────────────────────────────────────────────────────────────────────────────

class _DarkCtaButton extends StatelessWidget {
  const _DarkCtaButton({
    required this.label,
    required this.onPressed,
    required this.colors,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppColors colors;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null && !isLoading;

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDisabled
              ? colors.brandButtonBg.withValues(alpha: 0.45)
              : colors.brandButtonBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.brandBg,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: colors.brandBg,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 手機號 Badge（OTP 步驟，顯示在品牌區下方）
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneBadge extends StatelessWidget {
  const _PhoneBadge({required this.phone, required this.onTap, required this.colors});
  final String phone;
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              phone,
              style: const TextStyle(
                color: Color(0xE6FFFFFF),
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 1,
              height: 12,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(width: 10),
            Text(
              '更改',
              style: TextStyle(
                color: colors.brandGold,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 深色背景錯誤橫幅
// ─────────────────────────────────────────────────────────────────────────────

class _DarkErrorBanner extends StatelessWidget {
  const _DarkErrorBanner({required this.message});
  final String message;

  static const _kErrorColor = Color(0xFFCF6679);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _kErrorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _kErrorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: _kErrorColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: _kErrorColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OTP 前的隱式同意告知（「繼續即代表您同意…」）
// ─────────────────────────────────────────────────────────────────────────────

class _ConsentNotice extends StatefulWidget {
  const _ConsentNotice({required this.colors});
  final AppColors colors;

  @override
  State<_ConsentNotice> createState() => _ConsentNoticeState();
}

class _ConsentNoticeState extends State<_ConsentNotice> {
  late final TapGestureRecognizer _termsTap =
      TapGestureRecognizer()..onTap = () => context.push('/terms');
  late final TapGestureRecognizer _privacyTap =
      TapGestureRecognizer()..onTap = () => context.push('/privacy');

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = widget.colors;

    final linkStyle = TextStyle(
      color: colors.brandGold,
      decoration: TextDecoration.underline,
      decorationColor: colors.brandGold.withValues(alpha: 0.5),
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.dmSans(
          fontSize: 11,
          color: colors.brandCaption,
          height: 1.5,
        ),
        children: [
          TextSpan(text: l10n.authConsentPrefix),
          TextSpan(
            text: l10n.termsLabel,
            recognizer: _termsTap,
            style: linkStyle,
          ),
          TextSpan(text: l10n.termsAgreeAnd),
          TextSpan(
            text: l10n.privacyLabel,
            recognizer: _privacyTap,
            style: linkStyle,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 返回箭頭按鈕（深色背景左上角）
// ─────────────────────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap, required this.colors});
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4, right: 20),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: colors.brandOnDark.withValues(alpha: 0.6),
          size: 20,
        ),
      ),
    );
  }
}
