import '../../../l10n/app_localizations.dart';

/// 真人認證動作庫
///
/// 每次進入認證流程時，從此 enum 隨機抽取 2 個要求用戶配合做出動作。
/// [name] 用於存入 DB（identity_verifications.action1_code / action2_code）。
enum VerificationAction {
  smile,
  blink,
  openMouth,
  raiseRightHand,
  raiseLeftHand,
  wave,
  thumbsUp,
  touchNose,
  crossArms,
  tiltHead,
}

extension VerificationActionX on VerificationAction {
  /// 對應的 l10n 顯示文字
  String displayName(AppLocalizations l10n) => switch (this) {
    VerificationAction.smile          => l10n.verifyActionSmile,
    VerificationAction.blink          => l10n.verifyActionBlink,
    VerificationAction.openMouth      => l10n.verifyActionOpenMouth,
    VerificationAction.raiseRightHand => l10n.verifyActionRaiseRightHand,
    VerificationAction.raiseLeftHand  => l10n.verifyActionRaiseLeftHand,
    VerificationAction.wave           => l10n.verifyActionWave,
    VerificationAction.thumbsUp       => l10n.verifyActionThumbsUp,
    VerificationAction.touchNose      => l10n.verifyActionTouchNose,
    VerificationAction.crossArms      => l10n.verifyActionCrossArms,
    VerificationAction.tiltHead       => l10n.verifyActionTiltHead,
  };

  /// 從 DB 字串還原 enum（找不到則 null）
  static VerificationAction? fromCode(String code) {
    try {
      return VerificationAction.values.firstWhere((a) => a.name == code);
    } catch (_) {
      return null;
    }
  }
}
