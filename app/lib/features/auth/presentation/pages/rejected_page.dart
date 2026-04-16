import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/auth/sign_out.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/exit_on_double_back_scope.dart';
import '../../../../core/widgets/luko_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/apply_provider.dart';
import '../../providers/auth_provider.dart';
import '../pages/legal_scaffold.dart';

const _kMaxAttempts = 3;

/// 審核未通過頁
///
/// 路由：/review/rejected
/// 根據 applications.rejection_type 顯示不同內容：
///   soft / null → 一般拒絕畫面
///   hard        → 後台靜默封鎖，不會到達此頁
///
/// 重新申請規則：
///   - 無等待期，拒絕後可立即重新申請
///   - 每個帳號最多 3 次機會（application_count >= 3 時停用按鈕）
class RejectedPage extends ConsumerStatefulWidget {
  const RejectedPage({super.key, this.devRejectionType});

  /// Dev 模式覆寫：傳入 'soft' 可繞過 DB 查詢直接渲染對應畫面
  final String? devRejectionType;

  @override
  ConsumerState<RejectedPage> createState() => _RejectedPageState();
}

class _RejectedPageState extends ConsumerState<RejectedPage> {
  String? _rejectionType;       // 'soft' | 'hard' | null
  String? _reviewNote;
  List<String> _rejectionTags = [];
  int _applicationCount = 1;    // 目前第幾次申請（1–3）
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Dev 模式：直接套用覆寫類型，跳過 DB 查詢
    if (widget.devRejectionType != null) {
      setState(() {
        _rejectionType    = widget.devRejectionType;
        _applicationCount = 1;
        _isLoading        = false;
      });
      return;
    }

    try {
      final supabase = ref.read(supabaseProvider);
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final row = await supabase
          .from('applications')
          .select('rejection_type, review_note, rejection_tags, application_count')
          .eq('user_id', userId)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _rejectionType    = row?['rejection_type'] as String?;
        _reviewNote       = row?['review_note'] as String?;
        _rejectionTags    = List<String>.from(row?['rejection_tags'] as List? ?? []);
        _applicationCount = (row?['application_count'] as int?) ?? 1;
        _isLoading        = false;
      });
    } catch (e) {
      debugPrint('[RejectedPage] _loadData failed: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestDeletion() async {
    final supabase = ref.read(supabaseProvider);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      // upsert：若之前申請過又取消，直接覆蓋舊記錄
      await supabase.from('deletion_requests').upsert({
        'user_id': userId,
        'requested_at': DateTime.now().toIso8601String(),
        'scheduled_for': DateTime.now()
            .add(const Duration(days: 90))
            .toIso8601String(),
        'cancelled_at': null,
      });

      if (!mounted) return;

      // Router 監聽 appUserStatusProvider，自動導向 /review/deletion-pending
      ref.invalidate(appUserStatusProvider);
    } catch (e) {
      debugPrint('[RejectedPage] _requestDeletion failed: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showDeleteDialog() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.cardSurface,
        title: Text(
          l10n.reviewDeleteDialogTitle,
          style: TextStyle(color: colors.primaryText, fontWeight: FontWeight.w700),
        ),
        content: Text(
          l10n.reviewDeleteDialogBody,
          style: TextStyle(color: colors.secondaryText, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.reviewDeleteDialogCancel,
              style: TextStyle(color: colors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.reviewDeleteDialogConfirm,
              style: TextStyle(color: colors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) await _requestDeletion();
  }

  Future<void> _reapply() async {
    final supabase = ref.read(supabaseProvider);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      // 載入現有申請資料以預填表單（status 不在此更新，由 confirm 頁送出時觸發）
      final row = await supabase
          .from('applications')
          .select('display_name, birth_date, gender, seeking, bio, photo_paths')
          .eq('user_id', userId)
          .single();

      if (!mounted) return;

      final birthDate = DateTime.tryParse((row['birth_date'] as String?) ?? '');
      if (birthDate == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 預填表單：保留個人資料 + 已上傳照片路徑；認證欄位清空，強制重拍
      ref.read(applyFormProvider.notifier).prefillForReapply(
        displayName:        (row['display_name']  as String?)    ?? '',
        birthDate:          birthDate,
        gender:             (row['gender']         as String?)    ?? '',
        seeking:            List<String>.from(row['seeking']      as List? ?? []),
        uploadedPhotoPaths: List<String>.from(row['photo_paths']  as List? ?? []),
        interests:          List<String>.from(row['interests']    as List? ?? []),
        questionAnswers:    const [],  // 問題答案不從 DB 預填，讓用戶重新填寫
        bio:                (row['bio']            as String?)    ?? '',
      );

      // 放行 router，讓 rejected 用戶可存取 /apply/* 路由
      ref.read(reapplyModeProvider.notifier).state = true;

      if (mounted) context.go('/apply/info');
    } on PostgrestException catch (e) {
      debugPrint('[RejectedPage] _reapply PostgrestException: $e');
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('[RejectedPage] _reapply failed: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors    = Theme.of(context).extension<AppColors>()!;
    final l10n      = AppLocalizations.of(context)!;
    final isPotential = _rejectionType == 'soft';

    return ExitOnDoubleBackScope(
      child: Scaffold(
        backgroundColor: colors.backgroundWarm,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Dev 返回箭頭 ──────────────────────────────────────
                if (widget.devRejectionType != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  GestureDetector(
                    onTap: () => context.go('/dev/state-picker'),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8, right: 20),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: colors.secondaryText,
                        size: 20,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),

                // ── 圖示 ──────────────────────────────────────────────
                Center(
                  child: _RejectedIcon(colors: colors, isPotential: isPotential),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── 標題 ──────────────────────────────────────────────
                Text(
                  isPotential
                      ? l10n.reviewRejectedTitlePotential
                      : l10n.reviewRejectedTitleHard,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),

                // ── 說明文字 ───────────────────────────────────────────
                Text(
                  isPotential
                      ? l10n.reviewRejectedBodyPotential
                      : l10n.reviewRejectedBodyHard,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.secondaryText,
                    height: 1.65,
                  ),
                  textAlign: TextAlign.center,
                ),

                // ── 改善建議 ───────────────────────────────────────────
                // soft（差一點）：顯示個人化建議 + 通用改善 tips
                // hard（不通過）：顯示中性通用建議（不涉及外貌評論）
                if (isPotential) ...[
                  const SizedBox(height: AppSpacing.xl),
                  if (_reviewNote != null && _reviewNote!.isNotEmpty) ...[
                    _AdminFeedbackCard(
                      reviewNote: _reviewNote!,
                      colors: colors,
                      l10n: l10n,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _ImprovementTips(
                    colors: colors,
                    l10n: l10n,
                    rejectionTags: _rejectionTags,
                  ),
                ] else ...[
                  const SizedBox(height: AppSpacing.xl),
                  _ImprovementTips(colors: colors, l10n: l10n, isHard: true),
                ],

                const SizedBox(height: AppSpacing.xl),

                // ── 重申請卡片 ─────────────────────────────────────────
                if (!_isLoading)
                  _ReapplyCard(
                    colors: colors,
                    l10n: l10n,
                    applicationCount: _applicationCount,
                    onReapply: _reapply,
                    onDeleteAccount: _showDeleteDialog,
                  )
                else
                  const Center(child: CircularProgressIndicator()),

                // ── 機會用完時：登出 / 聯繫我們 ──────────────────────────
                if (!_isLoading && _applicationCount >= _kMaxAttempts) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _ExhaustedFooter(
                    colors: colors,
                    l10n: l10n,
                    onDeleteAccount: _showDeleteDialog,
                  ),
                ],

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 圖示 ─────────────────────────────────────────────────────────────────────

class _RejectedIcon extends StatelessWidget {
  const _RejectedIcon({required this.colors, required this.isPotential});
  final AppColors colors;
  final bool isPotential;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPotential
            ? colors.forestGreenSubtle
            : colors.warning.withValues(alpha: 0.12),
      ),
      child: Icon(
        isPotential ? Icons.auto_awesome_rounded : Icons.schedule_rounded,
        size: 36,
        color: isPotential ? colors.forestGreen : colors.warning,
      ),
    );
  }
}

// ── 審核員個人化建議卡片 ──────────────────────────────────────────────────────

class _AdminFeedbackCard extends StatelessWidget {
  const _AdminFeedbackCard({
    required this.reviewNote,
    required this.colors,
    required this.l10n,
  });

  final String reviewNote;
  final AppColors colors;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.forestGreenSubtle,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.forestGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rate_review_rounded, size: 16, color: colors.forestGreen),
              const SizedBox(width: 6),
              Text(
                l10n.reviewAdminFeedbackTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.forestGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            reviewNote,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.primaryText,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 改善建議卡片 ──────────────────────────────────────────────────────────────
//
// isHard = false（soft / 差一點）：
//   若後台有勾選 rejection_tags → 動態顯示對應建議
//   否則 fallback 到固定 tip1/2/3
// isHard = true（hard / 不通過）：使用中性建議，避免讓用戶感覺被評論外貌

class _ImprovementTips extends StatelessWidget {
  const _ImprovementTips({
    required this.colors,
    required this.l10n,
    this.isHard = false,
    this.rejectionTags = const [],
  });
  final AppColors colors;
  final AppLocalizations l10n;
  final bool isHard;
  final List<String> rejectionTags;

  String? _tagTip(String tag) => switch (tag) {
    'photo_blurry'     => l10n.reviewRejectedTagPhotoBlurry,
    'messy_background' => l10n.reviewRejectedTagMessyBackground,
    'casual_style'     => l10n.reviewRejectedTagCasualStyle,
    'face_unclear'     => l10n.reviewRejectedTagFaceUnclear,
    'too_few_photos'   => l10n.reviewRejectedTagTooFewPhotos,
    _                  => null,
  };

  @override
  Widget build(BuildContext context) {
    List<String> tips;
    if (isHard) {
      tips = [
        l10n.reviewRejectedHardTip1,
        l10n.reviewRejectedHardTip2,
        l10n.reviewRejectedHardTip3,
      ];
    } else {
      final tagTips = rejectionTags.map(_tagTip).whereType<String>().toList();
      tips = tagTips.isNotEmpty
          ? tagTips
          : [
              l10n.reviewRejectedTip1,
              l10n.reviewRejectedTip2,
              l10n.reviewRejectedTip3,
            ];
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tips.asMap().entries.map((entry) {
          final isLast = entry.key == tips.length - 1;
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.forestGreenSubtle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.forestGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.primaryText,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isLast) const SizedBox(height: AppSpacing.md),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── 重申請卡片 ───────────────────────────────────────────────────────────────

class _ReapplyCard extends StatelessWidget {
  const _ReapplyCard({
    required this.colors,
    required this.l10n,
    required this.applicationCount,
    required this.onReapply,
    required this.onDeleteAccount,
  });

  final AppColors colors;
  final AppLocalizations l10n;
  final int applicationCount;
  final VoidCallback onReapply;
  final VoidCallback onDeleteAccount;

  bool get _attemptsExhausted => applicationCount >= _kMaxAttempts;
  int get _attemptsRemaining  => (_kMaxAttempts - applicationCount).clamp(0, _kMaxAttempts);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.divider),
          ),
          child: _attemptsExhausted
              ? _ExhaustedState(colors: colors, l10n: l10n, textTheme: textTheme)
              : _ReapplyAvailableState(
                  colors: colors,
                  l10n: l10n,
                  textTheme: textTheme,
                  attemptsRemaining: _attemptsRemaining,
                  onReapply: onReapply,
                ),
        ),
        // 刪除帳號入口（僅在未用完機會時顯示，用完時由 _ExhaustedFooter 處理）
        // 使用極小字 + secondaryText 色：刻意低調，避免轉移重新申請的注意力
        if (!_attemptsExhausted) ...[
          const SizedBox(height: AppSpacing.md),
          Center(
            child: GestureDetector(
              onTap: onDeleteAccount,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  l10n.reviewDeleteRequestButton,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.secondaryText.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// 已用完所有機會
class _ExhaustedState extends StatelessWidget {
  const _ExhaustedState({
    required this.colors,
    required this.l10n,
    required this.textTheme,
  });

  final AppColors colors;
  final AppLocalizations l10n;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.block_rounded, size: 32, color: colors.secondaryText),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.reviewReapplyExhaustedTitle,
          style: textTheme.labelLarge?.copyWith(
            color: colors.primaryText,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.reviewReapplyExhaustedBody,
          style: textTheme.bodySmall?.copyWith(
            color: colors.secondaryText,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// 可以重新申請
class _ReapplyAvailableState extends StatelessWidget {
  const _ReapplyAvailableState({
    required this.colors,
    required this.l10n,
    required this.textTheme,
    required this.attemptsRemaining,
    required this.onReapply,
  });

  final AppColors colors;
  final AppLocalizations l10n;
  final TextTheme textTheme;
  final int attemptsRemaining;
  final VoidCallback onReapply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LukoButton.primary(
          label: l10n.reviewReapplyButton,
          onPressed: onReapply,
          icon: Icons.refresh_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.reviewReapplyAttemptsLeft(attemptsRemaining),
          style: textTheme.bodySmall?.copyWith(
            color: colors.secondaryText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── 機會用完後的底部操作區 ────────────────────────────────────────────────────
//
// 只在 applicationCount >= _kMaxAttempts 時顯示。
//
// 設計決策：不提供 App 內自助刪除帳號按鈕。
// 原因：刪除後可重新用同一身分申請，等同繞過 3 次上限。
// 合規做法：刪除請求走信箱人工處理（Apple 接受 email 作為刪除管道）；
//           帳號資料 90 天後由後端 cron job 自動清除（符合個資法）。
class _ExhaustedFooter extends StatelessWidget {
  const _ExhaustedFooter({
    required this.colors,
    required this.l10n,
    required this.onDeleteAccount,
  });

  final AppColors colors;
  final AppLocalizations l10n;
  final VoidCallback onDeleteAccount;

  Future<void> _onSignOut() => signOutAll();
  // Router 監聽 Supabase session 變化，登出後自動導向 /welcome

  Future<void> _onCopyEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: kLegalEmail));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.reviewExhaustedEmailCopied),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(color: colors.divider),
        const SizedBox(height: AppSpacing.lg),

        // 聯繫我們（點擊複製信箱）
        // 文案包含刪除帳號提示，作為合規的刪除管道
        GestureDetector(
          onTap: () => _onCopyEmail(context),
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mail_outline_rounded,
                    size: 14,
                    color: colors.secondaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.reviewExhaustedContactUs,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.secondaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                kLegalEmail,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.secondaryText.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // 登出
        LukoButton.secondary(
          label: l10n.reviewExhaustedSignOut,
          onPressed: _onSignOut,
        ),

        const SizedBox(height: AppSpacing.md),

        // 刪除帳號（低調入口，90天軟刪除，期間可取消）
        Center(
          child: GestureDetector(
            onTap: onDeleteAccount,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                l10n.reviewDeleteRequestButton,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.secondaryText.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
