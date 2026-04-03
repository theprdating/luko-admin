import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../l10n/app_localizations.dart';

/// 相簿 / 相機權限工具
///
/// 設計原則：
/// - `AssetPicker.pickAssets()` 與 `image_picker` 本身已會觸發系統原生權限彈窗，
///   不需要在呼叫前再做一次 `requestPermissionExtend()`（雙重請求會導致狀態不穩定）。
/// - 本 helper 只負責「已確認被永久拒絕」後，顯示引導用戶前往設定的 Dialog。
///
/// 使用方式（相簿）：
/// ```dart
/// try {
///   result = await AssetPicker.pickAssets(context, ...);
/// } on StateError {
///   if (mounted) await MediaPermissionHelper.showPhotoDenied(context);
///   return;
/// }
/// ```
///
/// 使用方式（相機）：
/// ```dart
/// try {
///   file = await _picker.pickImage(source: ImageSource.camera);
/// } catch (_) {
///   if (mounted) await MediaPermissionHelper.showCameraDenied(context);
///   return;
/// }
/// ```
class MediaPermissionHelper {
  MediaPermissionHelper._();

  /// 顯示相簿已被永久拒絕的引導 Dialog（前往系統設定開啟）。
  static Future<void> showPhotoDenied(BuildContext context) =>
      _showDeniedDialog(context, isCamera: false);

  /// 顯示相機已被永久拒絕的引導 Dialog（前往系統設定開啟）。
  static Future<void> showCameraDenied(BuildContext context) =>
      _showDeniedDialog(context, isCamera: true);

  static Future<void> _showDeniedDialog(
    BuildContext context, {
    required bool isCamera,
  }) async {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isCamera ? l10n.permissionCameraTitle : l10n.permissionPhotoTitle,
        ),
        content: Text(
          isCamera ? l10n.permissionCameraBody : l10n.permissionPhotoBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              PhotoManager.openSetting();
            },
            child: Text(l10n.permissionOpenSettings),
          ),
        ],
      ),
    );
  }
}
