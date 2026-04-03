import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/analytics/analytics_events.dart';
import '../../../../../core/analytics/analytics_provider.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/supabase/supabase_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/luko_button.dart';
import '../../../../../core/widgets/luko_loading_overlay.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../providers/apply_provider.dart';
import '../../../providers/auth_provider.dart';

/// 申請 Step 6 — 確認送出
///
/// 路由：/apply/confirm（正式）或 /dev/apply-confirm（開發測試）
/// 預覽所有表單資料 → 勾選條款 → 送出申請至 Supabase DB
/// 送出成功後 reset provider + invalidate appUserStatusProvider，
/// GoRouter redirect 自動導向 /review/pending
///
/// Dev 模式：不寫入 DB，直接導回 /dev/state-picker（避免把開發者帳號鎖成 pending）
class ApplyConfirmPage extends ConsumerStatefulWidget {
  const ApplyConfirmPage({super.key, this.isDevMode = false});

  /// true → 送出時跳過 DB 寫入，直接導回 /dev/state-picker
  final bool isDevMode;

  @override
  ConsumerState<ApplyConfirmPage> createState() => _ApplyConfirmPageState();
}

class _ApplyConfirmPageState extends ConsumerState<ApplyConfirmPage> {
  bool _isAgreed = false;
  bool _isSubmitting = false;
  String? _submitError;

  // ── 送出申請 ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_isAgreed || _isSubmitting) return;
    final l10n = AppLocalizations.of(context)!;
    final form = ref.read(applyFormProvider);

    // ── Dev 模式：跳過 DB 寫入，模擬送出後導回選擇器 ──────────────────────
    if (widget.isDevMode) {
      ref.read(applyFormProvider.notifier).reset();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚙ Dev: 申請流程完整測試完成'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/dev/state-picker');
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final supabase = ref.read(supabaseProvider);
      final userId = supabase.auth.currentUser!.id;

      final now = DateTime.now().toUtc().toIso8601String();

      await supabase.from('applications').upsert(
        {
          'user_id':             userId,
          'display_name':        form.displayName,
          'birth_date':          form.birthDate!.toIso8601String().substring(0, 10),
          'gender':              form.gender,
          'bio':                 form.bio.isEmpty ? null : form.bio,
          'photo_paths':         form.uploadedPhotoPaths,
          'seeking':             form.seeking,
          'status':              'pending',
          // 記錄用戶首次接受條款的時間（Step 5 勾選的當下）
          // 審核通過後此值由 Edge Function 複製到 profiles.terms_accepted_at
          'terms_accepted_at':   now,
          'privacy_accepted_at': now,
        },
        onConflict: 'user_id',
      );

      // 申請送出成功後，請求推播通知權限
      // 此時機最佳：用戶剛完成重要行動，接受通知許可的意願最高
      try {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (_) {
        // 通知權限請求失敗不影響申請流程，靜默忽略
      }

      // 清空暫存的申請資料
      ref.read(applyFormProvider.notifier).reset();

      // 追蹤申請送出事件
      ref.read(analyticsProvider)
        ..track(AnalyticsEvents.applyStepCompleted, {'step': 6})
        ..track(AnalyticsEvents.applySubmitted);

      // 觸發 GoRouter redirect：appUserStatusProvider 重新查詢後狀態變 pending，
      // redirect 函式會自動導向 /review/pending
      ref.invalidate(appUserStatusProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = l10n.commonError;
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final form = ref.watch(applyFormProvider);

    return LukoLoadingOverlay(
      isLoading: _isSubmitting,
      message: l10n.applyConfirmSubmitting,
      child: Scaffold(
        backgroundColor: colors.backgroundWarm,
        appBar: AppBar(
          backgroundColor: colors.backgroundWarm,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.go(
              widget.isDevMode ? '/dev/apply-bio' : '/apply/bio',
            ),
          ),
          title: Text(
            l10n.applyStep(6, 6),
            style: textTheme.labelMedium?.copyWith(
              color: colors.secondaryText,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),

                // ── 頁面標題 ──────────────────────────────────────────────
                Text(
                  l10n.applyConfirmTitle,
                  style: textTheme.headlineMedium?.copyWith(
                    color: colors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.applyConfirmSubtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── 照片縮圖列 ────────────────────────────────────────────
                _PhotoRow(
                  localPaths: form.localPhotoPaths,
                  colors: colors,
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── 基本資料卡片 ──────────────────────────────────────────
                _InfoCard(form: form, colors: colors),
                const SizedBox(height: AppSpacing.lg),

                // ── 審核說明卡片 ──────────────────────────────────────────
                _ReviewInfoCard(colors: colors, l10n: l10n),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),

        // ── 底部：條款 + 錯誤訊息 + 送出按鈕 ─────────────────────────────
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.sm,
              AppSpacing.pagePadding,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 條款同意列（含可點擊的服務條款 & 隱私權政策連結）
                _TermsRow(
                  isAgreed: _isAgreed,
                  colors: colors,
                  onChanged: (v) => setState(() => _isAgreed = v ?? false),
                  onTermsTap: () => context.push('/terms'),
                  onPrivacyTap: () => context.push('/privacy'),
                ),

                if (_submitError != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _submitError!,
                    style: textTheme.bodySmall?.copyWith(color: colors.error),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: AppSpacing.sm),

                LukoButton.primary(
                  label: l10n.applySubmitButton,
                  onPressed: (_isAgreed && !_isSubmitting) ? _submit : null,
                  isLoading: _isSubmitting,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 照片縮圖列（顯示所有已選照片，等寬排列）────────────────────────────────────

class _PhotoRow extends StatelessWidget {
  const _PhotoRow({required this.localPaths, required this.colors});

  final List<String> localPaths;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    if (localPaths.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (int i = 0; i < localPaths.length; i++) ...[
          Expanded(
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Image.file(
                  File(localPaths[i]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          if (i < localPaths.length - 1)
            const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

// ── 基本資料卡片 ──────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.form, required this.colors});

  final ApplyFormData form;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 名稱、生日、性別
          _InfoRow(
            label: l10n.applyNameLabel,
            value: form.displayName,
            colors: colors,
          ),
          _Divider(colors: colors),
          _InfoRow(
            label: l10n.applyBirthDateLabel,
            value: form.birthDate != null
                ? _birthDisplay(form.birthDate!)
                : '—',
            colors: colors,
          ),
          _Divider(colors: colors),
          _InfoRow(
            label: l10n.applyGenderLabel,
            value: _genderLabel(l10n, form.gender),
            colors: colors,
          ),
          _Divider(colors: colors),
          _InfoRow(
            label: l10n.applySeekingLabel,
            value: _seekingLabel(l10n, form.seeking),
            colors: colors,
          ),
          // Bio（若有填寫才顯示）
          _Divider(colors: colors),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.applyBioTitle,
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  form.bio.isEmpty ? l10n.applyConfirmNoBio : form.bio,
                  style: textTheme.bodyMedium?.copyWith(
                    color: form.bio.isEmpty
                        ? colors.secondaryText
                        : colors.primaryText,
                    fontStyle: form.bio.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _birthDisplay(DateTime birth) {
    final age = _calcAge(birth);
    final y = birth.year;
    final m = birth.month.toString().padLeft(2, '0');
    final d = birth.day.toString().padLeft(2, '0');
    return '$y/$m/$d（$age 歲）';
  }

  String _genderLabel(AppLocalizations l10n, String gender) {
    return switch (gender) {
      'male'   => l10n.applyGenderMale,
      'female' => l10n.applyGenderFemale,
      _        => l10n.applyGenderOther,
    };
  }

  String _seekingLabel(AppLocalizations l10n, List<String> seeking) {
    if (seeking.isEmpty) return '—';
    return switch (seeking.first) {
      'male'     => l10n.applySeekingMen,
      'female'   => l10n.applySeekingWomen,
      'everyone' => l10n.applySeekingEveryone,
      _          => seeking.first,
    };
  }
}

// ── 單列資訊（label + value）─────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String value;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: colors.secondaryText,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.primaryText,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: colors.divider);
}

// ── 條款同意列（含可點擊連結）────────────────────────────────────────────────
//
// "我同意 [服務條款] 及 [隱私權政策]"
// TapGestureRecognizer 需在 StatefulWidget 中管理生命週期以正確 dispose

class _TermsRow extends StatefulWidget {
  const _TermsRow({
    required this.isAgreed,
    required this.colors,
    required this.onChanged,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  final bool isAgreed;
  final AppColors colors;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  State<_TermsRow> createState() => _TermsRowState();
}

class _TermsRowState extends State<_TermsRow> {
  late final TapGestureRecognizer _termsTap =
      TapGestureRecognizer()..onTap = () => widget.onTermsTap();
  late final TapGestureRecognizer _privacyTap =
      TapGestureRecognizer()..onTap = () => widget.onPrivacyTap();

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n      = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final baseStyle = textTheme.bodySmall?.copyWith(
      color: widget.colors.secondaryText,
      height: 1.5,
    );
    const linkStyle = TextStyle(
      color: Color(0xFFC9A96E), // 品牌金
      decoration: TextDecoration.underline,
      decorationColor: Color(0x7FC9A96E),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 略微上移 checkbox 使其與文字第一行對齊
        Transform.translate(
          offset: const Offset(0, -2),
          child: Checkbox(
            value: widget.isAgreed,
            onChanged: widget.onChanged,
            activeColor: widget.colors.forestGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: baseStyle,
              children: [
                TextSpan(text: l10n.termsAgreePrefix),
                TextSpan(
                  text: l10n.termsLabel,
                  recognizer: _termsTap,
                  style: linkStyle,
                ),
                TextSpan(text: l10n.termsAgreeAnd),
                TextSpan(
                  text: l10n.privacyLabel,
                  recognizer: _privacyTap,
                  style: linkStyle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── 審核說明卡片 ──────────────────────────────────────────────────────────────
//
// 顯示預計審核時間和通知管道，讓用戶送出前有明確預期

class _ReviewInfoCard extends StatelessWidget {
  const _ReviewInfoCard({required this.colors, required this.l10n});

  final AppColors colors;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.forestGreenSubtle,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.forestGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 標題列 ─────────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: colors.forestGreen,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.applyConfirmReviewInfoTitle,
                style: textTheme.labelMedium?.copyWith(
                  color: colors.forestGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── 審核時間 ──────────────────────────────────────────
          _ReviewInfoRow(
            icon: Icons.schedule_rounded,
            text: l10n.applyConfirmReviewDays,
            colors: colors,
          ),
          const SizedBox(height: AppSpacing.xs),

          // ── 通知方式 ──────────────────────────────────────────
          _ReviewInfoRow(
            icon: Icons.notifications_outlined,
            text: l10n.applyConfirmReviewNotify,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _ReviewInfoRow extends StatelessWidget {
  const _ReviewInfoRow({
    required this.icon,
    required this.text,
    required this.colors,
  });

  final IconData icon;
  final String text;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 14, color: colors.secondaryText),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: colors.secondaryText,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 工具函式 ──────────────────────────────────────────────────────────────────

int _calcAge(DateTime birth) {
  final now = DateTime.now();
  int age = now.year - birth.year;
  if (now.month < birth.month ||
      (now.month == birth.month && now.day < birth.day)) {
    age--;
  }
  return age;
}
