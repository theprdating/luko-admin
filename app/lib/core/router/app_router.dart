import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/app_user_status.dart';
import '../providers/shared_prefs_provider.dart';
import '../../features/auth/presentation/pages/apply/apply_bio_page.dart';
import '../../features/auth/presentation/pages/apply/apply_verify_page.dart';
import '../../features/auth/presentation/pages/apply/apply_confirm_page.dart';
import '../../features/auth/presentation/pages/apply/apply_info_page.dart';
import '../../features/auth/presentation/pages/apply/apply_phone_page.dart';
import '../../features/auth/presentation/pages/apply/apply_photos_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/verify_phone_page.dart';
import '../../features/auth/presentation/pages/dev_state_picker_page.dart';
import '../../features/auth/presentation/pages/approved_gate_page.dart';
import '../../features/auth/presentation/pages/pending_page.dart';
import '../../features/auth/presentation/pages/rejected_page.dart';
import '../../features/auth/presentation/pages/terms_page.dart';
import '../../features/auth/presentation/pages/privacy_page.dart';
import '../../features/auth/presentation/pages/terms_update_page.dart';
import '../../features/auth/presentation/pages/welcome_in_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/providers/apply_provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../supabase/supabase_provider.dart';
import '../../features/chat/presentation/pages/chat_room_page.dart';
import '../../features/chat/presentation/pages/messages_page.dart';
import '../../features/discover/presentation/pages/discover_page.dart';
import '../../features/match/presentation/pages/matches_page.dart';
import '../../features/profile/presentation/pages/delete_account_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/my_profile_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../../features/profile/presentation/pages/user_profile_page.dart';
import '../../features/shared/presentation/shell_scaffold.dart';

// ── 路由名稱常數 ────────────────────────────────────────────────────────────
// 用 context.goNamed(AppRoutes.discover) 取代硬寫字串，減少拼字錯誤
abstract class AppRoutes {
  static const onboarding      = 'onboarding';
  static const welcome         = 'welcome';
  static const termsUpdate     = 'terms-update';
  static const verifyPhone     = 'verify-phone';
  static const applyPhone      = 'apply-phone';
  static const applyInfo       = 'apply-info';
  static const applyPhotos     = 'apply-photos';
  static const applyVerify     = 'apply-verify';
  static const applyBio        = 'apply-bio';
  static const applyConfirm    = 'apply-confirm';
  static const reviewPending   = 'review-pending';
  static const reviewApproved  = 'review-approved';
  static const reviewRejected  = 'review-rejected';
  static const welcomeIn       = 'welcome-in';
  static const discover        = 'discover';
  static const matches         = 'matches';
  static const messages        = 'messages';
  static const chatRoom        = 'chat-room';
  static const me              = 'me';
  static const editProfile     = 'edit-profile';
  static const userProfile     = 'user-profile';
  static const settings        = 'settings';
  static const deleteAccount   = 'delete-account';
  static const terms              = 'terms';
  static const privacy            = 'privacy';
  static const devStatePicker       = 'dev-state-picker';
  static const devPending           = 'dev-pending';
  static const devApproved          = 'dev-approved';
  static const devRejectedSoft      = 'dev-rejected-soft';
  static const devRejectedPotential = 'dev-rejected-potential';
  static const devApplyInfo         = 'dev-apply-info';
  static const devApplyPhotos       = 'dev-apply-photos';
  static const devApplyVerify       = 'dev-apply-verify';
  static const devApplyBio          = 'dev-apply-bio';
  static const devApplyConfirm      = 'dev-apply-confirm';
}

// ── Notifier：橋接 Riverpod → GoRouter refreshListenable ────────────────────
//
// GoRouter 的 refreshListenable 需要一個 Listenable（ChangeNotifier），
// 但 Riverpod 的 Provider 不直接實作 Listenable。
// 這個 class 橋接兩者：當 Riverpod 的 appUserStatusProvider 更新時，
// 呼叫 notifyListeners() 讓 GoRouter 重新執行 redirect。
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    // 監聽 Auth stream 變化（登入 / 登出）
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    // 監聽用戶狀態變化（申請審核通過 / 拒絕）
    _ref.listen(appUserStatusProvider, (_, __) => notifyListeners());
    // 監聽重新申請模式（rejected 用戶重填申請流程時放行 /apply/*）
    _ref.listen(reapplyModeProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  AppUserStatus get _status => _ref.read(appUserStatusProvider).when(
    data: (s) => s,
    loading: () => AppUserStatus.loading,
    error: (_, __) => AppUserStatus.unauthenticated,
  );

  /// GoRouter redirect callback
  ///
  /// 回傳 null = 不重導向；回傳路徑字串 = 強制導向該路徑
  String? redirect(GoRouterState state) {
    final path = state.matchedLocation;

    // /terms 與 /privacy 在所有登入狀態下均可存取（條款連結應始終可讀）
    if (path == '/terms' || path == '/privacy') return null;

    // /dev/* 在所有狀態下均可存取（僅 debug 建置出現，用於 UI 測試）
    if (path.startsWith('/dev/')) return null;

    final status = _status;

    return switch (status) {
      // 仍在確認 session，停在當前路徑。
      // initialLocation 為 '/'，冷啟動自然停在空白頁。
      // ⚠️ 不可 redirect 到 '/'：mid-flow 操作（updateUser / signInWithOtp）也會
      //    觸發 auth event → loading 狀態，若此時 redirect 到 '/' 會打斷進行中的流程。
      AppUserStatus.loading => null,

      // 未登入：同步判斷 onboarding 是否已看過，直接導向正確頁面
      AppUserStatus.unauthenticated => switch (path) {
        '/welcome' => null,
        '/onboarding' => _ref.read(onboardingSeenProvider) ? '/welcome' : null,
        _ => _ref.read(onboardingSeenProvider) ? '/welcome' : '/onboarding',
      },

      // OAuth 已登入，申請流程進行中（填寫資料步驟）
      // /apply/phone 不在正常申請流程中（使用 signInWithOtp 會提前設定 user.phone，
      // 導致 post-approval 的恭喜頁面被跳過）→ 一律導回 /apply/info
      AppUserStatus.onboarding =>
          (path.startsWith('/apply') && path != '/apply/phone') ? null : '/apply/info',

      // 審核通過，手機尚未綁定（一次性儀式）
      // 先顯示告知頁（/review/approved），用戶點 CTA 後才進 /verify/phone
      AppUserStatus.phoneVerificationRequired => switch (path) {
        '/review/approved' => null,
        '/verify/phone'    => null,
        _ => '/review/approved',
      },

      // 等待審核：只允許停在 /review/pending
      AppUserStatus.pending => path == '/review/pending' ? null : '/review/pending',

      // 審核未通過：停在 /review/rejected，或重新申請流程中允許 /apply/*
      AppUserStatus.rejected => (
        path == '/review/rejected' ||
        (path.startsWith('/apply') && _ref.read(reapplyModeProvider))
      ) ? null : '/review/rejected',

      // 已通過，但條款需更新：強制停在 /terms-update
      AppUserStatus.termsRequired => path == '/terms-update' ? null : '/terms-update',

      // 已通過且條款最新：不允許停在 auth / apply / review / verify 頁面
      // path == '/' 是冷啟動的暫時 splash，需一併導向（否則 approved 用戶會卡在空白頁）
      AppUserStatus.approved => (
        path == '/' ||
        path.startsWith('/apply') ||
        path.startsWith('/review') ||
        path == '/onboarding' ||
        path == '/welcome' ||
        path == '/verify/phone' ||
        path == '/terms-update'
      ) ? '/discover' : null,
    };
  }
}

// ── Router Provider ──────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    debugLogDiagnostics: true,   // 開發期間印出路由 log，上線前可關閉
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) => notifier.redirect(state),

    routes: [
      // ── 空白起始頁（與 native splash 同色，loading 期間不顯示任何內容）──
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(
          backgroundColor: Color(0xFF0F1E15),
        ),
      ),

      // ── Auth & Onboarding ──────────────────────────────────────────
      GoRoute(
        path: '/onboarding',
        name: AppRoutes.onboarding,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingPage(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),
      GoRoute(
        path: '/welcome',
        name: AppRoutes.welcome,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WelcomePage(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),
      GoRoute(
        path: '/terms-update',
        name: AppRoutes.termsUpdate,
        builder: (_, __) => const TermsUpdatePage(),
      ),
      GoRoute(
        path: '/verify/phone',
        name: AppRoutes.verifyPhone,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const VerifyPhonePage(),
          transitionsBuilder: (_, animation, __, child) =>
              DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFF0F1E15)),
                child: FadeTransition(opacity: animation, child: child),
              ),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),
      GoRoute(
        path: '/apply/phone',
        name: AppRoutes.applyPhone,
        builder: (_, __) => const ApplyPhonePage(),
      ),
      GoRoute(
        path: '/apply/info',
        name: AppRoutes.applyInfo,
        builder: (_, __) => const ApplyInfoPage(),
      ),
      GoRoute(
        path: '/apply/photos',
        name: AppRoutes.applyPhotos,
        builder: (_, __) => const ApplyPhotosPage(),
      ),
      GoRoute(
        path: '/apply/verify',
        name: AppRoutes.applyVerify,
        builder: (_, __) => const ApplyVerifyPage(),
      ),
      GoRoute(
        path: '/apply/bio',
        name: AppRoutes.applyBio,
        builder: (_, __) => const ApplyBioPage(),
      ),
      GoRoute(
        path: '/apply/confirm',
        name: AppRoutes.applyConfirm,
        builder: (_, __) => const ApplyConfirmPage(),
      ),
      GoRoute(
        path: '/review/pending',
        name: AppRoutes.reviewPending,
        builder: (_, __) => const PendingPage(),
      ),
      GoRoute(
        path: '/review/approved',
        name: AppRoutes.reviewApproved,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ApprovedGatePage(),
          transitionsBuilder: (_, animation, __, child) =>
              DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFF0F1E15)),
                child: FadeTransition(opacity: animation, child: child),
              ),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),
      GoRoute(
        path: '/review/rejected',
        name: AppRoutes.reviewRejected,
        builder: (_, __) => const RejectedPage(),
      ),
      GoRoute(
        path: '/welcome-in',
        name: AppRoutes.welcomeIn,
        builder: (_, __) => const WelcomeInPage(),
      ),

      // ── 主 App（底部導覽列 4 tabs）───────────────────────────────────
      // StatefulShellRoute.indexedStack 使用 IndexedStack 保留各 tab 的 State，
      // 切換 tab 時不會重建或遺失 scroll position
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/discover',
              name: AppRoutes.discover,
              builder: (_, __) => const DiscoverPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/matches',
              name: AppRoutes.matches,
              builder: (_, __) => const MatchesPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/messages',
              name: AppRoutes.messages,
              builder: (_, __) => const MessagesPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/me',
              name: AppRoutes.me,
              builder: (_, __) => const MyProfilePage(),
            ),
          ]),
        ],
      ),

      // ── Shell 外的全螢幕頁面（push，無底部導覽列）───────────────────
      GoRoute(
        path: '/messages/:matchId',
        name: AppRoutes.chatRoom,
        builder: (_, state) => ChatRoomPage(
          matchId: state.pathParameters['matchId']!,
        ),
      ),
      GoRoute(
        path: '/profile/:userId',
        name: AppRoutes.userProfile,
        builder: (_, state) => UserProfilePage(
          userId: state.pathParameters['userId']!,
        ),
      ),
      GoRoute(
        path: '/me/edit',
        name: AppRoutes.editProfile,
        builder: (_, __) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/settings',
        name: AppRoutes.settings,
        builder: (_, __) => const SettingsPage(),
      ),
      GoRoute(
        path: '/settings/delete',
        name: AppRoutes.deleteAccount,
        builder: (_, __) => const DeleteAccountPage(),
      ),

      // ── 法律文件（全狀態均可進入，redirect 邏輯已於上方放行）─────────
      GoRoute(
        path: '/terms',
        name: AppRoutes.terms,
        builder: (_, __) => const TermsPage(),
      ),
      GoRoute(
        path: '/privacy',
        name: AppRoutes.privacy,
        builder: (_, __) => const PrivacyPage(),
      ),

      // ── Dev 測試路由（bypass redirect，僅 debug 用）────────────────
      GoRoute(
        path: '/dev/state-picker',
        name: AppRoutes.devStatePicker,
        builder: (_, __) => const DevStatePickerPage(),
      ),
      GoRoute(
        path: '/dev/pending',
        name: AppRoutes.devPending,
        builder: (_, __) => const PendingPage(isDevMode: true),
      ),
      GoRoute(
        path: '/dev/approved',
        name: AppRoutes.devApproved,
        builder: (_, __) => const ApprovedGatePage(),
      ),
      GoRoute(
        path: '/dev/rejected-soft',
        name: AppRoutes.devRejectedSoft,
        builder: (_, __) => const RejectedPage(devRejectionType: 'soft'),
      ),
      GoRoute(
        path: '/dev/rejected-potential',
        name: AppRoutes.devRejectedPotential,
        builder: (_, __) => const RejectedPage(devRejectionType: 'potential'),
      ),
      GoRoute(
        path: '/dev/apply-info',
        name: AppRoutes.devApplyInfo,
        builder: (_, __) => const ApplyInfoPage(isDevMode: true),
      ),
      GoRoute(
        path: '/dev/apply-photos',
        name: AppRoutes.devApplyPhotos,
        builder: (_, __) => const ApplyPhotosPage(isDevMode: true),
      ),
      GoRoute(
        path: '/dev/apply-verify',
        name: AppRoutes.devApplyVerify,
        builder: (_, __) => const ApplyVerifyPage(isDevMode: true),
      ),
      GoRoute(
        path: '/dev/apply-bio',
        name: AppRoutes.devApplyBio,
        builder: (_, __) => const ApplyBioPage(isDevMode: true),
      ),
      GoRoute(
        path: '/dev/apply-confirm',
        name: AppRoutes.devApplyConfirm,
        builder: (_, __) => const ApplyConfirmPage(isDevMode: true),
      ),
    ],
  );
});
