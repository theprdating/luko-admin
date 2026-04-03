import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VerifyPhonePage
//
// 路由：/verify/phone
// 狀態：phoneVerificationRequired（審核通過，手機尚未綁定）
//
// 流程：
//   1. 用戶輸入手機號碼
//   2. 呼叫 supabase.auth.updateUser(phone:) → Supabase 發送 OTP
//   3. 用戶輸入 6 位驗證碼
//   4. 呼叫 supabase.auth.verifyOTP(type: OtpType.phoneChange)
//   5. 成功 → auth.users.phone 更新 → authStateProvider 更新
//      → appUserStatusProvider 重算 → GoRouter 自動導向 /discover
//
// ⚠️ 與 PhoneOtpFlow 不同：
//   - PhoneOtpFlow 用 signInWithOtp（建立新 session）
//   - 這裡用 updateUser + OtpType.phoneChange（綁定到現有 OAuth session）
// ─────────────────────────────────────────────────────────────────────────────

enum _Step { phoneInput, otpVerify }

class VerifyPhonePage extends ConsumerStatefulWidget {
  const VerifyPhonePage({super.key});

  @override
  ConsumerState<VerifyPhonePage> createState() => _VerifyPhonePageState();
}

class _VerifyPhonePageState extends ConsumerState<VerifyPhonePage> {
  _Step _step = _Step.phoneInput;
  bool _isLoading = false;

  String _e164Phone = '';
  String _phoneDisplay = '';
  String? _phoneError;
  String? _otpError;

  final _phoneCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();

  Timer? _resendTimer;
  int _resendSeconds = 0;

  static const String _countryCode = '+886';
  static const int _resendCooldown = 60;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _toE164(String localNumber) {
    final digits = localNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) return '$_countryCode${digits.substring(1)}';
    return '$_countryCode$digits';
  }

  bool _isValidPhone(String digits) {
    final cleaned = digits.replaceAll(RegExp(r'\D'), '');
    return (cleaned.startsWith('09') && cleaned.length == 10) ||
        (cleaned.startsWith('9') && cleaned.length == 9);
  }

  void _startResendTimer() {
    _resendSeconds = _resendCooldown;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) t.cancel();
      });
    });
  }

  // ── Step 1：發送 OTP ──────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    final l10n = AppLocalizations.of(context)!;
    final cleaned = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');

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
      // updateUser(phone:) 會發送 OTP 到指定號碼，並準備 phoneChange 驗證
      await ref.read(supabaseProvider).auth.updateUser(
            UserAttributes(phone: _e164Phone),
          );

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

  // ── Step 2：驗證 OTP ──────────────────────────────────────────────────────

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
            type: OtpType.phoneChange,  // 綁定到現有帳號，非重新登入
          );

      // 成功：auth.users.phone 已更新
      // authStateProvider 自動 emit → appUserStatusProvider 重算
      // → GoRouter redirect 到 /discover 或 /terms-update
      if (mounted) {
        // 主動 invalidate 確保即時重算
        ref.invalidate(appUserStatusProvider);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isLoading = false;
        _otpError = e.message.contains('expired')
            ? l10n.authOtpExpired
            : l10n.authOtpInvalid;
        _otpCtrl.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _otpError = AppLocalizations.of(context)!.commonError;
        _otpCtrl.clear();
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: colors.brandBg,
      body: SafeArea(
        bottom: false,
        child: _step == _Step.phoneInput
            ? _buildPhoneInput(l10n, colors, bottom)
            : _buildOtpVerify(l10n, colors, bottom),
      ),
    );
  }

  // ── Phone Input ───────────────────────────────────────────────────────────

  Widget _buildPhoneInput(AppLocalizations l10n, AppColors colors, double bottom) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        24,
        AppSpacing.pagePadding,
        bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            l10n.verifyPhoneTitle,
            style: GoogleFonts.dmSans(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: colors.brandOnDark,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.verifyPhoneSubtitle,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: colors.brandOnDark.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.verifyPhoneUniqueNote,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: colors.brandGold.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            l10n.authPhoneLabel,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.brandOnDark.withValues(alpha: 0.5),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.dmSans(
              fontSize: 18,
              color: colors.brandOnDark,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: l10n.authPhoneHint,
              hintStyle: GoogleFonts.dmSans(
                color: colors.brandOnDark.withValues(alpha: 0.25),
              ),
              prefixText: '+886  ',
              prefixStyle: GoogleFonts.dmSans(
                fontSize: 18,
                color: colors.brandOnDark.withValues(alpha: 0.5),
              ),
              errorText: _phoneError,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide(color: colors.brandGold),
              ),
            ),
            onSubmitted: (_) => _sendOtp(),
          ),
          const Spacer(),
          _PrimaryButton(
            label: l10n.authSendCode,
            isLoading: _isLoading,
            onTap: _sendOtp,
            colors: colors,
          ),
          SizedBox(height: bottom + 8),
        ],
      ),
    );
  }

  // ── OTP Verify ────────────────────────────────────────────────────────────

  Widget _buildOtpVerify(AppLocalizations l10n, AppColors colors, double bottom) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        24,
        AppSpacing.pagePadding,
        bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back arrow
          GestureDetector(
            onTap: () => setState(() {
              _step = _Step.phoneInput;
              _otpCtrl.clear();
              _otpError = null;
              _resendTimer?.cancel();
            }),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: colors.brandOnDark.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.authOtpTitle,
            style: GoogleFonts.dmSans(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: colors.brandOnDark,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.authOtpSentTo(_phoneDisplay),
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: colors.brandOnDark.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: colors.brandOnDark,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              counterText: '',
              errorText: _otpError,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide(color: colors.brandGold),
              ),
            ),
            onChanged: (val) {
              if (val.length == 6) _verifyOtp(val);
            },
          ),
          const SizedBox(height: 20),

          // Resend
          Center(
            child: _resendSeconds > 0
                ? Text(
                    l10n.authOtpResendIn(_resendSeconds),
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: colors.brandOnDark.withValues(alpha: 0.4),
                    ),
                  )
                : GestureDetector(
                    onTap: _isLoading ? null : _sendOtp,
                    child: Text(
                      l10n.authOtpResend,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: colors.brandGold,
                        decoration: TextDecoration.underline,
                        decorationColor: colors.brandGold,
                      ),
                    ),
                  ),
          ),

          const Spacer(),
          _PrimaryButton(
            label: l10n.authOtpVerify,
            isLoading: _isLoading,
            onTap: () => _verifyOtp(_otpCtrl.text),
            colors: colors,
          ),
          SizedBox(height: bottom + 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Primary 按鈕
// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.brandButtonBg,
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
                  color: colors.brandBg,
                ),
              ),
      ),
    );
  }
}
