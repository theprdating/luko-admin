import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 全域 Supabase client
///
/// 在任何 Widget / Provider 中取用：
/// ```dart
/// final supabase = ref.read(supabaseProvider);
/// await supabase.from('profiles').select();
/// ```
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Auth 狀態 Stream
///
/// 每次登入 / 登出 / Token 更新時都會 emit 新的 [AuthState]。
/// GoRouter 的 refreshListenable 透過這個 stream 觸發路由重新計算。
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// 當前登入用戶（可為 null）
///
/// - Stream 還在載入中：回傳同步的 currentUser（避免閃白畫面）
/// - 已收到 stream data：回傳 session user
/// - 未登入：回傳 null
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).when(
    data: (state) => state.session?.user,
    // stream 尚未 emit 第一個值前，先回傳同步的 currentUser
    loading: () => Supabase.instance.client.auth.currentUser,
    error: (_, __) => null,
  );
});
