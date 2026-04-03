import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 申請流程（Step 1–6）的表單資料
///
/// 跨頁面持久：用戶從 Step 2 返回 Step 3 時，資料不會消失。
@immutable
class ApplyFormData {
  const ApplyFormData({
    this.phone = '',
    this.displayName = '',
    this.birthDate,
    this.gender = '',
    this.seeking = const [],
    this.localPhotoPaths = const [],
    this.uploadedPhotoPaths = const [],
    this.verificationFrontPath = '',
    this.verificationSidePath = '',
    this.verificationAction1 = '',
    this.verificationAction1Path = '',
    this.verificationAction2 = '',
    this.verificationAction2Path = '',
    this.bio = '',
  });

  /// E.164 格式電話，例：+886912345678
  final String phone;

  /// 顯示名稱（1–20 字）
  final String displayName;

  /// 生日（需滿 18 歲）
  final DateTime? birthDate;

  /// 'male' | 'female' | 'other'
  final String gender;

  /// 想認識的對象：['male'] / ['female'] / ['everyone']
  final List<String> seeking;

  /// 本機照片路徑（XFile.path），用於頁面返回時預覽
  final List<String> localPhotoPaths;

  /// 已上傳至 Supabase Storage 的相對路徑，用於送出 DB
  final List<String> uploadedPhotoPaths;

  // ── 真人認證（Step 4）────────────────────────────────────────────────────
  /// 正面照本機路徑（本機暫存，僅供預覽）
  final String verificationFrontPath;

  /// 左側臉照本機路徑
  final String verificationSidePath;

  /// 動作 1 的 VerificationAction.name（DB 存此值）
  final String verificationAction1;

  /// 動作 1 照片本機路徑
  final String verificationAction1Path;

  /// 動作 2 的 VerificationAction.name
  final String verificationAction2;

  /// 動作 2 照片本機路徑
  final String verificationAction2Path;

  /// 自我介紹（選填，上限 150 字）
  final String bio;

  /// 四張認證照片是否都已拍攝
  bool get verificationDone =>
      verificationFrontPath.isNotEmpty &&
      verificationSidePath.isNotEmpty &&
      verificationAction1Path.isNotEmpty &&
      verificationAction2Path.isNotEmpty;

  ApplyFormData copyWith({
    String? phone,
    String? displayName,
    DateTime? birthDate,
    String? gender,
    List<String>? seeking,
    List<String>? localPhotoPaths,
    List<String>? uploadedPhotoPaths,
    String? verificationFrontPath,
    String? verificationSidePath,
    String? verificationAction1,
    String? verificationAction1Path,
    String? verificationAction2,
    String? verificationAction2Path,
    String? bio,
  }) {
    return ApplyFormData(
      phone:                    phone                    ?? this.phone,
      displayName:              displayName              ?? this.displayName,
      birthDate:                birthDate                ?? this.birthDate,
      gender:                   gender                   ?? this.gender,
      seeking:                  seeking                  ?? this.seeking,
      localPhotoPaths:          localPhotoPaths          ?? this.localPhotoPaths,
      uploadedPhotoPaths:       uploadedPhotoPaths       ?? this.uploadedPhotoPaths,
      verificationFrontPath:    verificationFrontPath    ?? this.verificationFrontPath,
      verificationSidePath:     verificationSidePath     ?? this.verificationSidePath,
      verificationAction1:      verificationAction1      ?? this.verificationAction1,
      verificationAction1Path:  verificationAction1Path  ?? this.verificationAction1Path,
      verificationAction2:      verificationAction2      ?? this.verificationAction2,
      verificationAction2Path:  verificationAction2Path  ?? this.verificationAction2Path,
      bio:                      bio                      ?? this.bio,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ApplyFormNotifier extends StateNotifier<ApplyFormData> {
  ApplyFormNotifier() : super(const ApplyFormData());

  /// Step 1：儲存電話
  void setPhone(String phone) =>
      state = state.copyWith(phone: phone);

  /// Step 2：基本資料（含 seeking）
  void setInfo({
    required String displayName,
    required DateTime birthDate,
    required String gender,
    required List<String> seeking,
  }) {
    state = state.copyWith(
      displayName: displayName,
      birthDate: birthDate,
      gender: gender,
      seeking: seeking,
    );
  }

  /// Step 3：照片選取後立即儲存本機路徑（供返回時預覽）
  void setLocalPhotos(List<String> paths) =>
      state = state.copyWith(localPhotoPaths: paths);

  /// Step 3：上傳成功後儲存 Storage 路徑
  void setUploadedPhotos(List<String> paths) =>
      state = state.copyWith(uploadedPhotoPaths: paths);

  /// Step 4：儲存真人認證資料（本機路徑 + 動作代碼）
  void setVerification({
    required String frontPath,
    required String sidePath,
    required String action1,
    required String action1Path,
    required String action2,
    required String action2Path,
  }) {
    state = state.copyWith(
      verificationFrontPath:   frontPath,
      verificationSidePath:    sidePath,
      verificationAction1:     action1,
      verificationAction1Path: action1Path,
      verificationAction2:     action2,
      verificationAction2Path: action2Path,
    );
  }

  /// Step 5：Bio
  void setBio(String bio) =>
      state = state.copyWith(bio: bio);

  /// 申請送出後重置（或用戶重新申請時）
  void reset() => state = const ApplyFormData();
}

final applyFormProvider =
    StateNotifierProvider<ApplyFormNotifier, ApplyFormData>(
  (ref) => ApplyFormNotifier(),
);
