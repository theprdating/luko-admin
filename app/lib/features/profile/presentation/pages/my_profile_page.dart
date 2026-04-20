import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/data/interests_questions_data.dart'
    show
        InterestItem,
        kInterestCategories,
        kInterestCategoryOf,
        kInterestLookup;
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/profile_provider.dart';

/// 我的個人檔案頁
///
/// 路由：/me（ShellRoute tab 3）
/// 顯示自己的公開檔案樣式，提供編輯和設定入口。
/// 與 discover 頁中其他人看到的樣式保持一致，讓用戶預覽自己的呈現效果。
class MyProfilePage extends ConsumerWidget {
  const MyProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(myProfileProvider);
    final photoUrlsAsync = ref.watch(myProfilePhotoUrlsProvider);

    return Scaffold(
      backgroundColor: colors.backgroundWarm,
      body: profileAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: colors.forestGreen),
        ),
        error: (e, stack) => _ErrorState(
          message: l10n.profileLoadError,
          error: e,
          stackTrace: stack,
          onRetry: () {
            ref.invalidate(myProfileProvider);
            ref.invalidate(myProfilePhotoUrlsProvider);
          },
          colors: colors,
        ),
        data: (profile) {
          if (profile == null) {
            return _ErrorState(
              message: l10n.profileLoadError,
              onRetry: () => ref.invalidate(myProfileProvider),
              colors: colors,
            );
          }
          return _ProfileContent(
            profile: profile,
            photoUrlsAsync: photoUrlsAsync,
          );
        },
      ),
    );
  }
}

// ── 內容主體 ──────────────────────────────────────────────────────────────────

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({
    required this.profile,
    required this.photoUrlsAsync,
  });

  final Map<String, dynamic> profile;
  final AsyncValue<List<String>> photoUrlsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;

    final displayName = profile['display_name'] as String? ?? '';
    final birthDate = profile['birth_date'] as String?;
    final bio = profile['bio'] as String?;
    final interests = (profile['interests'] as List?)?.cast<String>() ?? [];
    final questionAnswers = (profile['question_answers'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    final age = birthDate != null ? _calculateAge(birthDate) : null;

    return CustomScrollView(
      slivers: [
        // ── SliverAppBar（右側：設定）──────────────────────────────────
        SliverAppBar(
          backgroundColor: colors.backgroundWarm,
          surfaceTintColor: colors.backgroundWarm,
          elevation: 0,
          floating: true,
          pinned: false,
          title: Text(
            l10n.appName,
            style: textTheme.titleMedium?.copyWith(
              color: colors.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings_outlined, color: colors.primaryText),
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),

        // ── 照片 PageView ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _PhotoGallery(photoUrlsAsync: photoUrlsAsync, colors: colors),
        ),

        // ── 姓名 / 年齡 + 編輯按鈕（同行，按鈕靠右）──────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding, AppSpacing.lg,
              AppSpacing.pagePadding, 0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 名稱 + 年齡佔滿剩餘空間，過長時以 … 截斷
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: textTheme.headlineMedium?.copyWith(
                            color: colors.primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (age != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          ',  $age',
                          style: textTheme.titleLarge?.copyWith(
                            color: colors.secondaryText.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // 編輯按鈕：固定靠右，不受名稱長度影響
                OutlinedButton.icon(
                  onPressed: () => context.push('/me/edit'),
                  icon: Icon(Icons.edit_outlined,
                      size: 13, color: colors.forestGreen),
                  label: Text(
                    l10n.profileEditButton,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.forestGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: colors.forestGreen.withValues(alpha: 0.6),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── 關於我 ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _Section(
            title: l10n.profileSectionBio,
            colors: colors,
            child: (bio != null && bio.isNotEmpty)
                ? Text(
                    bio,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.primaryText,
                      height: 1.6,
                    ),
                  )
                : Text(
                    l10n.profileNoBio,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.secondaryText.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ),
        ),

        // ── 興趣（依類別分組）──────────────────────────────────────────
        SliverToBoxAdapter(
          child: _Section(
            title: l10n.profileSectionInterests,
            colors: colors,
            child: interests.isEmpty
                ? Text(
                    l10n.profileNoInterests,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.secondaryText.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : _GroupedInterests(
                    interestIds: interests,
                    langCode: langCode,
                    colors: colors,
                  ),
          ),
        ),

        // ── 個人問答 ────────────────────────────────────────────────────
        if (questionAnswers.isNotEmpty)
          SliverToBoxAdapter(
            child: _Section(
              title: l10n.profileSectionQuestions,
              colors: colors,
              child: Column(
                children: [
                  for (int i = 0; i < questionAnswers.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    _QACard(
                      question: questionAnswers[i]['question'] as String? ?? '',
                      answer: questionAnswers[i]['answer'] as String? ?? '',
                      colors: colors,
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: _Section(
              title: l10n.profileSectionQuestions,
              colors: colors,
              child: Text(
                l10n.profileNoQuestions,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.secondaryText.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),

        // ── 底部留白 ────────────────────────────────────────────────────
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
      ],
    );
  }

  static int _calculateAge(String birthDate) {
    final dob = DateTime.tryParse(birthDate);
    if (dob == null) return 0;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

}

// ── 照片 PageView ──────────────────────────────────────────────────────────

class _PhotoGallery extends StatefulWidget {
  const _PhotoGallery({required this.photoUrlsAsync, required this.colors});
  final AsyncValue<List<String>> photoUrlsAsync;
  final AppColors colors;

  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final galleryHeight = screenHeight * 0.52;

    return widget.photoUrlsAsync.when(
      loading: () => Container(
        height: galleryHeight,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        decoration: BoxDecoration(
          color: widget.colors.forestDeep,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Center(
          child: CircularProgressIndicator(color: widget.colors.forestGreen),
        ),
      ),
      error: (_, __) => Container(
        height: galleryHeight,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        decoration: BoxDecoration(
          color: widget.colors.forestDeep,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Icon(Icons.person_outline, size: 64, color: widget.colors.secondaryText),
      ),
      data: (urls) {
        if (urls.isEmpty) {
          return Container(
            height: galleryHeight,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            decoration: BoxDecoration(
              color: widget.colors.forestDeep,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Icon(Icons.person_outline, size: 64, color: widget.colors.secondaryText),
          );
        }
        return Column(
          children: [
            SizedBox(
              height: galleryHeight,
              child: PageView.builder(
                itemCount: urls.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (_, i) => Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? AppSpacing.pagePadding : AppSpacing.xs,
                    right: i == urls.length - 1 ? AppSpacing.pagePadding : AppSpacing.xs,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: CachedNetworkImage(
                      imageUrl: urls[i],
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: widget.colors.forestDeep,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: widget.colors.forestGreen,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: widget.colors.forestDeep,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: widget.colors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 指示點
            if (urls.length > 1) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(urls.length, (i) {
                  final isActive = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? widget.colors.forestGreen
                          : widget.colors.secondaryText.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ── Section 區塊 ────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, required this.colors});
  final String title;
  final Widget child;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding, AppSpacing.xl,
        AppSpacing.pagePadding, 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: colors.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, thickness: 1, color: colors.divider),
        ],
      ),
    );
  }
}

// ── 興趣（依類別分組）────────────────────────────────────────────────────────
//
// 按 kInterestCategories 的固定順序顯示，只顯示用戶有選的類別。
// 每個類別：小標題（類別名稱）+ 下方 Wrap chips。

class _GroupedInterests extends StatelessWidget {
  const _GroupedInterests({
    required this.interestIds,
    required this.langCode,
    required this.colors,
  });

  final List<String> interestIds;
  final String langCode;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // 分組：category id → 該類別中用戶有選的 InterestItem（保留 kInterestCategories 順序）
    final grouped = <String, List<InterestItem>>{};
    for (final id in interestIds) {
      final cat = kInterestCategoryOf[id];
      if (cat == null) continue;
      (grouped[cat.id] ??= []).add(kInterestLookup[id]!);
    }

    final categories = kInterestCategories
        .where((cat) => grouped.containsKey(cat.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < categories.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.lg),
          // 類別標題
          Text(
            categories[i].label(langCode).toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: colors.secondaryText.withValues(alpha: 0.6),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // 該類別的 chips
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: grouped[categories[i].id]!.map((item) {
              return _InterestTag(
                label: item.label(langCode),
                colors: colors,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

// ── 興趣標籤 ────────────────────────────────────────────────────────────────

class _InterestTag extends StatelessWidget {
  const _InterestTag({required this.label, required this.colors});
  final String label;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: colors.divider),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.primaryText,
            ),
      ),
    );
  }
}

// ── Q&A 卡片（可展開）────────────────────────────────────────────────────────
//
// 答案預設截 3 行 + 刪節號，點擊卡片切換展開 / 收合。
// 只有答案超過 3 行時才顯示展開提示，短答案直接全文顯示。

class _QACard extends StatefulWidget {
  const _QACard({
    required this.question,
    required this.answer,
    required this.colors,
  });
  final String question;
  final String answer;
  final AppColors colors;

  @override
  State<_QACard> createState() => _QACardState();
}

class _QACardState extends State<_QACard> {
  static const int _collapsedMaxLines = 3;
  bool _expanded = false;
  // 由 LayoutBuilder 決定答案是否超出截斷閾值
  bool _isOverflowing = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = widget.colors;

    final answerStyle = textTheme.bodyMedium?.copyWith(
      color: colors.primaryText,
      height: 1.55,
    );

    return GestureDetector(
      onTap: _isOverflowing ? () => setState(() => _expanded = !_expanded) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: colors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 問題標籤 ──
            Text(
              widget.question,
              style: textTheme.labelMedium?.copyWith(
                color: colors.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── 答案（用 LayoutBuilder 偵測是否 overflow）──
            LayoutBuilder(
              builder: (context, constraints) {
                // 用 TextPainter 測量 _collapsedMaxLines 以內能否放下全文
                final tp = TextPainter(
                  text: TextSpan(text: widget.answer, style: answerStyle),
                  maxLines: _collapsedMaxLines,
                  textDirection: TextDirection.ltr,
                );
                tp.layout(maxWidth: constraints.maxWidth);
                final overflows = tp.didExceedMaxLines;

                // 更新 overflow 狀態（不在 build 直接 setState，用 postFrameCallback）
                if (overflows != _isOverflowing) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _isOverflowing = overflows);
                  });
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.answer,
                      style: answerStyle,
                      maxLines: _expanded ? null : _collapsedMaxLines,
                      overflow: _expanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                    // ── 展開 / 收起提示 ──
                    if (overflows) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _expanded ? '收起' : '展開',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.forestGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── 錯誤狀態 ────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.colors,
    this.error,
    this.stackTrace,
  });
  final String message;
  final VoidCallback onRetry;
  final AppColors colors;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: colors.secondaryText),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.secondaryText,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () {
              debugPrint('═══ [MyProfilePage] 重試 ════════════════════════');
              debugPrint('Error  : $error');
              debugPrint('Stack  :\n$stackTrace');
              debugPrint('════════════════════════════════════════════════');
              onRetry();
            },
            child: Text(
              AppLocalizations.of(context)!.commonRetry,
              style: TextStyle(color: colors.forestGreen),
            ),
          ),
        ],
      ),
    );
  }
}
