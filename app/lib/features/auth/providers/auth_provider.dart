import 'package:flutter/cupertino.dart';
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

    // ── 刪除請求（最高優先級）────────────────────────────────────────
    // 任何狀態下，只要有未取消的刪除申請，一律導向待刪除頁面。
    // 必須在其他狀態判斷之前檢查，避免用戶看到被拒/等待頁而非刪除倒數頁。
    final deletionRow = await supabase
        .from('deletion_requests')
        .select('scheduled_for')
        .eq('user_id', user.id)
        .filter('cancelled_at', 'is', null)
        .maybeSingle();

    if (deletionRow != null) return AppUserStatus.pendingDeletion;

    if (row == null) {
      // ── Beta 封測遷移：偵測白名單，進入精簡申請流程 ──────────────────────
      final email = user.email ?? '';
      if (email.isNotEmpty) {
        try {
          final preapproved = await supabase
              .from('preapproved_emails')
              .select('email')
              .eq('email', email)
              .maybeSingle();
          if (preapproved != null) {
            return AppUserStatus.betaOnboarding;
          }
        } catch (_) {
          // 白名單查詢失敗，繼續正常流程
        }
      }
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

    // ── 手機已綁定：並行拉取條款版本設定 + 用戶 profile ────────────
    final results = await Future.wait([
      supabase
          .from('app_config')
          .select('value')
          .eq('key', 'terms_updated_at')
          .single(),
      supabase
          .from('profiles')
          .select('terms_accepted_at, interests, question_answers')
          .eq('id', user.id)
          .maybeSingle(),
    ]);

    final configRow = results[0] as Map<String, dynamic>;
    final termsUpdatedAt = DateTime.tryParse(configRow['value'] as String);
    // maybeSingle() 回傳 Map<String, dynamic>? — 以 dynamic 接收再手動取值
    final profileRow = results[1] as Map?;

    // ── 個人資料設置：interests 或 question_answers 為空 → 引導填寫 ────
    // 必須兩者都完成才算通過 profile setup：
    //   - interests: 至少 5 項
    //   - question_answers: 至少 1 題
    // 只完成其中一步（例如選完興趣但未回答問題）仍視為未完成。
    final rawInterests = profileRow?['interests'] as List?;
    final rawQuestionAnswers = profileRow?['question_answers'] as List?;
    if (rawInterests == null || rawInterests.isEmpty ||
        rawQuestionAnswers == null || rawQuestionAnswers.isEmpty) {
      return AppUserStatus.profileSetupRequired;
    }

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

/// 封測用戶資料：preapproved_emails（display_name, gender, seeking, bio）
/// ＋ profiles.photo_paths（用戶上次的照片路徑，供 apply 流程預填）
/// null = 非封測用戶或尚未載入
final betaUserDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  ref.watch(authStateProvider);
  final user = ref.read(currentUserProvider);
  debugPrint('[betaUserData] user=${user?.id} email=${user?.email}');
  if (user == null) return null;
  final email = user.email ?? '';
  if (email.isEmpty) {
    debugPrint('[betaUserData] email empty → return null');
    return null;
  }
  try {
    final supabase = ref.read(supabaseProvider);

    final preapproved = await supabase
        .from('preapproved_emails')
        .select('display_name, gender, seeking, bio, source_photo_urls')
        .eq('email', email)
        .maybeSingle();
    debugPrint('[betaUserData] preapproved row=$preapproved');
    if (preapproved == null) return null;

    // source_photo_urls：PR Dating 的 public URLs，供首次 onboarding 顯示鎖定照片用
    final sourcePhotoUrls = (preapproved['source_photo_urls'] as List?)
        ?.cast<String>()
        .toList() ?? const <String>[];

    // 嘗試從 profiles 取得照片路徑：
    //   - profiles 已存在（Edge Function 跑完）→ 用 Luko Storage paths
    //   - profiles 不存在或為空（首次 onboarding）→ fallback 到 source_photo_urls
    List<String> photoPaths = const [];
    try {
      final profileRow = await supabase
          .from('profiles')
          .select('photo_paths')
          .eq('id', user.id)
          .maybeSingle();
      debugPrint('[betaUserData] profiles row=$profileRow');
      final raw = profileRow?['photo_paths'] as List?;
      if (raw != null && raw.isNotEmpty) {
        photoPaths = raw.cast<String>().toList();
      }
    } catch (e) {
      debugPrint('[betaUserData] profiles fetch error: $e');
    }

    // profiles 空 → 用 PR Dating source URLs（首次 onboarding）
    if (photoPaths.isEmpty) {
      photoPaths = sourcePhotoUrls;
      debugPrint('[betaUserData] using source_photo_urls as fallback: ${photoPaths.length} photos');
    }

    final result = {
      ...preapproved,
      'photo_paths': photoPaths,
    };
    debugPrint('[betaUserData] final=$result');
    return result;
  } catch (e, st) {
    debugPrint('[betaUserData] error: $e\n$st');
    return null;
  }
});

/// Beta 用戶送出後暫時讓 /review/pending 顯示的 flag
final betaPendingProvider = StateProvider<bool>((ref) => false);
