import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_service.dart';

/// Analytics Provider
///
/// 此 Provider 必須在 main() 透過 ProviderScope.overrides 初始化：
/// ```dart
/// final analytics = await AnalyticsService.init();
///
/// runApp(ProviderScope(
///   overrides: [analyticsProvider.overrideWithValue(analytics)],
///   child: const LukoApp(),
/// ));
/// ```
///
/// 在 Widget / Provider 中取用：
/// ```dart
/// final analytics = ref.read(analyticsProvider);
/// analytics.screenView('discover');
/// ```
final analyticsProvider = Provider<AnalyticsService>(
  (_) => throw StateError('analyticsProvider not initialized via ProviderScope.overrides'),
);
