/// Supabase 連線設定
///
/// 取得位置：Supabase Dashboard → Project Settings → API
///
/// ⚠️  不要把真實 key 直接寫在這裡並提交到 git！
///     請用 --dart-define 在 build 時注入，例如：
///
///     flutter run \
///       --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///       --dart-define=SUPABASE_ANON_KEY=eyJhbGci...
///
///     或在 VS Code launch.json / Android Studio Run Configuration 設定。
class SupabaseConfig {
  SupabaseConfig._();

  /// Supabase 專案 URL
  /// 例：https://abcdefghijklmn.supabase.co
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT_REF.supabase.co',
  );

  /// Anon / Public Key（可寫在 client 端，受 RLS 保護）
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_ANON_KEY',
  );
}
