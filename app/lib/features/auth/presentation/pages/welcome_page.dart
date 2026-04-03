import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/exit_on_double_back_scope.dart';
import '../../../../l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WelcomePage
//
// 路由：/welcome
//
// 排版：品牌識別置中 + 底部 CTA 按鈕，無多餘文案
//   中央 — Icon + LUKO + 金線 + CURATED DATING
//   底部 — 申請加入（solid）+ 登入（text link）
//
// 動畫（總 1600ms）：
//   Phase 1 [0%–50%]  icon scale + fade
//   Phase 2 [25%–75%] LUKO + 金線展開
//   Phase 3 [55%–90%] CURATED DATING fade
//   Phase 4 [65%–100%] 按鈕淡入
// ─────────────────────────────────────────────────────────────────────────────

class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage>
    with TickerProviderStateMixin {
  // ── 入場 controller ──────────────────────────────────────────────────────
  late final AnimationController _ctrl;

  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  late final Animation<double> _brandFade;
  late final Animation<double> _lineWidth;
  late final Animation<double> _taglineFade;
  late final Animation<double> _btnFade;

  // ── Sign-in state ─────────────────────────────────────────────────────────
  bool _isSigningIn = false;
  String? _signInError;

  // ── 條款連結 recognizer（需 dispose 避免 memory leak）────────────────────
  late final TapGestureRecognizer _termsTap =
      TapGestureRecognizer()..onTap = () => context.push('/terms');
  late final TapGestureRecognizer _privacyTap =
      TapGestureRecognizer()..onTap = () => context.push('/privacy');

  // ── 離場 controller ──────────────────────────────────────────────────────
  late final AnimationController _exitCtrl;

  /// 品牌中央區塊：fade 1→0
  late final Animation<double> _exitFade;

  /// Icon：scale 1→0.82（縮小感）
  late final Animation<double> _exitScale;

  /// 按鈕：比品牌區稍快淡出
  late final Animation<double> _exitBtnFade;

  @override
  void initState() {
    super.initState();

    // ── 入場 ─────────────────────────────────────────────────────────────
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();

    _iconScale = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.00, 0.50, curve: Curves.easeOutCubic),
      ),
    );
    _iconFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.00, 0.44, curve: Curves.easeOut),
    );
    _brandFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 0.75, curve: Curves.easeOut),
    );
    _lineWidth = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.30, 0.78, curve: Curves.easeOut),
    );
    _taglineFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.55, 0.90, curve: Curves.easeOut),
    );
    _btnFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.65, 1.00, curve: Curves.easeOut),
    );

    // ── 離場（600ms，與入場無關）────────────────────────────────────────
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // 品牌整體：0→1 時 opacity 從 1→0（easeIn，加速淡出）
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitCtrl,
        curve: const Interval(0.10, 1.00, curve: Curves.easeIn),
      ),
    );

    // Icon 縮小：與 _exitFade 同步結束（都在 1.00），縮小淡出同時完成
    _exitScale = Tween<double>(begin: 1.0, end: 0.60).animate(
      CurvedAnimation(
        parent: _exitCtrl,
        curve: const Interval(0.10, 1.00, curve: Curves.easeInCubic),
      ),
    );

    // 按鈕：略比品牌快消失
    _exitBtnFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitCtrl,
        curve: const Interval(0.00, 0.70, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _exitCtrl.dispose();
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  // ── OAuth helpers ─────────────────────────────────────────────────────────

  /// Apple nonce：明文用於請求，SHA-256 hash 傳給 Apple（防重放攻擊）
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _signInWithGoogle() async {
    if (_isSigningIn) return;
    setState(() {
      _isSigningIn = true;
      _signInError = null;
    });

    try {
      final googleSignIn = GoogleSignIn(
        // iOS 使用 clientId（來自 GoogleService-Info.plist）
        // --dart-define=GOOGLE_IOS_CLIENT_ID=xxx
        clientId: const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
        // Android / Web 使用 serverClientId（來自 google-services.json）
        // --dart-define=GOOGLE_WEB_CLIENT_ID=xxx
        serverClientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // 用戶取消
        setState(() => _isSigningIn = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      // 成功：authStateProvider 更新 → GoRouter 自動導向
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSigningIn = false;
        _signInError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSigningIn = false;
        _signInError = AppLocalizations.of(context)!.commonError;
      });
    }
  }

  Future<void> _signInWithApple() async {
    if (_isSigningIn) return;
    setState(() {
      _isSigningIn = true;
      _signInError = null;
    });

    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
        nonce: hashedNonce,
      );

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
        nonce: rawNonce,
      );
      // 成功：authStateProvider 更新 → GoRouter 自動導向
    } on SignInWithAppleAuthorizationException catch (e) {
      if (!mounted) return;
      // 用戶取消不顯示錯誤
      if (e.code == AuthorizationErrorCode.canceled) {
        setState(() => _isSigningIn = false);
        return;
      }
      setState(() {
        _isSigningIn = false;
        _signInError = AppLocalizations.of(context)!.commonError;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSigningIn = false;
        _signInError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSigningIn = false;
        _signInError = AppLocalizations.of(context)!.commonError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n      = AppLocalizations.of(context)!;
    final colors    = Theme.of(context).extension<AppColors>()!;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return ExitOnDoubleBackScope(
      child: Scaffold(
        backgroundColor: colors.brandBg,
        body: Stack(
        fit: StackFit.expand,
        children: [

          // ── 主內容 ─────────────────────────────────────────────────────
          // Listenable.merge 讓兩個 controller 都能觸發 rebuild
          AnimatedBuilder(
            animation: Listenable.merge([_ctrl, _exitCtrl]),
            builder: (context, _) {
              // 離場 fade / scale 的當下值
              final exitF  = _exitFade.value;
              final exitS  = _exitScale.value;
              final exitBF = _exitBtnFade.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── 品牌識別（垂直置中）──────────────────────────────
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          // Icon（入場 fade × 離場 fade；scale 相乘）
                          Opacity(
                            opacity: (_iconFade.value * exitF).clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: _iconScale.value * exitS,
                              child: _IconWithGlow(
                                opacity: (_iconFade.value * exitF).clamp(0.0, 1.0),
                                colors: colors,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // LUKO
                          Opacity(
                            opacity: (_brandFade.value * exitF).clamp(0.0, 1.0),
                            child: Text(
                              'LUKO',
                              style: GoogleFonts.dmSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w200,
                                letterSpacing: 11.0,
                                color: colors.brandOnDark,
                                height: 1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // 金線
                          Opacity(
                            opacity: (_brandFade.value * exitF).clamp(0.0, 1.0),
                            child: _ExpandingLine(progress: _lineWidth.value, gold: colors.brandGold),
                          ),

                          const SizedBox(height: 14),

                          // CURATED DATING
                          Opacity(
                            opacity: (_taglineFade.value * exitF).clamp(0.0, 1.0),
                            child: Text(
                              'CURATED  DATING',
                              style: GoogleFonts.dmSans(
                                fontSize: 9.0,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 4.5,
                                color: colors.brandCaption,
                                height: 1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),

                  // ── 底部 CTA ─────────────────────────────────────────
                  Opacity(
                    opacity: (_btnFade.value * exitBF).clamp(0.0, 1.0),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.pagePadding,
                        0,
                        AppSpacing.pagePadding,
                        bottomPad + 36,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          // Google 登入（白底按鈕，符合 Google Branding）
                          _GoogleButton(
                            label: l10n.authContinueWithGoogle,
                            onTap: _isSigningIn ? null : _signInWithGoogle,
                            isLoading: _isSigningIn,
                          ),

                          const SizedBox(height: 12),

                          // Apple 登入（自製按鈕：與 Google 按鈕高度、字型一致，符合 Apple HIG 白底款）
                          _AppleButton(
                            label: l10n.authContinueWithApple,
                            onTap: _isSigningIn ? null : _signInWithApple,
                            isLoading: _isSigningIn,
                          ),

                          if (_signInError != null) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                _signInError!,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: colors.error,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // 同意條款（服務條款 & 隱私權政策 可點擊連結）
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: colors.brandCaption,
                                letterSpacing: 0.1,
                                height: 1.5,
                              ),
                              children: [
                                TextSpan(text: l10n.authConsentPrefix),
                                TextSpan(
                                  text: l10n.termsLabel,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: colors.brandGold,
                                    decoration: TextDecoration.underline,
                                    decorationColor: colors.brandGold
                                        .withValues(alpha: 0.5),
                                  ),
                                  recognizer: _termsTap,
                                ),
                                // authConsentSuffix('') 僅取連結詞（" 與 " / " and "），不含 privacyLabel
                                TextSpan(text: l10n.authConsentSuffix('')),
                                TextSpan(
                                  text: l10n.privacyLabel,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: colors.brandGold,
                                    decoration: TextDecoration.underline,
                                    decorationColor: colors.brandGold
                                        .withValues(alpha: 0.5),
                                  ),
                                  recognizer: _privacyTap,
                                ),
                              ],
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),

                ],
              );
            },
          ),

        ],
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon + 光暈
// ─────────────────────────────────────────────────────────────────────────────

class _IconWithGlow extends StatelessWidget {
  const _IconWithGlow({required this.opacity, required this.colors});
  final double opacity;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.06 * opacity),
            blurRadius: 90,
            spreadRadius: 28,
          ),
          BoxShadow(
            color: colors.forestGreen.withValues(alpha: 0.18 * opacity),
            blurRadius: 50,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/app_icon_white.png',
        height: 160,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox(height: 160),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 金線（從中心展開）
// ─────────────────────────────────────────────────────────────────────────────

class _ExpandingLine extends StatelessWidget {
  const _ExpandingLine({required this.progress, required this.gold});
  final double progress;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    const maxWidth = 44.0;
    return SizedBox(
      width: maxWidth,
      height: 1.0,
      child: ClipRect(
        child: Align(
          alignment: Alignment.center,
          widthFactor: progress,
          child: Container(
            width: maxWidth,
            height: 1.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gold.withValues(alpha: 0.0),
                  gold,
                  gold,
                  gold.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google Sign-In 按鈕
//
// 符合 Google Branding Guidelines（2024）：
//   • 白底 (#FFFFFF) + 1px stroke (#747775)         ← Light theme 規範色
//   • 字型：Roboto Medium 14sp，顏色 #1F1F1F        ← 官方指定字型
//   • 間距：左右 16px padding，logo 與文字間 12px    ← iOS 規範間距
//   • G logo 使用官方 PNG（gstatic CDN 下載）
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleButton extends StatefulWidget {
  const _GoogleButton({
    required this.label,
    required this.onTap,
    required this.isLoading,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.80 : 1.0,
        duration: const Duration(milliseconds: 60),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            // Google Light theme: 1px inset stroke #747775
            border: Border.all(color: const Color(0xFF747775), width: 1),
          ),
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF747775),
                  ),
                )
              : Padding(
                  // iOS 規範：左右 16px，logo 與文字間 12px
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 官方 Google G mark（gstatic CDN 下載，非手繪）
                      Image.asset(
                        'assets/images/google_logo.png',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.label,
                        style: GoogleFonts.roboto(
                          // Google 官方指定：Roboto Medium 14sp，#1F1F1F
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.25,
                          color: const Color(0xFF1F1F1F),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Apple Sign-In 按鈕（自製，與 Google 按鈕幾何完全一致）
//
// 符合 Apple HIG Sign in with Apple 規範：
//   • 白底 + 1px 黑色 border（white with outline 款式）
//   • Apple logo（Material Icons Icons.apple，全平台可用）
//   • 字型：DM Sans Medium 14sp，顏色 #000000
//   • 最小高度 30pt，此處 48 超過推薦 44pt
// ─────────────────────────────────────────────────────────────────────────────

class _AppleButton extends StatefulWidget {
  const _AppleButton({
    required this.label,
    required this.onTap,
    required this.isLoading,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  State<_AppleButton> createState() => _AppleButtonState();
}

class _AppleButtonState extends State<_AppleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.80 : 1.0,
        duration: const Duration(milliseconds: 60),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.apple, size: 22, color: Colors.black),
                      const SizedBox(width: 10),
                      Text(
                        widget.label,
                        // fontFamily 不指定 → iOS: SF Pro，Android: Roboto（平台原生）
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.25,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
