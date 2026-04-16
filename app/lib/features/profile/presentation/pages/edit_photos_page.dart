import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/media_permission_helper.dart';
import '../../../../core/widgets/luko_button.dart';
import '../../../../l10n/app_localizations.dart';

// ── Photo slot sealed type ────────────────────────────────────────────────────
//
// ExistingSlot: already on Supabase Storage — only needs a signedUrl for display.
// NewSlot: picked locally — must be compressed, cropped, and uploaded on save.

sealed class PhotoSlot {}

class ExistingSlot extends PhotoSlot {
  ExistingSlot({required this.storagePath, required this.signedUrl});
  final String storagePath;
  final String signedUrl;
}

class NewSlot extends PhotoSlot {
  NewSlot({required this.localPath});
  final String localPath;
}

/// EditPhotosPage → EditReverifyPage 傳遞的資料容器。
///
/// 不在 EditPhotosPage 上傳，讓 EditReverifyPage 統一在最後「送出」時上傳，
/// 避免用戶放棄 reverify 時 Storage 產生孤兒檔案。
class PendingPhotoData {
  PendingPhotoData({required this.userId, required this.slots});
  final String userId;
  final List<PhotoSlot> slots; // 保留 display order
}

/// 管理照片頁
///
/// 路由：/me/edit/photos（push，從 EditProfilePage 進入）
///
/// 流程：
/// 1. 載入 profiles.photo_paths，為每張取得 signed URL
/// 2. 使用者可拖動排序、刪除現有照片、新增本機照片（壓縮 + 裁切）
/// 3. 點「儲存」：上傳新照片 → 更新 photo_paths + photo_pending_review=true → pop
class EditPhotosPage extends ConsumerStatefulWidget {
  const EditPhotosPage({super.key});

  @override
  ConsumerState<EditPhotosPage> createState() => _EditPhotosPageState();
}

class _EditPhotosPageState extends ConsumerState<EditPhotosPage>
    with WidgetsBindingObserver {
  static const int _minPhotos = 2;
  static const int _maxPhotos = 9;

  final _picker = ImagePicker();

  List<PhotoSlot> _slots = [];
  bool _isLoadingExisting = true;
  bool _isProcessing = false; // 壓縮 / 裁切中
  String? _error;

  DefaultAssetPickerProvider? _pickerProvider;
  DefaultAssetPickerBuilderDelegate? _pickerDelegate;
  PermissionState? _permissionState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingPhotos();
      _checkInitialPermission();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermissionOnResume();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pickerProvider?.dispose();
    super.dispose();
  }

  // ── 載入現有照片（取 signed URLs）─────────────────────────────────────────

  Future<void> _loadExistingPhotos() async {
    try {
      final supabase = ref.read(supabaseProvider);
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoadingExisting = false);
        return;
      }

      final row = await supabase
          .from('profiles')
          .select('photo_paths')
          .eq('id', userId)
          .maybeSingle();

      final paths = (row?['photo_paths'] as List?)?.cast<String>() ?? [];

      // profile-photos 是 public bucket，getPublicUrl 同步計算，URL 永久有效
      final slots = paths.map<PhotoSlot>((path) {
        final url = supabase.storage
            .from('profile-photos')
            .getPublicUrl(path);
        return ExistingSlot(storagePath: path, signedUrl: url);
      }).toList();

      if (mounted) setState(() { _slots = slots; _isLoadingExisting = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingExisting = false);
    }
  }

  // ── 相簿權限查詢 ───────────────────────────────────────────────────────────

  Future<void> _checkInitialPermission() async {
    try {
      final ps = await PhotoManager.getPermissionState(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.image,
            mediaLocation: false,
          ),
        ),
      );
      if (mounted) setState(() => _permissionState = ps);
    } catch (_) {}
  }

  Future<void> _refreshPermissionOnResume() async {
    try {
      final ps = await PhotoManager.getPermissionState(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.image,
            mediaLocation: false,
          ),
        ),
      );
      if (!mounted) return;
      if (ps != _permissionState) {
        setState(() => _permissionState = ps);
        _pickerDelegate = null;
        _pickerProvider = null;
      }
    } catch (_) {}
  }

  // ── 從相簿選取（wechat_assets_picker，持久 delegate）──────────────────────

  Future<void> _pickFromGallery() async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final locale = Localizations.localeOf(context);
    if (_slots.length >= _maxPhotos) return;

    final ps = _permissionState ??
        await PhotoManager.getPermissionState(
          requestOption: const PermissionRequestOption(
            androidPermission: AndroidPermission(
              type: RequestType.image,
              mediaLocation: false,
            ),
          ),
        );
    if (!mounted) return;

    if (ps == PermissionState.denied || ps == PermissionState.restricted) {
      _pickerDelegate = null;
      _pickerProvider = null;
      if (mounted) setState(() => _permissionState = ps);
      await MediaPermissionHelper.showPhotoDenied(context);
      return;
    }

    if (_pickerDelegate == null) {
      _pickerProvider = DefaultAssetPickerProvider(
        maxAssets: 1,
        requestType: RequestType.image,
      );
      _pickerDelegate = DefaultAssetPickerBuilderDelegate(
        provider: _pickerProvider!,
        initialPermission: ps,
        keepScrollOffset: true,
        pickerTheme: AssetPicker.themeData(colors.forestGreen),
        textDelegate: locale.languageCode == 'zh'
            ? const TraditionalChineseAssetPickerTextDelegate()
            : const EnglishAssetPickerTextDelegate(),
      );
    } else {
      _pickerProvider!.selectedAssets = [];
    }

    if (!mounted) return;
    List<AssetEntity>? result;
    try {
      result = await AssetPicker.pickAssetsWithDelegate(
        context,
        delegate: _pickerDelegate!,
      );
    } on StateError {
      _pickerDelegate = null;
      _pickerProvider = null;
      if (mounted) await MediaPermissionHelper.showPhotoDenied(context);
      return;
    } catch (_) {
      _pickerDelegate = null;
      _pickerProvider = null;
      return;
    }

    // 同步 picker 關閉後的最新權限狀態
    try {
      final updatedPs = await PhotoManager.getPermissionState(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.image,
            mediaLocation: false,
          ),
        ),
      );
      if (mounted && updatedPs != _permissionState) {
        setState(() => _permissionState = updatedPs);
        _pickerDelegate = null;
        _pickerProvider = null;
      }
    } catch (_) {}

    if (result == null || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      for (final entity in result) {
        if (_slots.length >= _maxPhotos) break;
        final file = await entity.originFile;
        if (file == null) continue;
        final compressed = await _compressToJpeg(file.path);
        if (compressed == null || !mounted) continue;
        final finalPath = (await _cropImage(compressed)) ?? compressed;
        setState(() => _slots.add(NewSlot(localPath: finalPath)));
      }
    } catch (e) {
      debugPrint('[EditPhotosPage] gallery pick/compress error: $e');
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context)!.commonError);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── 從相機拍照 ──────────────────────────────────────────────────────────────

  Future<void> _pickFromCamera() async {
    if (_slots.length >= _maxPhotos) return;

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
      setState(() => _slots.add(NewSlot(localPath: finalPath)));
    } catch (e) {
      debugPrint('[EditPhotosPage] camera pick/compress error: $e');
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context)!.commonError);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── 來源選擇 BottomSheet ──────────────────────────────────────────────────

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

  // ── 壓縮 + 裁切 ───────────────────────────────────────────────────────────

  Future<String?> _compressToJpeg(String sourcePath) async {
    final tmpDir = await getTemporaryDirectory();
    final ts = DateTime.now().microsecondsSinceEpoch;
    final targetPath = '${tmpDir.path}/luko_edit_photo_$ts.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath, targetPath,
      quality: 85, minWidth: 1080, minHeight: 1080,
      format: CompressFormat.jpeg,
    );
    return result?.path;
  }

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

  // ── 移除 / 排序 ────────────────────────────────────────────────────────────

  void _removeSlot(int index) {
    if (_slots.length <= _minPhotos) return; // 不得低於最少張數
    setState(() => _slots.removeAt(index));
  }

  void _reorderSlots(int fromIndex, int toIndex) {
    if (fromIndex == toIndex || fromIndex >= _slots.length) return;
    setState(() {
      final item = _slots.removeAt(fromIndex);
      _slots.insert(toIndex.clamp(0, _slots.length), item);
    });
  }

  // ── 下一步：把 slots 傳給 EditReverifyPage，由它統一上傳 + 更新 DB ──────────
  //
  // 不在這裡做任何 Storage 上傳——避免用戶放棄 reverify 時產生孤兒檔案。
  // EditReverifyPage 在最後一步「送出」時一次完成：
  //   上傳新照片 → 上傳 reverify 照片 → 更新 profiles
  //
  // Extra 型別：PendingPhotoData（含 slots 列表，依 display order）

  Future<void> _next() async {
    if (_slots.length < _minPhotos) return; // canNext 已守衛，保險用

    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    final extra = PendingPhotoData(
      userId: userId,
      slots: List.unmodifiable(_slots),
    );

    if (!mounted) return;
    context.push('/me/edit/photos/reverify', extra: extra);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final count = _slots.length;
    final canNext = count >= _minPhotos && !_isProcessing && !_isLoadingExisting;

    return Scaffold(
      backgroundColor: colors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: colors.backgroundWarm,
        surfaceTintColor: colors.backgroundWarm,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.editPhotosTitle,
          style: textTheme.titleMedium?.copyWith(
            color: colors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoadingExisting
          ? Center(
              child: CircularProgressIndicator(
                color: colors.forestGreen,
                strokeWidth: 2.5,
              ),
            )
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.lg),

                      Text(
                        l10n.editPhotosSubtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.secondaryText,
                        ),
                      ),

                      // iOS / Android 14 有限相簿存取橫幅
                      if (_permissionState == PermissionState.limited) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _LimitedBanner(
                          hint: l10n.applyPhotosLimitedHint,
                          colors: colors,
                          textTheme: textTheme,
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xl),

                      _MixedPhotoGrid(
                        slots: _slots,
                        minPhotos: _minPhotos,
                        maxPhotos: _maxPhotos,
                        isProcessing: _isProcessing,
                        colors: colors,
                        l10n: l10n,
                        onAddTap: count < _maxPhotos ? _showSourcePicker : null,
                        onRemove: _removeSlot,
                        onReorder: _reorderSlots,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // 格式 + 數量
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

                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _error!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ),
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
          child: LukoButton.primary(
            label: l10n.commonNext,
            onPressed: canNext ? _next : null,
          ),
        ),
      ),
    );
  }
}

// ── 混合照片 Grid（ExistingSlot = network，NewSlot = file）───────────────────
//
// 與 apply_photos_page 的 _DraggablePhotoGrid 結構相同，
// 差異在於已有照片使用 CachedNetworkImage，新照片使用 Image.file。

class _MixedPhotoGrid extends StatefulWidget {
  const _MixedPhotoGrid({
    required this.slots,
    required this.minPhotos,
    required this.maxPhotos,
    required this.isProcessing,
    required this.colors,
    required this.l10n,
    required this.onAddTap,
    required this.onRemove,
    required this.onReorder,
  });

  final List<PhotoSlot> slots;
  final int minPhotos;
  final int maxPhotos;
  final bool isProcessing;
  final AppColors colors;
  final AppLocalizations l10n;
  final VoidCallback? onAddTap;
  final void Function(int index) onRemove;
  final void Function(int fromIndex, int toIndex) onReorder;

  @override
  State<_MixedPhotoGrid> createState() => _MixedPhotoGridState();
}

class _MixedPhotoGridState extends State<_MixedPhotoGrid> {
  int? _draggingIndex;

  @override
  Widget build(BuildContext context) {
    final count = widget.slots.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: widget.maxPhotos,
      itemBuilder: (context, i) {
        if (i < count)        return _buildDraggableSlot(i);
        if (i == count)       return _buildActiveEmptySlot(i, count);
        return                       _buildInactiveEmptySlot();
      },
    );
  }

  Widget _buildDraggableSlot(int i) {
    final slot = widget.slots[i];
    final isDragging = _draggingIndex == i;
    final canRemove = widget.slots.length > widget.minPhotos;
    final slotWidth =
        (MediaQuery.of(context).size.width - 2 * AppSpacing.pagePadding - 16) / 3;

    return LongPressDraggable<int>(
      data: i,
      delay: const Duration(milliseconds: 300),
      onDragStarted: () => setState(() => _draggingIndex = i),
      onDragEnd: (_) => setState(() => _draggingIndex = null),
      onDraggableCanceled: (_, __) => setState(() => _draggingIndex = null),
      feedback: SizedBox(
        width: slotWidth,
        height: slotWidth,
        child: Opacity(
          opacity: 0.85,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: _SlotImage(slot: slot, colors: widget.colors),
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
                  ? Border.all(color: widget.colors.forestGreen, width: 2.5)
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: _FilledSlot(
                slot: slot,
                isDragging: isDragging,
                canRemove: canRemove,
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
                color: widget.colors.forestGreenSubtle,
                border: Border.all(
                  color: isHovered
                      ? widget.colors.forestGreen
                      : widget.colors.forestGreen.withValues(alpha: 0.5),
                  width: isHovered ? 2.5 : 1.5,
                ),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Center(
                child: widget.isProcessing && i == count
                    ? SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: widget.colors.forestGreen,
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded,
                              size: 26, color: widget.colors.forestGreen),
                          const SizedBox(height: 4),
                          Text(
                            widget.l10n.applyPhotosAddPhoto,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: widget.colors.forestGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInactiveEmptySlot() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.colors.forestGreenSubtle.withValues(alpha: 0.45),
            widget.colors.forestGreenSubtle.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: widget.colors.forestGreen.withValues(alpha: 0.15),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.add_photo_alternate_outlined,
          size: 22,
          color: widget.colors.forestGreen.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

// ── 已填入格子 ────────────────────────────────────────────────────────────────

class _FilledSlot extends StatelessWidget {
  const _FilledSlot({
    required this.slot,
    required this.isDragging,
    required this.canRemove,
    required this.onRemove,
    required this.colors,
  });

  final PhotoSlot slot;
  final bool isDragging;
  final bool canRemove; // false when at minimum count
  final VoidCallback onRemove;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _SlotImage(slot: slot, colors: colors),
        // 長按拖動提示（左下角）
        Positioned(
          left: 6, bottom: 6,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.drag_indicator_rounded,
              color: Colors.white, size: 14,
            ),
          ),
        ),
        // 右上角移除按鈕（張數已達最少時隱藏）
        if (canRemove)
          Positioned(
            top: 6, right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white, size: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── 依 slot 類型渲染圖片 ──────────────────────────────────────────────────────
//
// ExistingSlot → CachedNetworkImage（已有 signed URL）
// NewSlot      → Image.file（本機暫存路徑）

class _SlotImage extends StatelessWidget {
  const _SlotImage({required this.slot, required this.colors});

  final PhotoSlot slot;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    switch (slot) {
      case final ExistingSlot existing:
        return CachedNetworkImage(
          imageUrl: existing.signedUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: colors.forestGreenSubtle,
            child: Center(
              child: CircularProgressIndicator(
                color: colors.forestGreen, strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            color: colors.forestGreenSubtle,
            child: Icon(
              Icons.broken_image_outlined,
              color: colors.secondaryText, size: 24,
            ),
          ),
        );
      case final NewSlot newPhoto:
        return Image.file(
          File(newPhoto.localPath),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: colors.forestGreenSubtle,
            child: Icon(
              Icons.broken_image_outlined,
              color: colors.secondaryText, size: 24,
            ),
          ),
        );
    }
  }
}

// ── 有限相簿存取橫幅 ──────────────────────────────────────────────────────────

class _LimitedBanner extends StatelessWidget {
  const _LimitedBanner({
    required this.hint,
    required this.colors,
    required this.textTheme,
  });

  final String hint;
  final AppColors colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.forestGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: colors.forestGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.photo_library_outlined,
              size: 16, color: colors.forestGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              style: textTheme.bodySmall?.copyWith(color: colors.secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}
