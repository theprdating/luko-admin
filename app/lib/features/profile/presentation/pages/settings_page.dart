import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/sign_out.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/supabase/supabase_provider.dart' show currentUserProvider;
import '../../../../l10n/app_localizations.dart';

/// 設定頁
///
/// 路由：/settings（push）
/// 區塊結構：帳號 → 隱私 → 偏好 → 支援 → 關於 → 登出 → 帳號安全（深埋）
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const String _appVersion = '1.0.3';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    // 取得手機號碼（mask 顯示）
    final user = ref.watch(currentUserProvider);
    final rawPhone = user?.phone ?? '';
    final maskedPhone = _maskPhone(rawPhone);

    return Scaffold(
      backgroundColor: colors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: colors.backgroundWarm,
        surfaceTintColor: colors.backgroundWarm,
        elevation: 0,
        title: Text(
          l10n.settingsTitle,
          style: textTheme.titleMedium?.copyWith(
            color: colors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        children: [
          // ── 帳號 ──────────────────────────────────────────────────────
          _SectionHeader(title: l10n.settingsSectionAccount, colors: colors),
          _SettingsTile(
            icon: Icons.phone_outlined,
            title: l10n.settingsPhone,
            trailing: Text(
              maskedPhone.isNotEmpty ? maskedPhone : '—',
              style: textTheme.bodyMedium?.copyWith(color: colors.secondaryText),
            ),
            colors: colors,
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: l10n.settingsNotifications,
            trailing: _NotificationToggle(colors: colors),
            colors: colors,
          ),

          // ── 隱私 ──────────────────────────────────────────────────────
          _SectionHeader(title: l10n.settingsSectionPrivacy, colors: colors),
          _SettingsTile(
            icon: Icons.visibility_outlined,
            title: '配對可見度',
            trailing: Text(
              '所有人',
              style: textTheme.bodyMedium?.copyWith(color: colors.secondaryText),
            ),
            colors: colors,
          ),
          _SettingsTile(
            icon: Icons.block_outlined,
            title: '封鎖名單',
            hasArrow: true,
            colors: colors,
          ),

          // ── 偏好 ──────────────────────────────────────────────────────
          _SectionHeader(title: l10n.settingsSectionPreferences, colors: colors),
          _SettingsTile(
            icon: Icons.language_outlined,
            title: l10n.settingsLanguage,
            trailing: Text(
              Localizations.localeOf(context).languageCode == 'zh'
                  ? l10n.settingsLanguageZh
                  : l10n.settingsLanguageEn,
              style: textTheme.bodyMedium?.copyWith(color: colors.secondaryText),
            ),
            hasArrow: true,
            colors: colors,
            onTap: () => _showLanguagePicker(context, ref, colors, l10n),
          ),

          // ── 支援 ──────────────────────────────────────────────────────
          _SectionHeader(title: l10n.settingsSectionSupport, colors: colors),
          _SettingsTile(
            icon: Icons.help_outline,
            title: l10n.settingsFaq,
            hasArrow: true,
            colors: colors,
          ),
          _SettingsTile(
            icon: Icons.mail_outline,
            title: l10n.settingsContactUs,
            hasArrow: true,
            colors: colors,
          ),
          _SettingsTile(
            icon: Icons.flag_outlined,
            title: l10n.settingsReport,
            hasArrow: true,
            colors: colors,
          ),

          // ── 關於 ──────────────────────────────────────────────────────
          _SectionHeader(title: l10n.settingsSectionAbout, colors: colors),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: l10n.settingsTerms,
            hasArrow: true,
            colors: colors,
            onTap: () => context.push('/terms'),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.settingsPrivacy,
            hasArrow: true,
            colors: colors,
            onTap: () => context.push('/privacy'),
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: l10n.settingsVersion,
            trailing: Text(
              _appVersion,
              style: textTheme.bodyMedium?.copyWith(color: colors.secondaryText),
            ),
            colors: colors,
          ),

          // ── 登出 ──────────────────────────────────────────────────────
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            child: OutlinedButton(
              onPressed: () => _confirmLogout(context, l10n, colors),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.divider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                l10n.settingsLogout,
                style: textTheme.labelLarge?.copyWith(
                  color: colors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // ── 深埋的帳號安全入口 ─────────────────────────────────────────
          // 刻意放在最底部，以小字次要色呈現，降低誤觸機率。
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: GestureDetector(
              onTap: () => context.push('/settings/security'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.pagePadding,
                ),
                child: Text(
                  l10n.settingsAccountSecurity,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.secondaryText.withValues(alpha: 0.5),
                    decoration: TextDecoration.underline,
                    decorationColor: colors.secondaryText.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  // 手機號碼遮罩：+886912345678 → +886 ****5678
  static String _maskPhone(String phone) {
    if (phone.length < 4) return phone;
    final visible = phone.substring(phone.length - 4);
    final prefix = phone.length > 7 ? phone.substring(0, phone.length - 7) : '';
    return '$prefix ****$visible'.trim();
  }

  Future<void> _confirmLogout(
    BuildContext context,
    AppLocalizations l10n,
    AppColors colors,
  ) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(l10n.settingsLogoutTitle),
        content: Text(l10n.settingsLogoutMessage),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: Text(
              l10n.commonCancel,
              style: TextStyle(color: colors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: Text(
              l10n.settingsLogoutConfirm,
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await signOutAll();
      // GoRouter redirect 自動導向 /welcome
    }
  }

  void _showLanguagePicker(
    BuildContext context,
    WidgetRef ref,
    AppColors colors,
    AppLocalizations l10n,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final currentLang = Localizations.localeOf(context).languageCode;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.bottomSheet),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: colors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            child: Text(
              l10n.settingsLanguage,
              style: textTheme.titleMedium?.copyWith(
                color: colors.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            leading: const Text('🇹🇼', style: TextStyle(fontSize: 22)),
            title: Text(l10n.settingsLanguageZh,
                style: textTheme.bodyLarge?.copyWith(color: colors.primaryText)),
            trailing: currentLang == 'zh'
                ? Icon(Icons.check, color: colors.forestGreen)
                : null,
            onTap: () {
              ref.read(localeProvider.notifier)
                  .setLocale(const Locale('zh', 'TW'));
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
            title: Text(l10n.settingsLanguageEn,
                style: textTheme.bodyLarge?.copyWith(color: colors.primaryText)),
            trailing: currentLang == 'en'
                ? Icon(Icons.check, color: colors.forestGreen)
                : null,
            onTap: () {
              ref.read(localeProvider.notifier)
                  .setLocale(const Locale('en'));
              Navigator.pop(ctx);
            },
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + AppSpacing.md),
        ],
      ),
    );
  }
}

// ── 區塊標題 ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.colors});
  final String title;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding, AppSpacing.xl,
        AppSpacing.pagePadding, AppSpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.secondaryText,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
      ),
    );
  }
}

// ── 設定 ListTile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.colors,
    this.trailing,
    this.hasArrow = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final bool hasArrow;
  final AppColors colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      leading: Icon(icon, color: colors.primaryText, size: 22),
      title: Text(
        title,
        style: textTheme.bodyLarge?.copyWith(color: colors.primaryText),
      ),
      trailing: trailing ??
          (hasArrow
              ? Icon(Icons.chevron_right, color: colors.secondaryText, size: 20)
              : null),
      onTap: onTap,
      minLeadingWidth: 28,
    );
  }
}

// ── 通知開關（本地 UI 狀態）────────────────────────────────────────────────────

class _NotificationToggle extends StatefulWidget {
  const _NotificationToggle({required this.colors});
  final AppColors colors;

  @override
  State<_NotificationToggle> createState() => _NotificationToggleState();
}

class _NotificationToggleState extends State<_NotificationToggle> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: _enabled,
      onChanged: (v) => setState(() => _enabled = v),
      activeThumbColor: widget.colors.forestGreen,
      activeTrackColor: widget.colors.forestGreen.withValues(alpha: 0.4),
    );
  }
}
