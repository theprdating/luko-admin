import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../domain/app_user_status.dart';

/// 當前用戶的完整 App 狀態
///
/// 此 Provider 會在以下情況自動重新計算：
///   - Auth session 變化（登入 / 登出）
///   - 任何地方呼叫 ref.invalidate(appUserStatusProvider)
///     （例如：申請送出後、審核結果更新後、條款接受後）
///
/// 狀態計算順序：
///   1. 無 session → unauthenticated
///   2. 有 session，無 applications 記錄 → onboarding
///   3. applications.status = rejected → rejected
///   4. applications.status = pending → pending
///   5. applications.status = approved → 比對條款版本
///      5a. terms 過期 → termsRequired
///      5b. terms 最新 → approved
final appUserStatusProvider = FutureProvider<AppUserStatus>((ref) async {
  // 監聽 Auth stream：登入 / 登出時自動重算
  ref.watch(authStateProvider);

  final user = ref.read(currentUserProvider);

  // ── 未登入 ──────────────────────────────────────────────────────────
  if (user == null) return AppUserStatus.unauthenticated;

  // ── 已登入：查詢 applications 資料表確認申請狀態 ─────────────────────
  try {
    final supabase = ref.read(supabaseProvider);

    final row = await supabase
        .from('applications')
        .select('status')
        .eq('user_id', user.id)
        .maybeSingle();

    if (row == null) {
      // 已完成 OTP 驗證，但尚未提交申請（申請流程進行中）
      return AppUserStatus.onboarding;
    }

    final status = row['status'] as String;

    // ── 非 approved 狀態直接返回 ────────────────────────────────────
    if (status != 'approved') {
      return switch (status) {
        'rejected' => AppUserStatus.rejected,
        _          => AppUserStatus.pending,
      };
    }

    // ── approved：先確認手機是否已綁定 ──────────────────────────────
    // 手機在 auth.users.phone 記錄，OAuth 登入後初始為 null
    // 需在 /verify/phone 完成 updateUser + verifyOTP(phoneChange) 後才有值
    if (user.phone == null || user.phone!.isEmpty) {
      return AppUserStatus.phoneVerificationRequired;
    }

    // ── 手機已綁定：並行拉取條款版本設定 + 用戶已接受版本 ────────────
    final results = await Future.wait([
      supabase
          .from('app_config')
          .select('value')
          .eq('key', 'terms_updated_at')
          .single(),
      supabase
          .from('profiles')
          .select('terms_accepted_at')
          .eq('id', user.id)
          .maybeSingle(),
    ]);

    final configRow = results[0] as Map<String, dynamic>;
    final termsUpdatedAt = DateTime.tryParse(configRow['value'] as String);
    // maybeSingle() 回傳 Map<String, dynamic>? — 以 dynamic 接收再手動取值
    final profileRow = results[1];
    final acceptedRaw = profileRow?['terms_accepted_at'] as String?;
    final termsAcceptedAt =
        acceptedRaw != null ? DateTime.tryParse(acceptedRaw) : null;

    // 條款版本有效 && 用戶接受時間晚於條款更新時間 → 正常進入
    if (termsUpdatedAt != null &&
        termsAcceptedAt != null &&
        !termsAcceptedAt.isBefore(termsUpdatedAt)) {
      return AppUserStatus.approved;
    }

    // 條款未接受 or 版本過舊 → 強制重新接受
    return AppUserStatus.termsRequired;
  } catch (_) {
    // DB 查詢失敗時（網路問題、冷啟動延遲），視為 onboarding 讓用戶重試
    return AppUserStatus.onboarding;
  }
});
