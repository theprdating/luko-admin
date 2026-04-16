import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 問題回答（Step 6：問題填寫）
@immutable
class QuestionAnswer {
  const QuestionAnswer({
    required this.questionId,
    required this.questionText,
    required this.answer,
  });

  final String questionId;
  final String questionText;
  final String answer;

  QuestionAnswer copyWith({String? answer}) => QuestionAnswer(
    questionId: questionId,
    questionText: questionText,
    answer: answer ?? this.answer,
  );
}

/// 申請流程（Step 1–8）的表單資料
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
    this.interests = const [],
    this.questionAnswers = const [],
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

  /// 興趣標籤列表（Step 5）
  final List<String> interests;

  /// 問題回答列表（Step 6）
  final List<QuestionAnswer> questionAnswers;

  /// 自我介紹（選填，上限 500 字）
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
    List<String>? interests,
    List<QuestionAnswer>? questionAnswers,
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
      interests:                interests                ?? this.interests,
      questionAnswers:          questionAnswers          ?? this.questionAnswers,
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

  /// Step 5：興趣標籤
  void setInterests(List<String> interests) =>
      state = state.copyWith(interests: interests);

  /// Step 6：問題回答
  void setQuestionAnswers(List<QuestionAnswer> answers) =>
      state = state.copyWith(questionAnswers: answers);

  /// Step 7：Bio
  void setBio(String bio) =>
      state = state.copyWith(bio: bio);

  /// Beta 模式：setInfo 後補回 bio + uploadedPhotoPaths（copyWith 不影響其他欄位）
  void restoreBetaExtras({
    required String bio,
    required List<String> uploadedPhotoPaths,
  }) {
    state = state.copyWith(bio: bio, uploadedPhotoPaths: uploadedPhotoPaths);
  }

  /// 申請送出後重置（或用戶重新申請時）
  void reset() => state = const ApplyFormData();

  /// Beta 遷移：預填封測資料（display_name, gender, seeking, bio, photo_paths）
  /// 用戶仍可在申請流程中修改文字欄位；照片在照片頁面鎖定，進 APP 後才可更換
  void prefillForBeta({
    required String displayName,
    required String gender,
    required List<String> seeking,
    required String bio,
    List<String> uploadedPhotoPaths = const [],
  }) {
    state = ApplyFormData(
      displayName:        displayName,
      gender:             gender,
      seeking:            seeking,
      bio:                bio,
      uploadedPhotoPaths: uploadedPhotoPaths,
    );
  }

  /// 重新申請：從 DB 預填已有資料，認證照片欄位保持空白（強制重拍）
  void prefillForReapply({
    required String displayName,
    required DateTime birthDate,
    required String gender,
    required List<String> seeking,
    required List<String> uploadedPhotoPaths,
    required List<String> interests,
    required List<QuestionAnswer> questionAnswers,
    required String bio,
  }) {
    state = ApplyFormData(
      displayName:        displayName,
      birthDate:          birthDate,
      gender:             gender,
      seeking:            seeking,
      uploadedPhotoPaths: uploadedPhotoPaths,
      interests:          interests,
      questionAnswers:    questionAnswers,
      bio:                bio,
      // phone, localPhotoPaths, verification 維持預設空值，
      // 照片頁面可辨識已有上傳路徑；認證步驟強制重拍。
    );
  }
}

final applyFormProvider =
    StateNotifierProvider<ApplyFormNotifier, ApplyFormData>(
  (ref) => ApplyFormNotifier(),
);

/// 用戶點擊「重新申請」後進入重填流程時設為 true，
/// 讓 router 放行 rejected 用戶存取 /apply/* 路由。
/// 送出確認頁後自動重設為 false。
final reapplyModeProvider = StateProvider<bool>((ref) => false);
