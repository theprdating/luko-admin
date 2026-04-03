/// App 全域的用戶狀態
///
/// GoRouter 的 redirect 邏輯依賴此 enum 決定要導向哪個頁面。
///
/// 狀態流轉：
/// ```
/// loading
///   ├─ → unauthenticated              （未登入）
///   └─ → onboarding                  （已登入，尚未提交申請）
///         ↓
///       pending                      （申請已提交，等待審核）
///         ├─ → rejected              （審核未通過，30 天後可重申請）
///         └─ → phoneVerificationRequired（審核通過，手機尚未綁定）
///               ↓
///             termsRequired          （手機已綁定，但條款版本已更新）
///               ↓
///             approved               （手機已綁定且條款為最新版本）
/// ```
enum AppUserStatus {
  /// 初始狀態 — 正在從 Supabase 確認 session 與 DB 狀態
  loading,

  /// 未登入 — 顯示歡迎頁
  unauthenticated,

  /// 已完成 OAuth 登入，但尚未送出申請（申請流程進行中）
  onboarding,

  /// 申請已送出，等待人工審核
  pending,

  /// 審核未通過
  rejected,

  /// 審核通過，但手機號碼尚未綁定（一次性儀式）
  phoneVerificationRequired,

  /// 手機已綁定，但平台條款或隱私政策已更新，需強制重新接受才能繼續
  termsRequired,

  /// 審核通過、手機已綁定、條款為最新版本，可完整使用 App
  approved,
}
