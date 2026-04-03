import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/supabase/supabase_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/media_permission_helper.dart';
import '../../../../../core/widgets/luko_button.dart';
import '../../../../../core/widgets/luko_loading_overlay.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../providers/apply_provider.dart';

// ── 平台設定提醒 ──────────────────────────────────────────────────────────────
//
// iOS  (ios/Runner/Info.plist)：
//   NSPhotoLibraryUsageDescription  → "Luko 需要存取相簿以上傳申請照片"
//   NSCameraUsageDescription        → "Luko 需要存取相機以拍攝申請照片"
//   NSPhotoLibraryAddUsageDescription → "Luko 需要存取相簿"
//
// Android (android/app/src/main/AndroidManifest.xml)：
//   已在 <application> 內宣告 UCropActivity（image_cropper 所需）
//   API 33+ 相簿/相機權限由 photo_manager (wechat_assets_picker) 自動處理
// ─────────────────────────────────────────────────────────────────────────────

/// 申請 Step 3 — 照片上傳
///
/// 路由：/apply/photos（正式）或 /dev/apply-photos（開發測試）
///
/// 功能：
/// - 從相簿（wechat_assets_picker，記憶上次位置）或相機選取照片
/// - 壓縮至 JPEG（flutter_image_compress）+ 裁切（image_cropper）
/// - 長按格子拖動調整順序（LongPressDraggable + DragTarget）
/// - 最少 2 張，最多 9 張
/// - 點「下一步」批次上傳至 Supabase Storage，然後進入 Step 4 真人認證
class ApplyPhotosPage extends ConsumerStatefulWidget {
  const ApplyPhotosPage({super.key, this.isDevMode = false});

  /// true → back 回 /dev/apply-info，next 跳 /dev/apply-verify，並跳過 Supabase 上傳
  final bool isDevMode;

  @override
  ConsumerState<ApplyPhotosPage> createState() => _ApplyPhotosPageState();
}

class _ApplyPhotosPageState extends ConsumerState<ApplyPhotosPage> {
  static const int _minPhotos = 2;
  static const int _maxPhotos = 9;

  final _picker = ImagePicker();

  /// 已壓縮的本機 JPEG 暫存路徑（順序 = display_order）
  List<String> _localPaths = [];

  /// wechat_assets_picker 上次選取的 AssetEntity（用於再次開啟時 scroll 回原位）
  List<AssetEntity> _lastSelectedEntities = [];

  bool _isProcessing = false; // 壓縮 / 裁切中
  bool _isUploading = false;  // 上傳中
  String? _error;

  @override
  void initState() {
    super.initState();
    _localPaths = List.from(ref.read(applyFormProvider).localPhotoPaths);
  }

  // ── 從相簿選取（wechat_assets_picker，多選，記憶位置）──────────────────────

  Future<void> _pickFromGallery() async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final remaining = _maxPhotos - _localPaths.length;
    if (remaining <= 0) return;

    // AssetPicker 內部已處理系統原生權限請求，不需預先 requestPermissionExtend()。
    // 只在永久拒絕時（StateError）才攔截，引導用戶前往設定。
    List<AssetEntity>? result;
    try {
      result = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          maxAssets: 1,
          selectedAssets: _lastSelectedEntities,
          requestType: RequestType.image,
          themeColor: colors.forestGreen,
          textDelegate: Localizations.localeOf(context).languageCode == 'zh'
              ? const TraditionalChineseAssetPickerTextDelegate()
              : const EnglishAssetPickerTextDelegate(),
          keepScrollOffset: true,
          dragToSelect: false,
        ),
      );
    } on StateError {
      if (mounted) await MediaPermissionHelper.showPhotoDenied(context);
      return;
    }
    if (result == null || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      for (final entity in result) {
        if (_localPaths.length >= _maxPhotos) break;
        final file = await entity.originFile;
        if (file == null) continue;

        final compressed = await _compressToJpeg(file.path);
        if (compressed == null || !mounted) continue;

        // 單張時提供裁切，多張批次跳過裁切
        final finalPath = result.length == 1
            ? (await _cropImage(compressed)) ?? compressed
            : compressed;

        setState(() => _localPaths.add(finalPath));
      }
      _lastSelectedEntities = result;
      ref.read(applyFormProvider.notifier).setLocalPhotos(List.from(_localPaths));
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.commonError);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── 從相機拍照（單張，含裁切）──────────────────────────────────────────────

  Future<void> _pickFromCamera() async {
    if (_localPaths.length >= _maxPhotos) return;

    XFile? file;
    try {
      file = await _picker.pickImage(source: ImageSource.camera);
    } catch (_) {
      if (mounted) await MediaPermissionHelper.showCameraDenied(context);
      return;
    }
    if (file == null || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      final compressed = await _compressToJpeg(file.path);
      if (compressed == null || !mounted) return;

      final finalPath = (await _cropImage(compressed)) ?? compressed;

      setState(() => _localPaths.add(finalPath));
      ref.read(applyFormProvider.notifier).setLocalPhotos(List.from(_localPaths));
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.commonError);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── 來源選擇 BottomSheet ──────────────────────────────────────────────────────

  Future<void> _showSourcePicker() async {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;

    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: colors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.applyPhotosFromGallery),
              onTap: () => Navigator.of(ctx).pop('gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.applyPhotosFromCamera),
              onTap: () => Navigator.of(ctx).pop('camera'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == 'gallery') await _pickFromGallery();
    if (source == 'camera') await _pickFromCamera();
  }

  // ── 壓縮並轉為 JPEG ───────────────────────────────────────────────────────────

  Future<String?> _compressToJpeg(String sourcePath) async {
    final tmpDir = await getTemporaryDirectory();
    final ts = DateTime.now().microsecondsSinceEpoch;
    final targetPath = '${tmpDir.path}/luko_photo_$ts.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      targetPath,
      quality: 85,
      minWidth: 1080,
      minHeight: 1080,
      format: CompressFormat.jpeg,
    );
    return result?.path;
  }

  // ── 裁切（使用 image_cropper 原生 UI）────────────────────────────────────────

  Future<String?> _cropImage(String sourcePath) async {
    final colors = Theme.of(context).extension<AppColors>()!;

    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁切照片',
          toolbarColor: colors.brandBg,
          toolbarWidgetColor: colors.brandOnDark,
          statusBarLight: false,
          backgroundColor: colors.brandBg,
          cropGridColor: colors.brandOnDark.withValues(alpha: 0.3),
          cropFrameColor: colors.brandOnDark,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
          dimmedLayerColor: Colors.black.withValues(alpha: 0.7),
        ),
        IOSUiSettings(
          title: '裁切照片',
          doneButtonTitle: '完成',
          cancelButtonTitle: '取消',
          aspectRatioLockEnabled: false,
          resetButtonHidden: false,
          rotateButtonsHidden: false,
        ),
      ],
    );
    return cropped?.path;
  }

  // ── 移除照片 ───────────────────────────────────────────────────────────────

  void _removePhoto(int index) {
    setState(() => _localPaths.removeAt(index));
    ref.read(applyFormProvider.notifier).setLocalPhotos(List.from(_localPaths));
  }

  // ── 拖動排序 ───────────────────────────────────────────────────────────────

  void _reorderPhotos(int fromIndex, int toIndex) {
    if (fromIndex == toIndex || fromIndex >= _localPaths.length) return;
    setState(() {
      final item = _localPaths.removeAt(fromIndex);
      final insertAt = toIndex.clamp(0, _localPaths.length);
      _localPaths.insert(insertAt, item);
    });
    ref.read(applyFormProvider.notifier).setLocalPhotos(List.from(_localPaths));
  }

  // ── 上傳並前進 ─────────────────────────────────────────────────────────────

  Future<void> _onNext() async {
    if (_localPaths.length < _minPhotos) return;

    if (widget.isDevMode) {
      context.go('/dev/apply-verify');
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      final supabase = ref.read(supabaseProvider);
      final userId = supabase.auth.currentUser!.id;
      final uploadedPaths = <String>[];

      for (int i = 0; i < _localPaths.length; i++) {
        final bytes = await File(_localPaths[i]).readAsBytes();
        final ts = DateTime.now().millisecondsSinceEpoch;
        final storagePath = '$userId/${ts}_$i.jpg';

        await supabase.storage
            .from('application-photos')
            .uploadBinary(
              storagePath,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );

        uploadedPaths.add(storagePath);
      }

      ref.read(applyFormProvider.notifier).setUploadedPhotos(uploadedPaths);
      if (!mounted) return;
      context.go('/apply/verify');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _error = AppLocalizations.of(context)!.commonError;
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final count = _localPaths.length;
    final canProceed = count >= _minPhotos && !_isProcessing;

    return LukoLoadingOverlay(
      isLoading: _isUploading,
      message: l10n.applyPhotosUploading,
      child: Scaffold(
        backgroundColor: colors.backgroundWarm,
        appBar: AppBar(
          backgroundColor: colors.backgroundWarm,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.go(
              widget.isDevMode ? '/dev/apply-info' : '/apply/info',
            ),
          ),
          title: Text(
            l10n.applyStep(3, 6),
            style: textTheme.labelMedium?.copyWith(color: colors.secondaryText),
          ),
          centerTitle: true,
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // ── 標題 ──────────────────────────────────────────────
                  Text(
                    l10n.applyPhotosTitle,
                    style: textTheme.headlineMedium?.copyWith(
                      color: colors.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.applyPhotosSubtitle,
                    style: textTheme.bodyMedium?.copyWith(color: colors.secondaryText),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── 9 格可拖動照片 Grid ────────────────────────────────
                  _DraggablePhotoGrid(
                    localPaths: _localPaths,
                    maxPhotos: _maxPhotos,
                    isProcessing: _isProcessing,
                    colors: colors,
                    l10n: l10n,
                    onAddTap: count < _maxPhotos ? _showSourcePicker : null,
                    onRemove: _removePhoto,
                    onReorder: _reorderPhotos,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── 底部提示列 ─────────────────────────────────────────
                  Row(
                    children: [
                      Text(
                        'JPG · PNG · HEIC',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.secondaryText,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$count / $_maxPhotos',
                        style: textTheme.bodySmall?.copyWith(
                          color: count >= _minPhotos
                              ? colors.forestGreen
                              : colors.secondaryText,
                          fontWeight: count >= _minPhotos
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),

                  // ── 錯誤訊息 ──────────────────────────────────────────
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
        ),

        // ── 底部按鈕 ────────────────────────────────────────────────────
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.sm,
              AppSpacing.pagePadding,
              AppSpacing.md,
            ),
            child: LukoButton.primary(
              label: l10n.commonNext,
              onPressed: canProceed ? _onNext : null,
              isLoading: _isUploading,
            ),
          ),
        ),
      ),
    );
  }
}

// ── 可拖動照片 Grid ────────────────────────────────────────────────────────────
//
// 每個有照片的格子都是 LongPressDraggable（長按啟動拖動）+ DragTarget（接受放下）。
// 空格子只作為 DragTarget（拖到最後空位可移動照片順序）。

class _DraggablePhotoGrid extends StatefulWidget {
  const _DraggablePhotoGrid({
    required this.localPaths,
    required this.maxPhotos,
    required this.isProcessing,
    required this.colors,
    required this.l10n,
    required this.onAddTap,
    required this.onRemove,
    required this.onReorder,
  });

  final List<String> localPaths;
  final int maxPhotos;
  final bool isProcessing;
  final AppColors colors;
  final AppLocalizations l10n;
  final VoidCallback? onAddTap;
  final void Function(int index) onRemove;
  final void Function(int from, int to) onReorder;

  @override
  State<_DraggablePhotoGrid> createState() => _DraggablePhotoGridState();
}

class _DraggablePhotoGridState extends State<_DraggablePhotoGrid> {
  int? _draggingIndex;

  @override
  Widget build(BuildContext context) {
    const crossAxisCount = 3;
    const spacing = 8.0;
    final count = widget.localPaths.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: widget.maxPhotos,
      itemBuilder: (_, i) {
        if (i < count) {
          // ── 有照片的格子：Draggable + DragTarget ────────────────────
          return _buildFilledSlot(i, count);
        } else if (i == count && count < widget.maxPhotos) {
          // ── 下一個空格（活躍）：DragTarget + 點擊新增 ────────────────
          return _buildActiveEmptySlot(i, count);
        } else {
          // ── 其餘空格（不活躍）────────────────────────────────────────
          return ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: _EmptySlot(
              isNext: false,
              isProcessing: false,
              colors: widget.colors,
              l10n: widget.l10n,
            ),
          );
        }
      },
    );
  }

  Widget _buildFilledSlot(int i, int count) {
    final path = widget.localPaths[i];
    final isDragging = _draggingIndex == i;

    return LongPressDraggable<int>(
      key: ValueKey(path),
      data: i,
      delay: const Duration(milliseconds: 300),
      onDragStarted: () => setState(() => _draggingIndex = i),
      onDragEnd: (_) => setState(() => _draggingIndex = null),
      onDraggableCanceled: (_, __) => setState(() => _draggingIndex = null),
      feedback: SizedBox(
        width: 100, height: 100,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Image.file(File(path), fit: BoxFit.cover),
          ),
        ),
      ),
      childWhenDragging: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          decoration: BoxDecoration(
            color: widget.colors.forestGreenSubtle,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: widget.colors.forestGreen.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
        ),
      ),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (d) => d.data != i,
        onAcceptWithDetails: (d) => widget.onReorder(d.data, i),
        builder: (context, candidateData, _) {
          final isHovered = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: isHovered
                  ? Border.all(
                      color: widget.colors.forestGreen,
                      width: 2.5,
                    )
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: _FilledSlot(
                localPath: path,
                isDragging: isDragging,
                onRemove: () => widget.onRemove(i),
                colors: widget.colors,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveEmptySlot(int i, int count) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => true,
      onAcceptWithDetails: (d) => widget.onReorder(d.data, i),
      builder: (context, candidateData, _) {
        final isHovered = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: widget.onAddTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isHovered
                    ? widget.colors.forestGreenSubtle
                    : widget.colors.forestGreenSubtle,
                border: Border.all(
                  color: isHovered
                      ? widget.colors.forestGreen
                      : widget.colors.forestGreen.withValues(alpha: 0.5),
                  width: isHovered ? 2.5 : 1.5,
                ),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: _EmptySlot(
                isNext: true,
                isProcessing: widget.isProcessing && i == count,
                colors: widget.colors,
                l10n: widget.l10n,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── 已填入照片的格子 ──────────────────────────────────────────────────────────

class _FilledSlot extends StatelessWidget {
  const _FilledSlot({
    required this.localPath,
    required this.isDragging,
    required this.onRemove,
    required this.colors,
  });

  final String localPath;
  final bool isDragging;
  final VoidCallback? onRemove;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          File(localPath),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: colors.forestGreenSubtle,
            child: Icon(Icons.broken_image_outlined,
                color: colors.secondaryText, size: 24),
          ),
        ),
        // 長按拖動提示（左下角）
        Positioned(
          left: 6,
          bottom: 6,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.drag_indicator_rounded,
                color: Colors.white, size: 14),
          ),
        ),
        // 右上角移除按鈕
        if (onRemove != null)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 14),
              ),
            ),
          ),
      ],
    );
  }
}

// ── 空格子 ────────────────────────────────────────────────────────────────────

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({
    required this.isNext,
    required this.isProcessing,
    required this.colors,
    required this.l10n,
  });

  final bool isNext;
  final bool isProcessing;
  final AppColors colors;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final iconColor = isNext
        ? colors.forestGreen
        : colors.secondaryText.withValues(alpha: 0.4);

    return Center(
      child: isProcessing
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.forestGreen,
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 26, color: iconColor),
                if (isNext) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.applyPhotosAddPhoto,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.forestGreen,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ],
            ),
    );
  }
}
