import 'package:mixpanel_flutter/mixpanel_flutter.dart';

import 'analytics_events.dart';

/// Mixpanel 初始化 Token
///
/// 替換方式：
///   - 開發：直接改這裡的字串（不要 commit 真實 token）
///   - CI/CD：`flutter build --dart-define=MIXPANEL_TOKEN=xxx`
class _AnalyticsConfig {
  static const String token = String.fromEnvironment(
    'MIXPANEL_TOKEN',
    defaultValue: 'REPLACE_WITH_TOKEN', // TODO: 換成正式 token
  );
}

/// Analytics 服務 — Mixpanel 的薄層封裝
///
/// 使用 `analyticsProvider` 取得實例，不要直接 new AnalyticsService。
///
/// 使用範例：
/// ```dart
/// final analytics = ref.read(analyticsProvider);
/// analytics.screenView('discover');
/// analytics.track(AnalyticsEvents.swipeLike, {'target_user_id': id});
/// ```
class AnalyticsService {
  AnalyticsService._(this._mixpanel);

  final Mixpanel _mixpanel;

  /// 初始化 Mixpanel（在 main() 呼叫，await 後傳入 ProviderScope）
  static Future<AnalyticsService> init() async {
    final mixpanel = await Mixpanel.init(
      _AnalyticsConfig.token,
      optOutTrackingDefault: false,
      trackAutomaticEvents: true, // iOS/Android 自動追蹤 app 生命週期
    );
    mixpanel.setLoggingEnabled(false); // 上線後關閉 log
    return AnalyticsService._(mixpanel);
  }

  // ── Identity ──────────────────────────────────────────────────────────────

  /// 登入後綁定用戶 ID（Supabase user UUID）
  void identify(String userId) => _mixpanel.identify(userId);

  /// 登出後清除 identity（避免跨用戶污染）
  void reset() => _mixpanel.reset();

  /// 設定用戶 Profile 屬性（見 [AnalyticsUserProps]）
  void setUserProperty(String key, dynamic value) =>
      _mixpanel.getPeople().set(key, value);

  void setUserPropertyOnce(String key, dynamic value) =>
      _mixpanel.getPeople().setOnce(key, value);

  // ── Event Tracking ────────────────────────────────────────────────────────

  /// 通用 track（直接使用 [AnalyticsEvents] 常數）
  void track(String event, [Map<String, dynamic>? properties]) =>
      _mixpanel.track(event, properties: properties ?? {});

  // ── Convenience Methods ───────────────────────────────────────────────────

  void screenView(String screenName) =>
      track(AnalyticsEvents.screenView, {'screen': screenName});

  void onboardingSlide(int slide) =>
      track(AnalyticsEvents.onboardingSlideView, {'slide': slide});

  void applyStep(int step, {String? gender}) =>
      track(AnalyticsEvents.applyStepCompleted, {
        'step': step,
        if (gender != null) 'gender': gender,
      });

  void authOtpFailed(String errorType) =>
      track(AnalyticsEvents.authOtpFailed, {'error_type': errorType});
}
