import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared_prefs_provider.dart';

const _kLocaleKey = 'luko.language';

/// App 語言 Provider
///
/// 初始值從 SharedPreferences 讀取；未設定時回傳 null（交給 MaterialApp
/// 的 localeResolutionCallback 決定跟隨裝置語言）。
/// 設定後持久化，下次冷啟動自動套用。
///
/// 使用：
///   ref.read(localeProvider.notifier).setLocale(const Locale('zh', 'TW'))
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final code = prefs.getString(_kLocaleKey);
    if (code == null) return null; // 尚未手動設定，跟隨裝置
    return code == 'zh' ? const Locale('zh', 'TW') : const Locale('en');
  }

  void setLocale(Locale locale) {
    state = locale;
    final code = locale.languageCode; // 'zh' or 'en'
    ref.read(sharedPreferencesProvider).setString(_kLocaleKey, code);
  }
}
