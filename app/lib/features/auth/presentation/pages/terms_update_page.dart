import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/luko_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────
const Color _kBgBase = Color(0xFF0F1E15);
const Color _kGold   = Color(0xFFC9A96E);
const Color _kTitle  = Color(0xFFF0FDF4);

/// 條款強制更新頁
///
/// 路由：/terms-update
/// 當 appUserStatusProvider 回傳 AppUserStatus.termsRequired 時顯示。
/// 用戶必須同意最新條款才能繼續使用 App；拒絕則登出。
/// 無法用返回鍵跳過（PopScope canPop: false）。
class TermsUpdatePage extends ConsumerStatefulWidget {
  const TermsUpdatePage({super.key});

  @override
  ConsumerState<TermsUpdatePage> createState() => _TermsUpdatePageState();
}

class _TermsUpdatePageState extends ConsumerState<TermsUpdatePage> {
  bool _isAccepting = false;

  // ── TapGestureRecognizer 生命週期管理 ─────────────────────────────────────
  late final TapGestureRecognizer _termsTap =
      TapGestureRecognizer()..onTap = () => context.push('/terms');
  late final TapGestureRecognizer _privacyTap =
      TapGestureRecognizer()..onTap = () => context.push('/privacy');

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);

    try {
      final supabase = ref.read(supabaseProvider);
      final userId   = supabase.auth.currentUser!.id;
      final now      = DateTime.now().toUtc().toIso8601String();

      await supabase.from('profiles').update({
        'terms_accepted_at':   now,
        'privacy_accepted_at': now,
      }).eq('id', userId);

      // 重新評估狀態 → approved → GoRouter 導向 /discover
      ref.invalidate(appUserStatusProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isAccepting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.commonError),
        ),
      );
    }
  }

  Future<void> _decline() async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.termsUpdateDecline),
        content: const Text('登出後，您可以隨時重新登入並接受最新條款。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.settingsLogout,
              style: TextStyle(
                color: Theme.of(ctx).extension<AppColors>()!.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref.read(supabaseProvider).auth.signOut();
    // Auth stream 觸發 → appUserStatusProvider → unauthenticated → /welcome
  }

  @override
  Widget build(BuildContext context) {
    final colors    = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n      = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false, // 不允許返回鍵跳過
      child: Scaffold(
        // 深色頂部 hero + 淺色卡片底部，與 login / apply 統一設計語彙
        backgroundColor: _kBgBase,
        body: Column(
          children: [

            // ── 深色品牌 Hero ───────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 20, 32, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App icon
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.04),
                            blurRadius: 50,
                            spreadRadius: 16,
                          ),
                          BoxShadow(
                            color: const Color(0xFF3D6B4F).withValues(alpha: 0.12),
                            blurRadius: 30,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/app_icon_white.png',
                        height: 64,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox(height: 64),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // LUKO wordmark
                    Text(
                      'LUKO',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 8.0,
                        color: _kTitle,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 金色細線
                    SizedBox(
                      width: 32,
                      height: 1.0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _kGold.withValues(alpha: 0.0),
                              _kGold,
                              _kGold,
                              _kGold.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.2, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 淺色內容卡片 ────────────────────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.backgroundWarm,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(
                      color: _kGold.withValues(alpha: 0.22),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pagePadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 金色把手
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 4),
                            child: Container(
                              width: 40,
                              height: 3,
                              decoration: BoxDecoration(
                                color: _kGold.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // ── 標題 ─────────────────────────────────────
                        Text(
                          l10n.termsUpdateTitle,
                          style: textTheme.headlineSmall?.copyWith(
                            color: colors.primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // ── 說明 ─────────────────────────────────────
                        Text(
                          l10n.termsUpdateSubtitle,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.secondaryText,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // ── 條款連結區塊 ──────────────────────────────
                        _LinksCard(
                          colors: colors,
                          termsTap: _termsTap,
                          privacyTap: _privacyTap,
                        ),

                        const Spacer(),

                        // ── 同意按鈕 ──────────────────────────────────
                        LukoButton.primary(
                          label: _isAccepting
                              ? l10n.termsUpdateAccepting
                              : l10n.termsUpdateAccept,
                          onPressed: _isAccepting ? null : _accept,
                          isLoading: _isAccepting,
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // ── 拒絕連結 ──────────────────────────────────
                        TextButton(
                          onPressed: _isAccepting ? null : _decline,
                          child: Text(
                            l10n.termsUpdateDecline,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.secondaryText,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// ── 條款 & 隱私連結卡片 ─────────────────────────────────────────────────────

class _LinksCard extends StatelessWidget {
  const _LinksCard({
    required this.colors,
    required this.termsTap,
    required this.privacyTap,
  });

  final AppColors colors;
  final TapGestureRecognizer termsTap;
  final TapGestureRecognizer privacyTap;

  @override
  Widget build(BuildContext context) {
    final l10n      = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        children: [
          _LinkRow(
            icon: Icons.description_outlined,
            label: l10n.termsReadFull,
            recognizer: termsTap,
            colors: colors,
            textTheme: textTheme,
            showDivider: true,
          ),
          _LinkRow(
            icon: Icons.shield_outlined,
            label: l10n.privacyReadFull,
            recognizer: privacyTap,
            colors: colors,
            textTheme: textTheme,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.recognizer,
    required this.colors,
    required this.textTheme,
    required this.showDivider,
  });

  final IconData icon;
  final String label;
  final TapGestureRecognizer recognizer;
  final AppColors colors;
  final TextTheme textTheme;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: recognizer.onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: _kGold),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.primaryText,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colors.secondaryText,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: colors.divider),
      ],
    );
  }
}
