import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
import '../../../domain/app_user_status.dart';

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

  // ── 送出申請（Step 6）────────────────────────────────────────────────────────
  //
  // 所有上傳集中在此處理（Step 3 照片頁僅選取與預覽，不上傳）：
  //   1. 上傳申請照片 → application-photos bucket（並行，繞過 uploadBinary bug）
  //   2. 上傳驗證照片 → verification-photos bucket
  //   3. 寫入 identity_verifications table
  //   4. 寫入 applications table
  //
  // 好處：
  //   - 用戶中途放棄不會留下孤兒檔案
  //   - 網路錯誤只在最後一步出現，不卡在流程中途
  //   - 申請照片並行上傳，速度更快

  Future<void> _submit() async {
    if (!_isAgreed || _isSubmitting) return;
    final l10n = AppLocalizations.of(context)!;
    final form = ref.read(applyFormProvider);

    // ── Dev 模式 ──────────────────────────────────────────────────────────
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
      final ts = DateTime.now().millisecondsSinceEpoch;

      // ── 輔助：用 upload(File) 上傳單張照片 ──────────────────────────────
      // 使用 upload(File) 而非 uploadBinary(bytes)，
      // 繞過 storage_client 2.5.0 在 bucket 有 allowed_mime_types 時的 404 bug。
      Future<String> uploadFile(
          String bucket,
          String localPath,
          String storagePath,
          ) async {
        final file = File(localPath);
        await supabase.storage.from(bucket).upload(
          storagePath,
          file,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
        return storagePath;
      }

      // ── 1. 上傳申請照片（若尚未上傳）────────────────────────────────────
      // 重新申請且照片未修改（uploadedPhotoPaths 非空）→ 直接重用既有路徑
      // 首次申請或照片已修改（新選 / 刪除 / 排序）→ 從本機路徑並行上傳
      final List<String> uploadedPhotoPaths;
      if (form.uploadedPhotoPaths.isNotEmpty) {
        uploadedPhotoPaths = form.uploadedPhotoPaths;
      } else {
        final photoFutures = List.generate(
          form.localPhotoPaths.length,
          (i) => uploadFile(
            'application-photos',
            form.localPhotoPaths[i],
            '$userId/photos/${ts}_$i.jpg',
          ),
        );
        uploadedPhotoPaths = await Future.wait(photoFutures);
        if (uploadedPhotoPaths.isEmpty) {
          throw Exception('所有照片上傳失敗，請確認網路連線');
        }
      }

      // ── 2. 上傳驗證照片 → verification-photos ───────────────────────────
      final frontStoragePath = await uploadFile(
        'verification-photos',
        form.verificationFrontPath,
        '$userId/verify/${ts}_front.jpg',
      );
      final sideStoragePath = await uploadFile(
        'verification-photos',
        form.verificationSidePath,
        '$userId/verify/${ts}_side.jpg',
      );
      final action1StoragePath = await uploadFile(
        'verification-photos',
        form.verificationAction1Path,
        '$userId/verify/${ts}_action1.jpg',
      );
      final action2StoragePath = await uploadFile(
        'verification-photos',
        form.verificationAction2Path,
        '$userId/verify/${ts}_action2.jpg',
      );

      // ── 3. 寫入 identity_verifications ──────────────────────────────────
      await supabase.from('identity_verifications').upsert(
        {
          'user_id':          userId,
          'front_face_path':  frontStoragePath,
          'side_face_path':   sideStoragePath,
          'action1_code':     form.verificationAction1,
          'action1_path':     action1StoragePath,
          'action2_code':     form.verificationAction2,
          'action2_path':     action2StoragePath,
          'status':           'pending',
        },
        onConflict: 'user_id',
      );

      // ── 4. 寫入 applications ─────────────────────────────────────────────
      final now = DateTime.now().toUtc().toIso8601String();
      await supabase.from('applications').upsert(
        {
          'user_id':             userId,
          'display_name':        form.displayName,
          'birth_date':          form.birthDate!.toIso8601String().substring(0, 10),
          'gender':              form.gender,
          'bio':                 form.bio.isEmpty ? null : form.bio,
          'photo_paths':         uploadedPhotoPaths,
          'seeking':             form.seeking,
          'status':              'pending',
          'terms_accepted_at':   now,
          'privacy_accepted_at': now,
        },
        onConflict: 'user_id',
      );

      // ── 申請送出成功 ──────────────────────────────────────────────────────

      // 請求推播通知權限（最佳時機：用戶剛完成重要行動）
      try {
        await FirebaseMessaging.instance.requestPermission(
          alert: true, badge: true, sound: true,
        );
      } catch (_) {}

      ref.read(applyFormProvider.notifier).reset();

      // 先讓 status 進 loading（router redirect 回傳 null，不重導向）
      // 再關閉 reapplyMode，避免 rejected 中間狀態閃屏到 /review/rejected
      ref.invalidate(appUserStatusProvider);
      ref.read(reapplyModeProvider.notifier).state = false;

      ref.read(analyticsProvider)
        ..track(AnalyticsEvents.applyStepCompleted, {'step': 6})
        ..track(AnalyticsEvents.applySubmitted);
    } catch (e, st) {
      debugPrint('Apply submit error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = l10n.commonError;
      });
    }
  }

  // ── Beta 用戶送出（無上傳照片、無真人認證，直接 call RPC）─────────────────────
  Future<void> _submitBeta() async {
    if (!_isAgreed || _isSubmitting) return;
    setState(() { _isSubmitting = true; _submitError = null; });

    try {
      final supabase = ref.read(supabaseProvider);
      final form = ref.read(applyFormProvider);

      await supabase.rpc('claim_beta_approval', params: {
        'p_display_name': form.displayName,
        'p_gender':       form.gender.isEmpty ? null : form.gender,
        'p_seeking':      form.seeking.isEmpty ? null : form.seeking,
        'p_bio':          form.bio.isEmpty ? null : form.bio,
        'p_photo_paths':  form.uploadedPhotoPaths.isEmpty
                          ? null
                          : form.uploadedPhotoPaths,
        'p_birth_date':   form.birthDate != null
                          ? form.birthDate!.toIso8601String().substring(0, 10)
                          : null,
      });

      // 請求推播通知權限
      try {
        await FirebaseMessaging.instance.requestPermission(
          alert: true, badge: true, sound: true,
        );
      } catch (_) {}

      ref.read(applyFormProvider.notifier).reset();
      // betaPendingProvider=true 讓 router 知道要先停在 /review/pending（而非直接 /review/approved）
      ref.read(betaPendingProvider.notifier).state = true;
      // invalidate 觸發 appUserStatusProvider 重算（betaOnboarding → phoneVerificationRequired）
      // router redirect：phoneVerificationRequired + betaPendingProvider=true → /review/pending
      // 不可用 context.go('/review/pending')：status 仍是 stale betaOnboarding 時 router 會踢回 /apply/info
      ref.invalidate(appUserStatusProvider);
    } catch (e) {
      debugPrint('Beta submit error: $e');
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = AppLocalizations.of(context)!.commonError;
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

    final isBetaMode = ref.watch(appUserStatusProvider).when(
      data: (s) => s == AppUserStatus.betaOnboarding,
      loading: () => false,
      error: (_, __) => false,
    );

    final backRoute = widget.isDevMode ? '/dev/apply-bio' : '/apply/bio';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isSubmitting) context.go(backRoute);
      },
      child: LukoLoadingOverlay(
      isLoading: _isSubmitting,
      message: l10n.applyConfirmSubmitting,
      child: Scaffold(
        backgroundColor: colors.backgroundWarm,
        appBar: AppBar(
          backgroundColor: colors.backgroundWarm,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.go(backRoute),
          ),
          title: Text(
            isBetaMode ? l10n.applyStep(3, 3) : l10n.applyStep(6, 6),
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

                // ── 照片縮圖列（有照片就顯示）────────────────────────────
                if (form.localPhotoPaths.isNotEmpty) ...[
                  _PhotoRow(
                    localPaths: form.localPhotoPaths,
                    colors: colors,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── 基本資料卡片 ──────────────────────────────────────────
                _InfoCard(form: form, colors: colors, isBetaMode: isBetaMode),
                const SizedBox(height: AppSpacing.lg),

                // ── 審核說明卡片 ──────────────────────────────────────────
                if (isBetaMode)
                  _BetaReviewInfoCard(colors: colors, l10n: l10n)
                else
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
                  onPressed: (_isAgreed && !_isSubmitting)
                      ? (isBetaMode ? _submitBeta : _submit)
                      : null,
                  isLoading: _isSubmitting,
                ),
              ],
            ),
          ),
        ),
      ),    // LukoLoadingOverlay
      ),    // PopScope
    );
  }
}

// ── 照片縮圖列（顯示所有已選照片，等寬排列，點擊可放大）──────────────────────────

class _PhotoRow extends StatelessWidget {
  const _PhotoRow({required this.localPaths, required this.colors});

  final List<String> localPaths;
  final AppColors colors;

  void _showFullscreen(BuildContext context, int index) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                // ── 可縮放的照片 ─────────────────────────────────────
                Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.file(
                      File(localPaths[index]),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // ── 關閉按鈕（右上角）───────────────────────────────
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // ── 照片計數（左上角）───────────────────────────────
                if (localPaths.length > 1)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${index + 1} / ${localPaths.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (localPaths.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (int i = 0; i < localPaths.length; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => _showFullscreen(context, i),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(localPaths[i]),
                        fit: BoxFit.cover,
                      ),
                      // 放大提示（僅第一張，引導用戶發現可點擊）
                      if (i == 0)
                        Positioned(
                          right: 5,
                          bottom: 5,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.zoom_in_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
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
  const _InfoCard({
    required this.form,
    required this.colors,
    this.isBetaMode = false,
  });

  final ApplyFormData form;
  final AppColors colors;
  final bool isBetaMode;

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
          // 名稱
          _InfoRow(
            label: l10n.applyNameLabel,
            value: form.displayName,
            colors: colors,
          ),
          // 生日（Beta 模式略過）
          if (!isBetaMode) ...[
            _Divider(colors: colors),
            _InfoRow(
              label: l10n.applyBirthDateLabel,
              value: form.birthDate != null
                  ? _birthDisplay(form.birthDate!)
                  : '—',
              colors: colors,
            ),
          ],
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
          // Bio
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: widget.isAgreed,
          onChanged: widget.onChanged,
          activeColor: widget.colors.forestGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
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

// ── Beta 審核說明卡片 ─────────────────────────────────────────────────────────
//
// Beta 用戶送出後即刻通過，不需等待人工審核

class _BetaReviewInfoCard extends StatelessWidget {
  const _BetaReviewInfoCard({required this.colors, required this.l10n});

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_outlined,
            size: 18,
            color: colors.forestGreen,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '封測用戶身份已確認，送出後即刻完成審核。',
              style: textTheme.bodySmall?.copyWith(
                color: colors.secondaryText,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
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