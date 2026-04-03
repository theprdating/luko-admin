import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

/// 主 App 外殼 — 提供底部導覽列
///
/// 使用 GoRouter 的 StatefulShellRoute.indexedStack，
/// 確保切換 Tab 時各頁面的 State（scroll position、資料）都被保留。
///
/// 雙擊返回退出：第一次顯示 SnackBar 提示，2 秒內再按一次才真正退出。
class ShellScaffold extends StatefulWidget {
  const ShellScaffold({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<ShellScaffold> {
  /// Tab 索引對應的路由
  static const _tabs = [
    _TabItem(icon: Icons.explore_outlined,     activeIcon: Icons.explore,        label: '探索',  route: '/discover'),
    _TabItem(icon: Icons.favorite_border,      activeIcon: Icons.favorite,       label: '配對',  route: '/matches'),
    _TabItem(icon: Icons.chat_bubble_outline,  activeIcon: Icons.chat_bubble,    label: '訊息',  route: '/messages'),
    _TabItem(icon: Icons.person_outline,       activeIcon: Icons.person,         label: '我的',  route: '/me'),
  ];

  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final currentIndex = widget.navigationShell.currentIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 淺色主 App：覆蓋全域預設，改為深色狀態列圖示
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress != null &&
            now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          // 2 秒內再次按下 → 真正退出
          SystemNavigator.pop();
        } else {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('再按一次退出程式'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
        child: Scaffold(
          // body 直接是各 tab 的頁面（它們自己管理 AppBar）
          body: widget.navigationShell,

          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            backgroundColor: colors.cardSurface,
            surfaceTintColor: Colors.transparent,
            indicatorColor: colors.forestGreenSubtle,
            onDestinationSelected: (index) {
              widget.navigationShell.goBranch(
                index,
                // 點擊已選中的 tab → 捲回頂部（GoRouter 預設行為）
                initialLocation: index == currentIndex,
              );
            },
            destinations: _tabs
                .asMap()
                .entries
                .map((e) => NavigationDestination(
                      icon: Icon(e.value.icon, color: colors.secondaryText),
                      selectedIcon: Icon(e.value.activeIcon, color: colors.forestGreen),
                      label: e.value.label,
                    ))
                .toList(),
          ),
        ),  // Scaffold
      ),  // AnnotatedRegion
    );  // PopScope
  }
}

class _TabItem {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
}
