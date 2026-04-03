import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

/// Dev 狀態選擇器（僅開發測試用）
///
/// 路由：/dev/state-picker
/// 在 Login 頁按下「Dev: Skip」後顯示，
/// 讓開發者選擇要模擬哪種用戶狀態來測試對應畫面。
class DevStatePickerPage extends StatelessWidget {
  const DevStatePickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.brandBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // ── 頂部返回 ──────────────────────────────────────────
              GestureDetector(
                onTap: () => context.go('/welcome'),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8, right: 20),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: colors.brandOnDark.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── 標題 ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.brandGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: colors.brandGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '⚙  DEV MODE',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.5,
                    color: colors.brandGold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                '選擇要測試的\n用戶狀態',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  color: colors.brandOnDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '此頁面只在開發建置中出現',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: colors.brandCaption,
                ),
              ),

              const SizedBox(height: 48),

              // ── 狀態選項 ──────────────────────────────────────────
              _StateOption(
                colors: colors,
                icon: Icons.hourglass_top_rounded,
                label: '審核中',
                sublabel: 'PendingPage',
                onTap: () => context.go('/dev/pending'),
              ),
              const SizedBox(height: 12),
              _StateOption(
                colors: colors,
                icon: Icons.schedule_rounded,
                label: '拒絕 — 一般',
                sublabel: 'RejectedPage (soft)',
                onTap: () => context.go('/dev/rejected-soft'),
              ),
              const SizedBox(height: 12),
              _StateOption(
                colors: colors,
                icon: Icons.auto_awesome_rounded,
                label: '拒絕 — 有潛力',
                sublabel: 'RejectedPage (potential)',
                accent: colors.brandGold,
                onTap: () => context.go('/dev/rejected-potential'),
              ),
              const SizedBox(height: 12),
              _StateOption(
                colors: colors,
                icon: Icons.check_circle_outline_rounded,
                label: '完整申請流程',
                sublabel: 'Step 2 → 3 → 4 → 5（不寫入 DB）',
                onTap: () => context.go('/dev/apply-info'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 狀態選項卡片 ──────────────────────────────────────────────────────────────

class _StateOption extends StatelessWidget {
  const _StateOption({
    required this.colors,
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
    this.accent,
  });

  final AppColors colors;
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final accentColor = accent ?? colors.forestGreen;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.15),
              ),
              child: Icon(icon, size: 20, color: accentColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.brandOnDark,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: colors.brandCaption,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: colors.brandCaption,
            ),
          ],
        ),
      ),
    );
  }
}
