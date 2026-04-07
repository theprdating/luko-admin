import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 完整登出：清除所有 OAuth provider session + Supabase session
///
/// 確保下次登入時：
/// - Google 用戶會看到帳號選擇器（而非自動重新登入）
/// - Apple 用戶需重新通過 Face ID / Touch ID
///
/// 在所有登出入口（設定頁、條款拒絕、申請流程放棄）統一使用此函式。
Future<void> signOutAll() async {
  // Google Sign-In SDK 本機 session 清除
  // signOut() 清除 cached credentials；下次 signIn() 強制顯示帳號選擇器
  // disconnect() 會完全撤銷授權，此處選用 signOut() 保留帳號關聯但要求重選
  try {
    await GoogleSignIn().signOut();
  } catch (_) {
    // 非 Google 登入用戶，或 SDK 尚未初始化時忽略
  }

  // Supabase session 清除（涵蓋 Apple OAuth token 與所有 JWT）
  await Supabase.instance.client.auth.signOut();
}
