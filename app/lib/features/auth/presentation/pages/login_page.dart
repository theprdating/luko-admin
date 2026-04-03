import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../widgets/phone_otp_flow.dart';

/// 登入頁（回訪用戶）
///
/// 路由：/login
/// OTP 驗證成功後不手動導航——
/// Supabase session 建立 → authStateProvider 更新 →
/// appUserStatusProvider 重新計算 → GoRouter redirect 自動導向正確頁面
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PhoneOtpFlow(
      title: l10n.authLoginTitle,
      subtitle: l10n.authLoginSubtitle,
      // onSuccess = null：讓 GoRouter 依狀態自動導向
      // approved  → /discover
      // pending   → /review/pending
      // rejected  → /review/rejected
      onSuccess: null,
      onBack: () => context.go('/welcome'),
      debugSkipRoute: '/dev/state-picker',
    );
  }
}
