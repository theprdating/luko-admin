import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../widgets/phone_otp_flow.dart';

/// 申請 Step 1 — 手機號碼驗證
///
/// 路由：/apply/phone
/// OTP 驗證成功 → 導向 /apply/info
class ApplyPhonePage extends StatelessWidget {
  const ApplyPhonePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PhoneOtpFlow(
      title: l10n.authPhoneTitle,
      subtitle: l10n.authPhoneSubtitle,
      // 驗證成功後手動導向申請流程下一步
      // GoRouter redirect 不介入（status = onboarding，/apply/* 路徑允許）
      onSuccess: () => context.go('/apply/info'),
      onBack: () => context.go('/welcome'),
      debugSkipRoute: '/dev/apply-info',
    );
  }
}
