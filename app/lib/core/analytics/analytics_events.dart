/// Mixpanel 事件名稱常數
///
/// 命名規範：`snake_case`，格式為 `{物件}_{動作}` 或 `{場景}_{動作}`
/// 所有 track 呼叫必須使用此處的常數，禁止直接寫字串
abstract class AnalyticsEvents {
  // ── Screen Views ──────────────────────────────────────────────────────────
  static const screenView = 'screen_view';
  // properties: { 'screen': String }

  // ── Onboarding ────────────────────────────────────────────────────────────
  static const onboardingStarted   = 'onboarding_started';
  static const onboardingSlideView = 'onboarding_slide_view';
  // properties: { 'slide': int (1-3) }
  static const onboardingCompleted = 'onboarding_completed';
  static const onboardingSkipped   = 'onboarding_skipped';
  // properties: { 'skipped_at_slide': int }

  // ── Auth: Phone OTP ───────────────────────────────────────────────────────
  static const authPhoneSent     = 'auth_phone_sent';
  static const authOtpVerified   = 'auth_otp_verified';
  static const authOtpFailed     = 'auth_otp_failed';
  // properties: { 'error_type': 'invalid' | 'expired' }

  // ── Apply Flow ────────────────────────────────────────────────────────────
  static const applyStepCompleted  = 'apply_step_completed';
  // properties: { 'step': int (1-5) }
  static const applyPhotoUploaded  = 'apply_photo_uploaded';
  // properties: { 'count': int }
  static const applySubmitted      = 'apply_submitted';

  // ── Login ─────────────────────────────────────────────────────────────────
  static const loginStarted    = 'login_started';
  static const loginCompleted  = 'login_completed';

  // ── Terms ─────────────────────────────────────────────────────────────────
  static const termsUpdateShown    = 'terms_update_shown';
  static const termsUpdateAccepted = 'terms_update_accepted';
  static const termsUpdateDeclined = 'terms_update_declined';

  // ── Core App ──────────────────────────────────────────────────────────────
  static const swipeLike    = 'swipe_like';
  static const swipePass    = 'swipe_pass';
  static const matchCreated = 'match_created';
  static const messageSent  = 'message_sent';
  // properties: { 'char_count': int }
  static const profileView  = 'profile_view';
  // properties: { 'target_user_id': String }

  // ── Account ───────────────────────────────────────────────────────────────
  static const logout        = 'logout';
  static const accountDelete = 'account_delete';
}

/// Mixpanel 用戶屬性 Key
abstract class AnalyticsUserProps {
  static const gender           = 'gender';
  static const applicationCount = 'application_count';
  static const isFoundingMember = 'is_founding_member';
  static const accountStatus    = 'account_status'; // pending / approved / rejected
}
