/// App 全域的用戶狀態
///
/// GoRouter 的 redirect 邏輯依賴此 enum 決定要導向哪個頁面。
///
/// 狀態流轉：
/// ```
/// loading
///   ├─ → unauthenticated              （未登入）
///   ├─ → betaOnboarding              （封測白名單用戶，走精簡申請流程）
///   └─ → onboarding                  （已登入，尚未提交申請）
///         ↓
///       pending                      （申請已提交，等待審核）
///         ├─ → rejected              （審核未通過）
///         │     └─ → pendingDeletion （任何狀態下用戶申請刪除帳號）
///         └─ → phoneVerificationRequired（審核通過，手機尚未綁定）
///               ↓
///             profileSetupRequired   （手機已綁定，興趣/問題尚未填寫）
///               ↓
///             termsRequired          （Setup 完成，但條款版本已更新）
///               ↓
///             approved               （全部完成，可使用 App）
/// ```
enum AppUserStatus {
  /// 初始狀態 — 正在從 Supabase 確認 session 與 DB 狀態
  loading,

  /// 未登入 — 顯示歡迎頁
  unauthenticated,

  /// 已登入，且 email 在封測白名單，尚未送出申請（走精簡 beta 申請流程）
  betaOnboarding,

  /// 已完成 OAuth 登入，但尚未送出申請（申請流程進行中）
  onboarding,

  /// 申請已送出，等待人工審核
  pending,

  /// 審核未通過
  rejected,

  /// 用戶已提出刪除帳號申請，帳號進入凍結狀態（90 天後自動清除）
  /// 此狀態優先級高於 pending / rejected，任何狀態下申請刪除均跳至此
  pendingDeletion,

  /// 審核通過，但手機號碼尚未綁定（一次性儀式）
  phoneVerificationRequired,

  /// 手機已綁定，但興趣標籤 / 問題回答尚未填寫（一次性個人資料設置）
  /// 觸發條件：profiles.interests 為空陣列
  profileSetupRequired,

  /// 手機已綁定，但平台條款或隱私政策已更新，需強制重新接受才能繼續
  termsRequired,

  /// 審核通過、手機已綁定、個人資料已設置、條款為最新版本，可完整使用 App
  approved,
}
