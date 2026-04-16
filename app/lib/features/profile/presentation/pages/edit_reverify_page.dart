import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import 'edit_photos_page.dart' show PendingPhotoData, ExistingSlot, NewSlot;

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/luko_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/verification_action.dart';
import '../../providers/profile_provider.dart';

/// 換照驗證頁
///
/// 路由：/me/edit/photos/reverify（從 EditPhotosPage push）
/// GoRouter extra：PendingPhotoData（含排序後的 slots，尚未上傳）
///
/// 流程：
///   Step 1：拍正面照
///   Step 2：拍 1 個隨機動作照
///   → 上傳新照片（NewSlot）到 profile-photos/{userId}/{ts}_{i}.jpg
///   → 上傳驗證照到 profile-photos/{userId}/reverify/{ts}_{0,1}.jpg
///   → 更新 profiles: pending_photo_paths + photo_pending_review=true + reverify_photo_paths
///   → pop ×2 回 EditProfilePage，顯示成功 SnackBar
///
/// 所有 Storage 上傳集中在此頁「送出」，避免早傳產生孤兒檔案。
class EditReverifyPage extends ConsumerStatefulWidget {
  const EditReverifyPage({super.key, required this.pendingData});

  final PendingPhotoData pendingData;

  @override
  ConsumerState<EditReverifyPage> createState() => _EditReverifyPageState();
}

enum _Step { front, action }

class _EditReverifyPageState extends ConsumerState<EditReverifyPage> {
  final _picker = ImagePicker();

  _Step _step = _Step.front;
  late final VerificationAction _randomAction;

  String? _frontPath;
  String? _actionPath;

  bool _isUploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final all = List.of(VerificationAction.values)..shuffle(Random());
    _randomAction = all.first;
  }

  // ── 拍照 ─────────────────────────────────────────────────────────────────────

  Future<void> _capture() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 90,
    );
    if (file == null || !mounted) return;
    final compressed = await _compressToJpeg(file.path);
    if (compressed == null || !mounted) return;
    setState(() {
      if (_step == _Step.front) {
        _frontPath = compressed;
      } else {
        _actionPath = compressed;
      }
    });
  }

  void _retake() => setState(() {
    if (_step == _Step.front) {
      _frontPath = null;
    } else {
      _actionPath = null;
    }
  });

  void _goToAction() => setState(() => _step = _Step.action);

  Future<String?> _compressToJpeg(String sourcePath) async {
    final tmpDir = await getTemporaryDirectory();
    final ts = DateTime.now().microsecondsSinceEpoch;
    final targetPath = '${tmpDir.path}/luko_reverify_$ts.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath, targetPath,
      quality: 85, minWidth: 800, minHeight: 800,
      format: CompressFormat.jpeg,
    );
    return result?.path;
  }

  // ── 送出：上傳新照片 + reverify 照片 → 更新 profiles ────────────────────────
  //
  // 所有 Storage 上傳在此一次完成，不依賴 EditPhotosPage 的早傳，
  // 避免用戶放棄 reverify 時產生孤兒檔案。

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_frontPath == null || _actionPath == null) return;

    setState(() { _isUploading = true; _error = null; });
    try {
      final supabase = ref.read(supabaseProvider);
      final userId = widget.pendingData.userId;
      final slots = widget.pendingData.slots;

      final ts = DateTime.now().millisecondsSinceEpoch;

      // 1. 上傳新照片（僅 NewSlot；ExistingSlot 保留原路徑不重傳）
      final pendingPaths = <String>[];
      for (int i = 0; i < slots.length; i++) {
        final slot = slots[i];
        switch (slot) {
          case final ExistingSlot existing:
            pendingPaths.add(existing.storagePath);
          case final NewSlot newPhoto:
            final storagePath = '$userId/${ts}_$i.jpg';
            await supabase.storage.from('profile-photos').upload(
              storagePath,
              File(newPhoto.localPath),
              fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
            );
            pendingPaths.add(storagePath);
        }
      }

      // 2. 上傳 reverify 驗證照
      final reverifyPaths = <String>[];
      for (final (i, localPath) in [_frontPath!, _actionPath!].indexed) {
        final storagePath = '$userId/reverify/${ts}_$i.jpg';
        await supabase.storage.from('profile-photos').upload(
          storagePath,
          File(localPath),
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
        reverifyPaths.add(storagePath);
      }

      // 3. 更新 profiles（atomic：全部上傳成功才寫 DB）
      // .select('id') 讓 SDK 回傳被更新的 rows；若回傳空陣列代表 RLS 靜默 block（0 rows），
      // 必須視為錯誤而非靜默成功。
      final updated = await supabase.from('profiles').update({
        'pending_photo_paths': pendingPaths,
        'photo_pending_review': true,
        'reverify_photo_paths': reverifyPaths,
      }).eq('id', userId).select('id');

      if (updated.isEmpty) {
        debugPrint('[EditReverifyPage] profiles.update returned 0 rows — RLS block or userId mismatch (userId=$userId)');
        throw Exception('profiles update matched 0 rows');
      }

      ref.invalidate(myProfileProvider);
      ref.invalidate(myProfilePhotoUrlsProvider);
      ref.invalidate(myProfilePhotoThumbnailUrlsProvider);
      ref.invalidate(myProfilePhotoPendingProvider);

      if (!mounted) return;
      // Pop reverify page and photos page, return to edit profile
      context.pop();
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.editReverifySuccess),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('[EditReverifyPage] submit error: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
          _error = AppLocalizations.of(context)!.editReverifyFailed;
        });
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final currentPhoto = _step == _Step.front ? _frontPath : _actionPath;
    final hasCurrent = currentPhoto != null;
    final canProceed = hasCurrent && !_isUploading;

    return Scaffold(
      backgroundColor: colors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: colors.backgroundWarm,
        surfaceTintColor: colors.backgroundWarm,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isUploading ? null : () => context.pop(),
        ),
        title: Text(
          l10n.editReverifyTitle,
          style: textTheme.titleMedium?.copyWith(
            color: colors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 說明 ────────────────────────────────────────────────
              Text(
                l10n.editReverifySubtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.secondaryText,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── 步驟指示 ────────────────────────────────────────────
              _StepIndicator(
                currentStep: _step == _Step.front ? 0 : 1,
                colors: colors,
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── 拍照指引 ────────────────────────────────────────────
              _StepPrompt(
                step: _step,
                action: _randomAction,
                l10n: l10n,
                colors: colors,
                textTheme: textTheme,
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── 預覽格 ──────────────────────────────────────────────
              _CameraSlot(localPath: currentPhoto, colors: colors),
              const SizedBox(height: AppSpacing.md),

              // ── 拍照 / 重拍 ─────────────────────────────────────────
              if (!hasCurrent)
                OutlinedButton.icon(
                  onPressed: _capture,
                  icon: Icon(Icons.camera_alt_outlined,
                      size: 18, color: colors.forestGreen),
                  label: Text(
                    l10n.applyVerifyTakePhoto,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.forestGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.forestGreen.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                )
              else
                TextButton.icon(
                  onPressed: _retake,
                  icon: Icon(Icons.refresh_rounded,
                      size: 16, color: colors.secondaryText),
                  label: Text(
                    l10n.applyVerifyRetake,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.secondaryText,
                    ),
                  ),
                ),

              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: textTheme.bodySmall?.copyWith(color: colors.error),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.sm,
            AppSpacing.pagePadding,
            AppSpacing.md,
          ),
          child: _step == _Step.front
              ? LukoButton.primary(
                  label: l10n.applyVerifyNextStep,
                  onPressed: canProceed ? _goToAction : null,
                )
              : LukoButton.primary(
                  label: _isUploading
                      ? l10n.editReverifyUploading
                      : l10n.editReverifySubmit,
                  onPressed: canProceed ? _submit : null,
                ),
        ),
      ),
    );
  }
}

// ── 步驟指示器（2 步）────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.colors});
  final int currentStep; // 0 or 1
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < 2; i++) ...[
          if (i > 0) ...[
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Container(
                height: 2,
                color: i <= currentStep ? colors.forestGreen : colors.divider,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= currentStep ? colors.forestGreen : colors.cardSurface,
              border: Border.all(
                color: i == currentStep
                    ? colors.forestGreen
                    : (i < currentStep ? colors.forestGreen : colors.divider),
              ),
            ),
            child: Center(
              child: i < currentStep
                  ? Icon(Icons.check_rounded, size: 14, color: colors.brandOnDark)
                  : Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: i == currentStep
                            ? colors.brandOnDark
                            : colors.secondaryText,
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── 步驟指引卡片 ──────────────────────────────────────────────────────────────

class _StepPrompt extends StatelessWidget {
  const _StepPrompt({
    required this.step,
    required this.action,
    required this.l10n,
    required this.colors,
    required this.textTheme,
  });
  final _Step step;
  final VerificationAction action;
  final AppLocalizations l10n;
  final AppColors colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final title = step == _Step.front
        ? l10n.applyVerifyStepFrontTitle
        : l10n.applyVerifyStepActionTitle;
    final hint = step == _Step.front
        ? l10n.applyVerifyStepFrontHint
        : '${l10n.applyVerifyStepActionHint} ${action.displayName(l10n)}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.forestGreenSubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.forestGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              color: colors.forestGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: textTheme.bodySmall?.copyWith(
              color: colors.primaryText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 相機預覽格 ────────────────────────────────────────────────────────────────

class _CameraSlot extends StatelessWidget {
  const _CameraSlot({required this.localPath, required this.colors});
  final String? localPath;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final slotSize = screenW - AppSpacing.pagePadding * 2;

    return Container(
      width: slotSize,
      height: slotSize * 0.75,
      decoration: BoxDecoration(
        color: colors.forestDeep,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.divider),
      ),
      clipBehavior: Clip.hardEdge,
      child: localPath == null
          ? Center(
              child: Icon(
                Icons.camera_alt_outlined,
                size: 48,
                color: colors.secondaryText.withValues(alpha: 0.4),
              ),
            )
          : Image.file(
              File(localPath!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(Icons.broken_image_outlined,
                    color: colors.secondaryText),
              ),
            ),
    );
  }
}
