import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// 探索頁 — 卡片滑動配對
///
/// 路由：/discover（ShellRoute tab 0）
/// TODO: 實作卡片堆疊、右滑 Like / 左滑 Pass、預載 Queue
class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: colors.backgroundWarm,
        elevation: 0,
        title: Text(
          l10n.appName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colors.forestGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: const SafeArea(
        child: _MidnightRefreshEmptyState(),
      ),
    );
  }
}

/// 每日台灣時間凌晨 12:00 刷新的等待空狀態，含倒數計時器。
///
/// 時間計算：
///   - 台灣固定 UTC+8，無夏令時間。
///   - 台灣凌晨 12:00 = UTC 16:00（前一天）。
///   - [_nextTaiwanMidnightLocal] 回傳的是「下一個台灣凌晨 12:00」換算成
///     裝置系統時區後的 DateTime，純粹是裝置端計算，無 DB / 網路呼叫。
class _MidnightRefreshEmptyState extends StatefulWidget {
  const _MidnightRefreshEmptyState();

  @override
  State<_MidnightRefreshEmptyState> createState() =>
      _MidnightRefreshEmptyStateState();
}

class _MidnightRefreshEmptyStateState
    extends State<_MidnightRefreshEmptyState> {
  late Timer _timer;
  late DateTime _nextRefreshLocal; // 下次刷新時間（裝置時區）
  Duration _remaining = Duration.zero;

  /// 計算下一個台灣凌晨 12:00，以裝置本地時間表示。
  ///
  /// 台灣凌晨 12:00 UTC+8 = UTC 16:00。
  /// 先在 UTC 空間找到下一個 16:00，再 .toLocal() 轉成裝置時區。
  static DateTime _nextTaiwanMidnightLocal() {
    final utcNow = DateTime.now().toUtc();
    // 今天 UTC 16:00
    var target = DateTime.utc(utcNow.year, utcNow.month, utcNow.day, 16);
    // 若已過今天的 UTC 16:00，改用明天
    if (!utcNow.isBefore(target)) {
      target = target.add(const Duration(days: 1));
    }
    return target.toLocal();
  }

  /// 把時間格式化為 HH:mm，例如 "05:00"、"16:00"
  static String _formatHHmm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// 把剩餘 Duration 格式化為倒數顯示，例如 "07:42:15"
  static String _formatCountdown(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void initState() {
    super.initState();
    _nextRefreshLocal = _nextTaiwanMidnightLocal();
    _remaining = _nextRefreshLocal.difference(DateTime.now());

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = _nextTaiwanMidnightLocal();
      setState(() {
        _nextRefreshLocal = next;
        _remaining = next.difference(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    final localTimeStr = _formatHHmm(_nextRefreshLocal);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.forestGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.access_time_rounded,
                size: 40,
                color: colors.forestGreen,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              l10n.discoverMidnightTitle,
              style: textTheme.titleLarge?.copyWith(
                color: colors.primaryText,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle — includes local equivalent time
            Text(
              l10n.discoverMidnightSubtitle(localTimeStr),
              style: textTheme.bodyMedium?.copyWith(
                color: colors.secondaryText,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),

            // Countdown card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              decoration: BoxDecoration(
                color: colors.forestGreen.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.forestGreen.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.discoverMidnightCountdownLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.secondaryText,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCountdown(_remaining),
                    style: textTheme.displaySmall?.copyWith(
                      color: colors.forestGreen,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
