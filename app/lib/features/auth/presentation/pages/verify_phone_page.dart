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
//   1. 用戶選擇國碼、輸入手機號碼
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

// ── 國碼資料（與 phone_otp_flow.dart 共同維護同一份清單邏輯）────────────────────

class _CountryInfo {
  const _CountryInfo({
    required this.flag,
    required this.nameZh,
    required this.code,
    required this.isSupported,
    this.maxDigits = 15,
  });

  final String flag;
  final String nameZh;
  final String code;
  final bool isSupported;
  final int maxDigits;
}

const _kCountries = [
  _CountryInfo(flag: '🇹🇼', nameZh: '台灣',   code: '+886', isSupported: true,  maxDigits: 10),
  _CountryInfo(flag: '🇯🇵', nameZh: '日本',   code: '+81',  isSupported: false, maxDigits: 11),
  _CountryInfo(flag: '🇭🇰', nameZh: '香港',   code: '+852', isSupported: false, maxDigits: 8),
  _CountryInfo(flag: '🇸🇬', nameZh: '新加坡',  code: '+65',  isSupported: false, maxDigits: 8),
  _CountryInfo(flag: '🇰🇷', nameZh: '韓國',   code: '+82',  isSupported: false, maxDigits: 11),
  _CountryInfo(flag: '🇲🇾', nameZh: '馬來西亞', code: '+60',  isSupported: false, maxDigits: 11),
  _CountryInfo(flag: '🇺🇸', nameZh: '美國',   code: '+1',   isSupported: false, maxDigits: 10),
  _CountryInfo(flag: '🇨🇦', nameZh: '加拿大',  code: '+1',   isSupported: false, maxDigits: 10),
  _CountryInfo(flag: '🇦🇺', nameZh: '澳洲',   code: '+61',  isSupported: false, maxDigits: 10),
  _CountryInfo(flag: '🇬🇧', nameZh: '英國',   code: '+44',  isSupported: false, maxDigits: 10),
];

const _kDefaultCountry = _CountryInfo(
  flag: '🇹🇼', nameZh: '台灣', code: '+886', isSupported: true, maxDigits: 10,
);

class VerifyPhonePage extends ConsumerStatefulWidget {
  const VerifyPhonePage({super.key});

  @override
  ConsumerState<VerifyPhonePage> createState() => _VerifyPhonePageState();
}

class _VerifyPhonePageState extends ConsumerState<VerifyPhonePage> {
  _Step _step = _Step.phoneInput;
  bool _isLoading = false;

  _CountryInfo _selectedCountry = _kDefaultCountry;
  String _e164Phone = '';
  String _phoneDisplay = '';
  String? _phoneError;
  String? _otpError;

  final _phoneCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();

  Timer? _resendTimer;
  int _resendSeconds = 0;

  static const int _resendCooldown = 60;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// 將本地號碼正規化為 E.164
  /// 台灣：09XXXXXXXX / 9XXXXXXXX → +886XXXXXXXXX（唯一格式，防重複綁定）
  String _toE164(String localNumber) {
    final digits = localNumber.replaceAll(RegExp(r'\D'), '');
    final stripped = digits.startsWith('0') ? digits.substring(1) : digits;
    return '${_selectedCountry.code}$stripped';
  }

  bool _isValidPhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (_selectedCountry.code == '+886') {
      return (digits.startsWith('09') && digits.length == 10) ||
          (digits.startsWith('9') && digits.length == 9);
    }
    return digits.length >= 7 && digits.length <= 15;
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

  void _showCountryPicker() {
    final colors = Theme.of(context).extension<AppColors>()!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LightCountryPickerSheet(
        colors: colors,
        selectedName: _selectedCountry.nameZh,
        onSelected: (country) {
          setState(() {
            _selectedCountry = country;
            _phoneError = null;
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // ── Step 1：發送 OTP ──────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    final l10n = AppLocalizations.of(context)!;
    final cleaned = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');

    if (!_selectedCountry.isSupported) {
      setState(() => _phoneError = l10n.phoneCountryUnsupported);
      return;
    }

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
        ? '${_selectedCountry.code} ${cleaned.substring(1)}'
        : '${_selectedCountry.code} $cleaned';

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
      // Rate-limit 類（前一個 OTP 仍有效）→ 直接到 OTP 輸入頁
      final isRateLimit = e.message.contains('seconds') ||
          e.message.toLowerCase().contains('rate') ||
          e.message.toLowerCase().contains('limit');
      if (isRateLimit) {
        setState(() {
          _step = _Step.otpVerify;
          _isLoading = false;
        });
        _startResendTimer();
      } else {
        setState(() {
          _isLoading = false;
          _phoneError = e.message;
        });
      }
    } catch (_) {
      // 網路逾時或未知錯誤：Twilio 很可能已送出 SMS，直接導向 OTP 輸入頁
      if (!mounted) return;
      setState(() {
        _step = _Step.otpVerify;
        _isLoading = false;
      });
      _startResendTimer();
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
            type: OtpType.phoneChange, // 綁定到現有帳號，非重新登入
          );

      // 成功：auth.users.phone 已更新
      // authStateProvider 自動 emit → appUserStatusProvider 重算
      // → GoRouter redirect 到 /discover 或 /terms-update
      if (mounted) {
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
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.backgroundWarm,
      body: SafeArea(
        bottom: false,
        // AnimatedSwitcher 讓 phone→OTP 有輕微滑入感
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          ),
          child: _step == _Step.phoneInput
              ? _buildPhoneInput(colors, key: const ValueKey('phone'))
              : _buildOtpVerify(colors, key: const ValueKey('otp')),
        ),
      ),
    );
  }

  // ── Phone Input ───────────────────────────────────────────────────────────

  Widget _buildPhoneInput(AppColors colors, {Key? key}) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final isUnsupported = !_selectedCountry.isSupported;

    return KeyedSubtree(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pagePadding, 24,
                AppSpacing.pagePadding, 16,
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
                      color: colors.primaryText,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.verifyPhoneSubtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: colors.secondaryText,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.verifyPhoneUniqueNote,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: colors.forestGreen,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // ── 標籤 ──────────────────────────────────────────────────
                  Text(
                    l10n.authPhoneLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.secondaryText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── 國碼選擇 + 手機號輸入 ─────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LightCountryButton(
                        country: _selectedCountry,
                        onTap: _showCountryPicker,
                        colors: colors,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(
                                _selectedCountry.maxDigits),
                          ],
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            color: colors.primaryText,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.authPhoneHint,
                            hintStyle: GoogleFonts.dmSans(
                              color: colors.secondaryText.withValues(alpha: 0.6),
                            ),
                            errorText: _phoneError,
                            filled: true,
                            fillColor: colors.cardSurface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.input),
                              borderSide: BorderSide(color: colors.divider),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.input),
                              borderSide: BorderSide(color: colors.divider),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.input),
                              borderSide: BorderSide(
                                  color: colors.forestGreen, width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.input),
                              borderSide:
                                  BorderSide(color: colors.error, width: 1.5),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.input),
                              borderSide:
                                  BorderSide(color: colors.error, width: 1.5),
                            ),
                          ),
                          onSubmitted: (_) => _sendOtp(),
                        ),
                      ),
                    ],
                  ),

                  // ── 未支援國碼提示 ────────────────────────────────────────
                  if (isUnsupported) ...[
                    const SizedBox(height: 10),
                    _LightUnsupportedBanner(
                      message: AppLocalizations.of(context)!.phoneCountryUnsupported,
                      colors: colors,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── 固定底部按鈕 ───────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.pagePadding, 8,
              AppSpacing.pagePadding, bottom + 24,
            ),
            child: _PrimaryButton(
              label: l10n.authSendCode,
              isLoading: _isLoading,
              enabled: !isUnsupported,
              onTap: _sendOtp,
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }

  // ── OTP Verify ────────────────────────────────────────────────────────────

  Widget _buildOtpVerify(AppColors colors, {Key? key}) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return KeyedSubtree(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pagePadding, 24,
                AppSpacing.pagePadding, 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back arrow
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _step = _Step.phoneInput;
                        _otpCtrl.clear();
                        _otpError = null;
                        _resendTimer?.cancel();
                      }),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: colors.secondaryText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.authOtpTitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: colors.primaryText,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.authOtpSentTo(_phoneDisplay),
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: colors.secondaryText,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    autofocus: true,
                    style: GoogleFonts.dmSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: colors.primaryText,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      errorText: _otpError,
                      filled: true,
                      fillColor: colors.cardSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.input),
                        borderSide: BorderSide(color: colors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.input),
                        borderSide: BorderSide(color: colors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.input),
                        borderSide:
                            BorderSide(color: colors.forestGreen, width: 1.5),
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
                              color: colors.secondaryText,
                            ),
                          )
                        : GestureDetector(
                            onTap: _isLoading ? null : _sendOtp,
                            child: Text(
                              l10n.authOtpResend,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: colors.forestGreen,
                                decoration: TextDecoration.underline,
                                decorationColor: colors.forestGreen,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // ── 固定底部按鈕 ─────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.pagePadding, 8,
              AppSpacing.pagePadding, bottom + 24,
            ),
            child: _PrimaryButton(
              label: l10n.authOtpVerify,
              isLoading: _isLoading,
              onTap: () => _verifyOtp(_otpCtrl.text),
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 淺色主題：國碼選擇按鈕
// ─────────────────────────────────────────────────────────────────────────────

class _LightCountryButton extends StatelessWidget {
  const _LightCountryButton({
    required this.country,
    required this.onTap,
    required this.colors,
  });

  final _CountryInfo country;
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56, // 與旁邊 TextField 高度一致
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(
            color: country.isSupported
                ? colors.divider
                : colors.warning.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(country.flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              country.code,
              style: GoogleFonts.dmSans(
                color: colors.primaryText,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: colors.secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 淺色主題：未支援國碼提示條
// ─────────────────────────────────────────────────────────────────────────────

class _LightUnsupportedBanner extends StatelessWidget {
  const _LightUnsupportedBanner({required this.message, required this.colors});
  final String message;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 15, color: colors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: colors.warning,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 淺色主題：國碼選擇底部表單
// ─────────────────────────────────────────────────────────────────────────────

class _LightCountryPickerSheet extends StatelessWidget {
  const _LightCountryPickerSheet({
    required this.colors,
    required this.selectedName,
    required this.onSelected,
  });

  final AppColors colors;
  final String selectedName;
  final ValueChanged<_CountryInfo> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖曳把手
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // 標題
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  '選擇國碼',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.primaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 國家清單
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _kCountries.length,
            itemBuilder: (_, i) {
              final c = _kCountries[i];
              final isSelected = c.nameZh == selectedName;
              return _LightCountryTile(
                country: c,
                isSelected: isSelected,
                colors: colors,
                onTap: () => onSelected(c),
              );
            },
          ),

          SizedBox(height: bottomPadding + 16),
        ],
      ),
    );
  }
}

class _LightCountryTile extends StatelessWidget {
  const _LightCountryTile({
    required this.country,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  final _CountryInfo country;
  final bool isSelected;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: country.isSupported ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Text(country.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                country.nameZh,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: country.isSupported
                      ? colors.primaryText
                      : colors.secondaryText,
                ),
              ),
            ),
            Text(
              country.code,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: colors.secondaryText,
              ),
            ),
            const SizedBox(width: 12),
            if (isSelected)
              Icon(Icons.check_rounded, size: 18, color: colors.forestGreen)
            else if (!country.isSupported)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '即將開放',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: colors.warning,
                  ),
                ),
              )
            else
              const SizedBox(width: 18),
          ],
        ),
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
    this.enabled = true,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  final AppColors colors;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isActive = enabled && !isLoading;

    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive
              ? colors.forestGreen
              : colors.forestGreen.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.brandOnDark,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.brandOnDark,
                ),
              ),
      ),
    );
  }
}
