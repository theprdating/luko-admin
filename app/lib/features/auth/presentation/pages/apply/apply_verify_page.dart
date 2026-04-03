import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/supabase/supabase_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/luko_button.dart';
import '../../../../../core/widgets/luko_loading_overlay.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/verification_action.dart';
import '../../../providers/apply_provider.dart';

/// 申請 Step 4 — 真人認證
///
/// 路由：/apply/verify（正式）或 /dev/apply-verify（開發測試）
///
/// 流程：
///   intro（說明頁）
///   → Step 1：正面照
///   → Step 2：左側臉照
///   → Step 3：動作 1（隨機抽取）
///   → Step 4：動作 2（隨機抽取）
///   → 全部照片上傳至 Supabase（verification-photos bucket）
///   → 寫入 identity_verifications table
///   → 導向 /apply/bio
///
/// 認證照片僅供後台審核人員查閱，不對外顯示。
class ApplyVerifyPage extends ConsumerStatefulWidget {
  const ApplyVerifyPage({super.key, this.isDevMode = false});

  /// true → 跳過 Supabase 上傳，直接前往 /dev/apply-bio
  final bool isDevMode;

  @override
  ConsumerState<ApplyVerifyPage> createState() => _ApplyVerifyPageState();
}

// 認證流程的各步驟
enum _VerifyStep { intro, frontFace, sideFace, action1, action2 }

class _ApplyVerifyPageState extends ConsumerState<ApplyVerifyPage> {
  _VerifyStep _step = _VerifyStep.intro;

  final _picker = ImagePicker();

  // 每次進入頁面隨機抽取 2 個動作
  late final List<VerificationAction> _randomActions;

  // 各步驟拍攝的本機路徑
  String? _frontFacePath;
  String? _sideFacePath;
  String? _action1Path;
  String? _action2Path;

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();

    // 若已有儲存的認證資料（用戶返回此頁），復原狀態
    final form = ref.read(applyFormProvider);
    if (form.verificationDone) {
      _frontFacePath = form.verificationFrontPath;
      _sideFacePath  = form.verificationSidePath;
      _action1Path   = form.verificationAction1Path;
      _action2Path   = form.verificationAction2Path;

      // 復原動作（從 provider 的 action code 反查 enum）
      final a1 = VerificationActionX.fromCode(form.verificationAction1);
      final a2 = VerificationActionX.fromCode(form.verificationAction2);
      if (a1 != null && a2 != null) {
        _randomActions = [a1, a2];
        _step = _VerifyStep.intro; // 仍回到 intro，讓用戶可重新確認
        return;
      }
    }

    // 首次進入：隨機抽取 2 個動作
    final all = List.of(VerificationAction.values)..shuffle(Random());
    _randomActions = all.take(2).toList();
  }

  // ── 拍照（相機） ─────────────────────────────────────────────────────────────

  Future<String?> _capturePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 90,
    );
    if (file == null) return null;

    // 壓縮至 JPEG 但不裁切（認證照片保持原構圖）
    final tmpDir = await getTemporaryDirectory();
    final ts = DateTime.now().microsecondsSinceEpoch;
    final targetPath = '${tmpDir.path}/luko_verify_$ts.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 88,
      minWidth: 720,
      minHeight: 720,
      format: CompressFormat.jpeg,
    );
    return result?.path;
  }

  // ── 拍照並更新當前步驟 ───────────────────────────────────────────────────────

  Future<void> _takePhoto() async {
    final path = await _capturePhoto();
    if (path == null || !mounted) return;

    setState(() {
      switch (_step) {
        case _VerifyStep.frontFace: _frontFacePath = path;
        case _VerifyStep.sideFace:  _sideFacePath  = path;
        case _VerifyStep.action1:   _action1Path   = path;
        case _VerifyStep.action2:   _action2Path   = path;
        case _VerifyStep.intro:     break;
      }
    });
  }

  // ── 重拍 ─────────────────────────────────────────────────────────────────────

  void _retake() {
    setState(() {
      switch (_step) {
        case _VerifyStep.frontFace: _frontFacePath = null;
        case _VerifyStep.sideFace:  _sideFacePath  = null;
        case _VerifyStep.action1:   _action1Path   = null;
        case _VerifyStep.action2:   _action2Path   = null;
        case _VerifyStep.intro:     break;
      }
    });
  }

  // ── 目前步驟的照片 ───────────────────────────────────────────────────────────

  String? get _currentPath => switch (_step) {
    _VerifyStep.frontFace => _frontFacePath,
    _VerifyStep.sideFace  => _sideFacePath,
    _VerifyStep.action1   => _action1Path,
    _VerifyStep.action2   => _action2Path,
    _VerifyStep.intro     => null,
  };

  // ── 前進下一步 / 送出 ────────────────────────────────────────────────────────

  Future<void> _onNext() async {
    switch (_step) {
      case _VerifyStep.intro:
        setState(() => _step = _VerifyStep.frontFace);
        return;

      case _VerifyStep.frontFace:
        if (_frontFacePath == null) return;
        setState(() => _step = _VerifyStep.sideFace);
        return;

      case _VerifyStep.sideFace:
        if (_sideFacePath == null) return;
        setState(() => _step = _VerifyStep.action1);
        return;

      case _VerifyStep.action1:
        if (_action1Path == null) return;
        setState(() => _step = _VerifyStep.action2);
        return;

      case _VerifyStep.action2:
        if (_action2Path == null) return;
        await _uploadAndProceed();
        return;
    }
  }

  // ── 上傳認證照片並寫入 DB ─────────────────────────────────────────────────────

  Future<void> _uploadAndProceed() async {
    if (widget.isDevMode) {
      // Dev 模式：存路徑到 provider，直接前往 bio
      ref.read(applyFormProvider.notifier).setVerification(
        frontPath:   _frontFacePath ?? '',
        sidePath:    _sideFacePath  ?? '',
        action1:     _randomActions[0].name,
        action1Path: _action1Path   ?? '',
        action2:     _randomActions[1].name,
        action2Path: _action2Path   ?? '',
      );
      if (mounted) context.go('/dev/apply-bio');
      return;
    }

    setState(() => _isUploading = true);
    try {
      final supabase = ref.read(supabaseProvider);
      final userId = supabase.auth.currentUser!.id;
      final ts = DateTime.now().millisecondsSinceEpoch;

      // 上傳四張照片至 verification-photos bucket
      Future<String> upload(String localPath, String label) async {
        final bytes = await File(localPath).readAsBytes();
        final storagePath = '$userId/${ts}_$label.jpg';
        await supabase.storage
            .from('verification-photos')
            .uploadBinary(
              storagePath,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        return storagePath;
      }

      final frontPath   = await upload(_frontFacePath!, 'front');
      final sidePath    = await upload(_sideFacePath!,  'side');
      final action1Path = await upload(_action1Path!,   'action1');
      final action2Path = await upload(_action2Path!,   'action2');

      // 寫入 identity_verifications table
      await supabase.from('identity_verifications').insert({
        'user_id':        userId,
        'front_face_path': frontPath,
        'side_face_path':  sidePath,
        'action1_code':    _randomActions[0].name,
        'action1_path':    action1Path,
        'action2_code':    _randomActions[1].name,
        'action2_path':    action2Path,
        'status':          'pending',
      });

      // 儲存至 provider（供 confirm 頁顯示，以及返回時復原狀態）
      ref.read(applyFormProvider.notifier).setVerification(
        frontPath:   _frontFacePath!,
        sidePath:    _sideFacePath!,
        action1:     _randomActions[0].name,
        action1Path: _action1Path!,
        action2:     _randomActions[1].name,
        action2Path: _action2Path!,
      );

      if (!mounted) return;
      context.go('/apply/bio');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.commonError),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── 返回鍵處理 ───────────────────────────────────────────────────────────────

  void _onBack() {
    switch (_step) {
      case _VerifyStep.intro:
        context.go(widget.isDevMode ? '/dev/apply-photos' : '/apply/photos');
        return;
      case _VerifyStep.frontFace:
        setState(() => _step = _VerifyStep.intro);
        return;
      case _VerifyStep.sideFace:
        setState(() { _step = _VerifyStep.frontFace; _sideFacePath = null; });
        return;
      case _VerifyStep.action1:
        setState(() { _step = _VerifyStep.sideFace; _action1Path = null; });
        return;
      case _VerifyStep.action2:
        setState(() { _step = _VerifyStep.action1; _action2Path = null; });
        return;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return LukoLoadingOverlay(
      isLoading: _isUploading,
      message: l10n.applyVerifyUploading,
      child: Scaffold(
        backgroundColor: colors.backgroundWarm,
        appBar: AppBar(
          backgroundColor: colors.backgroundWarm,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: _onBack,
          ),
          title: Text(
            l10n.applyStep(4, 6),
            style: textTheme.labelMedium?.copyWith(color: colors.secondaryText),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: _step == _VerifyStep.intro
              ? _IntroView(
                  colors: colors,
                  l10n: l10n,
                  alreadyDone: _frontFacePath != null,
                  onStart: _onNext,
                )
              : _CaptureView(
                  step: _step,
                  colors: colors,
                  l10n: l10n,
                  randomActions: _randomActions,
                  capturedPath: _currentPath,
                  onTakePhoto: _takePhoto,
                  onRetake: _retake,
                  onNext: _currentPath != null ? _onNext : null,
                ),
        ),
      ),
    );
  }
}

// ── 介紹頁 ────────────────────────────────────────────────────────────────────

class _IntroView extends StatelessWidget {
  const _IntroView({
    required this.colors,
    required this.l10n,
    required this.alreadyDone,
    required this.onStart,
  });

  final AppColors colors;
  final AppLocalizations l10n;
  final bool alreadyDone; // 已完成過（返回）
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),

          // ── 圖示 ──────────────────────────────────────────────────
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.forestGreenSubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_user_outlined,
                size: 36,
                color: colors.forestGreen,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── 標題 ──────────────────────────────────────────────────
          Text(
            l10n.applyVerifyIntroTitle,
            style: textTheme.headlineMedium?.copyWith(
              color: colors.primaryText,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.applyVerifyIntroBody,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.secondaryText,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── 步驟列表卡片 ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.cardSurface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: colors.divider),
            ),
            child: Column(
              children: [
                _IntroStep(
                  number: 1,
                  label: l10n.applyVerifyIntroStep1,
                  colors: colors,
                ),
                const SizedBox(height: AppSpacing.md),
                _IntroStep(
                  number: 2,
                  label: l10n.applyVerifyIntroStep2,
                  colors: colors,
                ),
                const SizedBox(height: AppSpacing.md),
                _IntroStep(
                  number: 3,
                  label: l10n.applyVerifyIntroStep3,
                  colors: colors,
                ),
              ],
            ),
          ),

          const Spacer(),

          LukoButton.primary(
            label: alreadyDone
                ? l10n.applyVerifyNextStep
                : l10n.applyVerifyStartButton,
            onPressed: onStart,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({
    required this.number,
    required this.label,
    required this.colors,
  });

  final int number;
  final String label;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colors.forestGreenSubtle,
            shape: BoxShape.circle,
            border: Border.all(color: colors.forestGreen.withValues(alpha: 0.4)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: textTheme.labelMedium?.copyWith(
              color: colors.forestGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(color: colors.primaryText),
        ),
      ],
    );
  }
}

// ── 拍照步驟頁 ────────────────────────────────────────────────────────────────

class _CaptureView extends StatelessWidget {
  const _CaptureView({
    required this.step,
    required this.colors,
    required this.l10n,
    required this.randomActions,
    required this.capturedPath,
    required this.onTakePhoto,
    required this.onRetake,
    required this.onNext,
  });

  final _VerifyStep step;
  final AppColors colors;
  final AppLocalizations l10n;
  final List<VerificationAction> randomActions;
  final String? capturedPath;
  final VoidCallback onTakePhoto;
  final VoidCallback onRetake;
  final VoidCallback? onNext;

  String _title() => switch (step) {
    _VerifyStep.frontFace => l10n.applyVerifyStepFrontTitle,
    _VerifyStep.sideFace  => l10n.applyVerifyStepSideTitle,
    _VerifyStep.action1   => l10n.applyVerifyStepActionTitle,
    _VerifyStep.action2   => l10n.applyVerifyStepActionTitle,
    _VerifyStep.intro     => '',
  };

  String _hint() => switch (step) {
    _VerifyStep.frontFace => l10n.applyVerifyStepFrontHint,
    _VerifyStep.sideFace  => l10n.applyVerifyStepSideHint,
    _VerifyStep.action1   => l10n.applyVerifyStepActionHint,
    _VerifyStep.action2   => l10n.applyVerifyStepActionHint,
    _VerifyStep.intro     => '',
  };

  String? _actionName() => switch (step) {
    _VerifyStep.action1 => randomActions[0].displayName(l10n),
    _VerifyStep.action2 => randomActions[1].displayName(l10n),
    _               => null,
  };

  IconData _icon() => switch (step) {
    _VerifyStep.frontFace => Icons.face_outlined,
    _VerifyStep.sideFace  => Icons.face_retouching_natural_outlined,
    _VerifyStep.action1   => Icons.waving_hand_outlined,
    _VerifyStep.action2   => Icons.waving_hand_outlined,
    _VerifyStep.intro     => Icons.camera_alt_outlined,
  };

  // 步驟編號（1~4，不含 intro）
  int get _stepNumber => switch (step) {
    _VerifyStep.frontFace => 1,
    _VerifyStep.sideFace  => 2,
    _VerifyStep.action1   => 3,
    _VerifyStep.action2   => 4,
    _VerifyStep.intro     => 0,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final actionName = _actionName();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),

          // ── 步驟指示點 ───────────────────────────────────────────
          _StepDots(current: _stepNumber, total: 4, colors: colors),
          const SizedBox(height: AppSpacing.xl),

          // ── 標題 ─────────────────────────────────────────────────
          Text(
            _title(),
            style: textTheme.headlineMedium?.copyWith(
              color: colors.primaryText,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _hint(),
            style: textTheme.bodyMedium?.copyWith(
              color: colors.secondaryText,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          // 動作名稱（action1 / action2 步驟才顯示）
          if (actionName != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colors.forestGreenSubtle,
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(color: colors.forestGreen.withValues(alpha: 0.4)),
              ),
              child: Text(
                actionName,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.forestGreen,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // ── 照片預覽 / 佔位 ──────────────────────────────────────
          Expanded(
            child: capturedPath != null
                ? _PhotoPreview(path: capturedPath!, colors: colors)
                : _PhotoPlaceholder(icon: _icon(), colors: colors),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── 操作按鈕 ──────────────────────────────────────────────
          if (capturedPath == null) ...[
            LukoButton.primary(
              label: l10n.applyVerifyTakePhoto,
              onPressed: onTakePhoto,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: LukoButton.secondary(
                    label: l10n.applyVerifyRetake,
                    onPressed: onRetake,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: LukoButton.primary(
                    label: step == _VerifyStep.action2
                        ? l10n.applyVerifyUploading.replaceFirst('...', '')
                        : l10n.applyVerifyNextStep,
                    onPressed: onNext,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ── 步驟指示點 ────────────────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  const _StepDots({
    required this.current,
    required this.total,
    required this.colors,
  });

  final int current;
  final int total;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i + 1 == current;
        final isDone   = i + 1 < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isDone || isActive
                ? colors.forestGreen
                : colors.divider,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ── 照片預覽 ──────────────────────────────────────────────────────────────────

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.path, required this.colors});
  final String path;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          color: colors.forestGreenSubtle,
          child: Icon(Icons.broken_image_outlined,
              color: colors.secondaryText, size: 40),
        ),
      ),
    );
  }
}

// ── 拍照佔位（尚未拍照時的示意區域）─────────────────────────────────────────────

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.icon, required this.colors});
  final IconData icon;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.divider, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: colors.secondaryText.withValues(alpha: 0.4)),
          const SizedBox(height: AppSpacing.sm),
          Icon(Icons.camera_alt_outlined,
              size: 24, color: colors.secondaryText.withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}
