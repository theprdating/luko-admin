import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// main() 初始化後注入，整個 app 同步可用
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('SharedPreferences not initialized'),
);

/// onboarding 是否已看過（同步讀取，不會有 loading 狀態）
final onboardingSeenProvider = Provider<bool>((ref) {
  return ref.read(sharedPreferencesProvider).getBool('luko.onboarding_shown') ?? false;
});
