import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/supabase/supabase_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/media_permission_helper.dart';
import '../../../../../core/widgets/luko_button.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/app_user_status.dart';
import '../../../providers/apply_provider.dart';
import '../../../providers/auth_provider.dart';

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

class _ApplyPhotosPageState extends ConsumerState<ApplyPhotosPage>
    with WidgetsBindingObserver {
  static const int _minPhotos = 2;
  static const int _maxPhotos = 9;

  final _picker = ImagePicker();

  /// 已壓縮的本機 JPEG 暫存路徑（順序 = display_order）
  List<String> _localPaths = [];

  /// 持久化的 picker provider / delegate，讓 keepScrollOffset 真正跨次呼叫生效。
  /// pickAssetsWithDelegate() 不會 dispose delegate，捲動位置因此得以保留。
  DefaultAssetPickerProvider? _pickerProvider;
  DefaultAssetPickerBuilderDelegate? _pickerDelegate;

  bool _isProcessing  = false; // 壓縮 / 裁切中
  bool _isDownloading = false; // 重新申請：從 Storage 下載已有照片中
  String? _error;

  /// 最近一次取得的相簿權限狀態，用於判斷是否顯示「有限存取」提示橫幅
  PermissionState? _permissionState;

  @override
  void initState() {
    super.initState();
    _localPaths = List.from(ref.read(applyFormProvider).localPhotoPaths);
    WidgetsBinding.instance.addObserver(this);
    // addPostFrameCallback 確保 widget 完全 mount 後才查詢權限。
    // 使用 getPermissionState()（純查詢，不觸發系統彈窗）取代
    // requestPermissionExtend()，避免 Android 14 雙重請求導致回傳
    // 舊快取 limited 狀態的問題。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkInitialPermission();

      // 重新申請：localPhotoPaths 為空但有已上傳路徑 → 從 Storage 下載以預覽
      final form = ref.read(applyFormProvider);
      if (_localPaths.isEmpty && form.uploadedPhotoPaths.isNotEmpty) {
        _downloadExistingPhotos(form.uploadedPhotoPaths);
      }
    });
  }

  /// App 從背景回到前台時（用戶可能剛在 Settings 更改過照片權限），
  /// 重新查詢並同步 UI 狀態。若權限有變動則同時重置 stale delegate，
  /// 確保下次開啟 picker 時以最新權限重建。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissionOnResume();
    }
  }

  Future<void> _refreshPermissionOnResume() async {
    try {
      // 從設定頁回來：使用純查詢，不再彈一次系統授權對話框。
      // getPermissionState() 直接讀取目前系統授予的狀態，
      // 包含用戶在設定裡把「有限存取」改為「允許全部」的情境。
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
        // 權限已變動，delegate 快取的 initialPermission 已過時，強制重建
        _pickerDelegate = null;
        _pickerProvider = null;
      }
    } catch (_) {
      // 查詢失敗不中斷流程
    }
  }

  /// 初始查詢：純讀取目前系統狀態，不觸發授權彈窗。
  ///
  /// 設計原則：
  /// - `getPermissionState()` 是非侵入式查詢，不會彈出系統對話框。
  /// - 真正的授權彈窗由 `AssetPicker.pickAssetsWithDelegate()` 在用戶
  ///   主動點擊「從相簿選取」時由 picker 自行觸發，時機更自然。
  /// - 避免 Android 14 雙重呼叫問題：initState postFrameCallback 呼叫
  ///   requestPermissionExtend() 後，_pickFromGallery() 內部再次呼叫，
  ///   Activity permission result callback 不保證順序，可能回傳舊快取
  ///   limited 狀態，即使用戶已授予完整存取（READ_MEDIA_IMAGES）亦然。
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
    } catch (_) {
      // 查詢失敗不影響 UI，用戶仍可手動開啟 picker
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pickerProvider?.dispose();
    super.dispose();
  }

  // ── 從相簿選取（wechat_assets_picker，持久 delegate，記憶捲動位置）──────────

  Future<void> _pickFromGallery() async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final locale = Localizations.localeOf(context); // context 在 await 前擷取
    if (_localPaths.length >= _maxPhotos) return;

    // 使用快取的 _permissionState（由 _checkInitialPermission 或
    // _refreshPermissionOnResume 以 getPermissionState() 純查詢取得）。
    //
    // 若尚未初始化（理論上極少發生），才做一次 getPermissionState() fallback。
    // 不使用 requestPermissionExtend() 的原因：
    //   picker 本身已會在開啟時觸發系統授權彈窗；
    //   若此處再呼叫 requestPermissionExtend()，Android 14 的雙重請求
    //   可能使 Activity permission result 順序錯亂，回傳 limited 舊快取，
    //   即使用戶已授予完整 READ_MEDIA_IMAGES 亦然。
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

    // 明確被永久拒絕才顯示引導 Dialog；同時清除快取，讓用戶改設定後可重試。
    if (ps == PermissionState.denied || ps == PermissionState.restricted) {
      _pickerDelegate = null;
      _pickerProvider = null;
      if (mounted) setState(() => _permissionState = ps);
      await MediaPermissionHelper.showPhotoDenied(context);
      return;
    }

    // 首次建立，或 delegate 已被重置（權限變動後）
    if (_pickerDelegate == null) {
      _pickerProvider = DefaultAssetPickerProvider(
        maxAssets: 1,
        requestType: RequestType.image,
      );
      _pickerDelegate = DefaultAssetPickerBuilderDelegate(
        provider: _pickerProvider!,
        // 直接傳入實際的 ps：
        // - authorized → 正常，無橫幅
        // - limited    → 顯示 picker 內建「有限存取」橫幅，用戶可在 picker 裡
        //                直接點「管理」追加照片，不必退出再找外層橫幅
        // - notDetermined → picker 會自行觸發系統授權彈窗
        initialPermission: ps,
        keepScrollOffset: true,
        pickerTheme: AssetPicker.themeData(colors.forestGreen),
        textDelegate: locale.languageCode == 'zh'
            ? const TraditionalChineseAssetPickerTextDelegate()
            : const EnglishAssetPickerTextDelegate(),
      );
    } else {
      // 再次開啟：清除上次選取，讓挑選器以無勾選狀態開啟
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
      // StateError = picker 偵測到權限被拒，清除 delegate 讓下次重新請求
      _pickerDelegate = null;
      _pickerProvider = null;
      if (mounted) await MediaPermissionHelper.showPhotoDenied(context);
      return;
    } catch (_) {
      // 其他例外（delegate 已 disposed 等），重置讓用戶可以重試
      _pickerDelegate = null;
      _pickerProvider = null;
      return;
    }

    // picker 關閉後，以純查詢同步最新狀態：
    // 用戶可能在 picker 內點「管理」並將 limited → authorized，
    // 若狀態有變化需同步更新外層橫幅，並重置 delegate 讓下次以新狀態重建。
    // 同樣使用 getPermissionState() 而非 requestPermissionExtend()，
    // 避免 picker 剛關閉時的競爭條件。
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
    } catch (_) {
      // 查詢失敗不影響照片處理流程
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

        final finalPath = (await _cropImage(compressed)) ?? compressed;

        setState(() => _localPaths.add(finalPath));
      }
      final n = ref.read(applyFormProvider.notifier);
      n.setLocalPhotos(List.from(_localPaths));
      n.setUploadedPhotos([]); // 照片已修改，確認頁須重新上傳
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
      final n = ref.read(applyFormProvider.notifier);
      n.setLocalPhotos(List.from(_localPaths));
      n.setUploadedPhotos([]); // 照片已修改，確認頁須重新上傳
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
    final n = ref.read(applyFormProvider.notifier);
    n.setLocalPhotos(List.from(_localPaths));
    n.setUploadedPhotos([]); // 照片已修改，確認頁須重新上傳
  }

  // ── 拖動排序 ───────────────────────────────────────────────────────────────

  void _reorderPhotos(int fromIndex, int toIndex) {
    if (fromIndex == toIndex || fromIndex >= _localPaths.length) return;
    setState(() {
      final item = _localPaths.removeAt(fromIndex);
      final insertAt = toIndex.clamp(0, _localPaths.length);
      _localPaths.insert(insertAt, item);
    });
    final n = ref.read(applyFormProvider.notifier);
    n.setLocalPhotos(List.from(_localPaths));
    n.setUploadedPhotos([]); // 順序已修改，確認頁須重新上傳
  }

  // ── 重新申請：從 Storage 下載已有照片，還原為本機暫存路徑 ──────────────────
  //
  // 目的：讓照片格顯示之前上傳的照片（維持原順序），使用者可以直接預覽、
  // 拖動排序或刪除，體驗與首次申請完全一致。
  // 下載完成後同步更新 provider 的 localPhotoPaths，供 confirm 頁預覽使用。
  // 若部分照片下載失敗則跳過，不中斷整體流程。

  Future<void> _downloadExistingPhotos(List<String> storagePaths) async {
    setState(() => _isDownloading = true);

    try {
      final supabase = ref.read(supabaseProvider);
      final tmpDir   = await getTemporaryDirectory();
      final ts       = DateTime.now().millisecondsSinceEpoch;

      // 並行下載所有照片，總時間 ≈ 最慢的單張（而非所有張數加總）
      final futures = List.generate(storagePaths.length, (i) async {
        try {
          final bytes = await supabase.storage
              .from('application-photos')
              .download(storagePaths[i]);
          final localPath = '${tmpDir.path}/luko_reapply_${ts}_$i.jpg';
          await File(localPath).writeAsBytes(bytes);
          return localPath;
        } catch (e) {
          debugPrint('Reapply photo download [$i] failed: $e');
          return null; // 單張失敗回傳 null，不中斷其餘下載
        }
      });

      final results = await Future.wait(futures);
      // 過濾失敗項目，保留原始順序
      final localPaths = results.whereType<String>().toList();

      if (!mounted) return;
      setState(() {
        _localPaths     = localPaths;
        _isDownloading  = false;
      });
      // 更新 provider，讓 confirm 頁也能看到照片預覽
      ref.read(applyFormProvider.notifier).setLocalPhotos(List.from(_localPaths));
    } catch (e) {
      debugPrint('Reapply photo download error: $e');
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  // ── 上傳並前進 ─────────────────────────────────────────────────────────────
  //
  // 修正重點：
  // 1. Storage path 必須是 `{uid}/photos/{timestamp}_{index}.jpg`
  //    RLS policy 以 (storage.foldername(name))[1] 比對 auth.uid()，
  //    foldername 回傳的是「第一層目錄」，所以路徑第一段必須等於 uid。
  //    原本路徑 `$userId/${ts}_$i.jpg` 本身格式正確，
  //    但 404 代表 bucket 不存在或未建立；改用 upsert:true 避免重複上傳時衝突。
  //
  // 2. 加入 upsert: true，重新進入此頁後不會因檔名重複而 403。
  //
  // 3. 改為固定 session 時間戳 + 索引，避免同一次上傳因毫秒差異命名不一致。
  //
  // 4. 加入更詳細的錯誤分類，方便 debug。

  // 照片不在此頁上傳；所有上傳集中在 Step 6（apply_confirm_page.dart）的送出時處理
  void _onNext(bool isBetaMode) {
    if (widget.isDevMode) {
      context.go('/dev/apply-verify');
      return;
    }
    context.go(isBetaMode ? '/apply/bio' : '/apply/verify');
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final count = _localPaths.length;
    final existingPaths = ref.watch(applyFormProvider).uploadedPhotoPaths;

    final isBetaMode = ref.watch(appUserStatusProvider).when(
      data: (s) => s == AppUserStatus.betaOnboarding,
      loading: () => false,
      error: (_, __) => false,
    );

    // Beta 模式：不需要照片，直接允許前進
    // 正式模式：已有新選照片（≥2）或重新申請保留舊路徑；下載 / 壓縮中停用
    final canProceed = isBetaMode ||
        ((count >= _minPhotos || existingPaths.isNotEmpty)
        && !_isProcessing
        && !_isDownloading);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(widget.isDevMode ? '/dev/apply-info' : '/apply/info');
      },
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
            isBetaMode ? l10n.applyStep(2, 3) : l10n.applyStep(3, 6),
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

                  // ── Beta 模式：顯示鎖定的既有照片 ──────────────────────
                  if (isBetaMode)
                    _BetaPhotosCard(
                      localPaths: _localPaths,
                      isLoading: _isDownloading,
                      colors: colors,
                      l10n: l10n,
                      textTheme: textTheme,
                    )
                  else ...[
                    // ── 重新申請：下載失敗後的 fallback 橫幅 ────────────────
                    // 下載中（_isDownloading）改以 Grid 內 spinner 表達，不顯示橫幅
                    if (existingPaths.isNotEmpty && _localPaths.isEmpty && !_isDownloading) ...[
                      _ExistingPhotosBanner(
                        count: existingPaths.length,
                        colors: colors,
                        textTheme: textTheme,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    // ── 有限存取提示橫幅（僅在確認為 limited 時顯示）────────
                    // _permissionState == null 表示尚未查詢完成，不顯示橫幅
                    // _permissionState == authorized 表示完整權限，不顯示
                    // _permissionState == limited 才顯示（iOS 或 Android 14 部分存取）
                    if (_permissionState == PermissionState.limited) ...[
                      _LimitedAccessBanner(
                        hint: l10n.applyPhotosLimitedHint,
                        colors: colors,
                        textTheme: textTheme,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    // ── 9 格可拖動照片 Grid（或下載中 spinner）────────────────
                    // 重新申請時先從 Storage 下載照片（_isDownloading），
                    // 完成後才渲染可操作的 Grid，避免空格子誤導用戶重新上傳。
                    if (_isDownloading)
                      SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: colors.forestGreen,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    else
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
              onPressed: canProceed ? () => _onNext(isBetaMode) : null,
            ),
          ),
        ),
      ), // Scaffold
    );   // PopScope
  }
}

// ── Beta 模式：照片鎖定卡片（顯示現有照片 + 鎖定說明）────────────────────────────

class _BetaPhotosCard extends StatelessWidget {
  const _BetaPhotosCard({
    required this.localPaths,
    required this.isLoading,
    required this.colors,
    required this.l10n,
    required this.textTheme,
  });

  final List<String> localPaths;
  final bool isLoading;
  final AppColors colors;
  final AppLocalizations l10n;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 鎖定說明橫幅
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.lock_outline_rounded, size: 16,
                    color: colors.secondaryText),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.betaApplyPhotosLockedBody,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.secondaryText, height: 1.5,
                  ),
                ),
              ),
            ],
          ),

          if (isLoading) ...[
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: SizedBox(
                width: 28, height: 28,
                child: CircularProgressIndicator(
                  color: colors.forestGreen, strokeWidth: 2.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ] else if (localPaths.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _LockedPhotoGrid(localPaths: localPaths, colors: colors),
          ],
        ],
      ),
    );
  }
}

// ── Beta 模式：唯讀照片格（不可新增 / 刪除 / 拖動）────────────────────────────────

class _LockedPhotoGrid extends StatelessWidget {
  const _LockedPhotoGrid({required this.localPaths, required this.colors});

  final List<String> localPaths;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: localPaths.length,
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Image.file(
          File(localPaths[i]),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: colors.forestGreenSubtle,
            child: Icon(Icons.broken_image_outlined,
                color: colors.secondaryText, size: 20),
          ),
        ),
      ),
    );
  }
}

// ── 可拖動照片 Grid ────────────────────────────────────────────────────────────
//
// 每個有照片的格子都是 LongPressDraggable（長按啟動拖動）+ DragTarget（接受放下）。
// 空格子是純 DragTarget（只接受，不發射）。
// 順序規則：拖到目標格子時，fromIndex 的照片插入 toIndex 位置，其他往後移。

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
  final void Function(int fromIndex, int toIndex) onReorder;

  @override
  State<_DraggablePhotoGrid> createState() => _DraggablePhotoGridState();
}

class _DraggablePhotoGridState extends State<_DraggablePhotoGrid> {
  int? _draggingIndex;

  @override
  Widget build(BuildContext context) {
    final count = widget.localPaths.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      // 永遠顯示全部 9 格：已填格 + 1 個可點擊加號格 + 其餘灰階佔位格
      itemCount: widget.maxPhotos,
      itemBuilder: (context, i) {
        if (i < count) {
          return _buildDraggableSlot(i, count);  // 已有照片
        } else if (i == count) {
          return _buildActiveEmptySlot(i, count); // 下一個可新增格（含 + 按鈕）
        } else {
          return _buildInactiveEmptySlot();        // 視覺佔位格（不可互動）
        }
      },
    );
  }

  Widget _buildDraggableSlot(int i, int count) {
    final path = widget.localPaths[i];
    final isDragging = _draggingIndex == i;

    return LongPressDraggable<int>(
      data: i,
      delay: const Duration(milliseconds: 300),
      onDragStarted: () => setState(() => _draggingIndex = i),
      onDragEnd: (_) => setState(() => _draggingIndex = null),
      onDraggableCanceled: (_, __) => setState(() => _draggingIndex = null),
      feedback: SizedBox(
        width: (MediaQuery.of(context).size.width - 2 * AppSpacing.pagePadding - 16) / 3,
        height: (MediaQuery.of(context).size.width - 2 * AppSpacing.pagePadding - 16) / 3,
        child: Opacity(
          opacity: 0.85,
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

  /// 灰階佔位格：純視覺，不可點擊、不接受拖放
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

// ── iOS / Android 14 有限存取橫幅 ─────────────────────────────────────────────
//
// 僅在 _permissionState == PermissionState.limited 時顯示。
// authorized / notDetermined / null 一律不顯示。

class _LimitedAccessBanner extends StatelessWidget {
  const _LimitedAccessBanner({
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
          Icon(Icons.photo_library_outlined, size: 16, color: colors.forestGreen),
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

// ── 重新申請：已有上傳照片提示橫幅 ────────────────────────────────────────────
//
// 當用戶進入重新申請流程，`uploadedPhotoPaths` 已預填但未重選本機照片時顯示。
// 提示用戶可直接點「下一步」保留舊照片，或重新選取替換。

class _ExistingPhotosBanner extends StatelessWidget {
  const _ExistingPhotosBanner({
    required this.count,
    required this.colors,
    required this.textTheme,
  });

  final int count;
  final AppColors colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.forestGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colors.forestGreen.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 16, color: colors.forestGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.applyPhotosExistingHint(count),
              style: textTheme.bodySmall?.copyWith(color: colors.secondaryText),
            ),
          ),
        ],
      ),
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