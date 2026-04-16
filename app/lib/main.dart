import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/analytics/analytics_provider.dart';
import 'core/analytics/analytics_service.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/shared_prefs_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/fcm_service.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase 初始化（FCM 必須在 Supabase 之前或同步完成）─────────────────
  await Firebase.initializeApp();

  // ── Supabase 初始化 ────────────────────────────────────────────────────────
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    debug: kDebugMode,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,  // 加這行
    ),
  );


  // ── FCM 初始化（Supabase 之後，確保 auth.currentUser 可讀）──────────────
  await FcmService.init();

  // 登入後重新嘗試儲存 token（例如：冷啟動時尚未登入，登入後補存）
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.signedIn) {
      FcmService.init();
    }
  });

  // ── SharedPreferences 初始化 ───────────────────────────────────────────────
  // runApp 前完成，讓 onboardingSeenProvider 可同步讀取，避免初始路由閃爍
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('luko.onboarding_shown', false); // TODO: 測試用，記得移除

  // ── Mixpanel 初始化 ────────────────────────────────────────────────────────
  // await 確保 analytics 在 runApp 前就緒，整個 App 生命週期內不會 null
  final analytics = await AnalyticsService.init();

  // ── 系統 UI 設定 ───────────────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 預設：狀態列白色圖示（深綠背景頁面用）
  // 淺色主 App 頁面由 ShellScaffold 的 AnnotatedRegion 覆蓋為深色圖示
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,         // Android：深色背景 → 白色圖示
      statusBarBrightness: Brightness.dark,              // iOS：深色背景 → 白色圖示
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Android：讓 App 延伸到導航列後方（搭配 SafeArea 使用）
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    // ProviderScope 是 Riverpod 的根節點，所有 Provider 都在此範圍內
    // overrides 注入已初始化的 analytics 單例，避免任何頁面出現 StateError
    ProviderScope(
      overrides: [
        analyticsProvider.overrideWithValue(analytics),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const LukoApp(),
    ),
  );
}

class LukoApp extends ConsumerWidget {
  const LukoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FCM 審核結果通知 → 刷新 App 狀態機，觸發 router redirect
    FcmService.setStatusChangeCallback(() => ref.invalidate(appUserStatusProvider));

    // FCM 換照審核結果 → 刷新個人資料照片
    FcmService.setPhotoChangeCallback(() {
      ref.invalidate(myProfileProvider);
      ref.invalidate(myProfilePhotoUrlsProvider);
      ref.invalidate(myProfilePhotoThumbnailUrlsProvider);
      ref.invalidate(myProfilePhotoPendingProvider);
    });

    final router = ref.watch(routerProvider);
    // null = 尚未手動設定，由 localeResolutionCallback 跟隨裝置語言
    final savedLocale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'PR Dating',
      debugShowCheckedModeBanner: false,

      // ── Theme ────────────────────────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // ── Router ───────────────────────────────────────────────────────
      routerConfig: router,

      // ── i18n / l10n ──────────────────────────────────────────────────
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'TW'),
        Locale('en'),
      ],
      // 已手動設定語言：直接使用。未設定（null）：跟隨裝置語言。
      locale: savedLocale,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('en');
        if (locale.languageCode == 'zh') return const Locale('zh', 'TW');
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) return supported;
        }
        return const Locale('en');
      },
    );
  }
}
