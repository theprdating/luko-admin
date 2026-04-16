import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/profile_provider.dart';

/// 編輯個人檔案頁
///
/// 路由：/me/edit（push，全螢幕 form）
/// 支援編輯：顯示名稱、自我介紹、想認識偏好。
/// 興趣和問答跳轉至獨立編輯頁（/me/edit/interests, /me/edit/questions）。
/// 更換照片前顯示審核警告對話框。
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  static const int _maxBio = 500;
  static const int _maxName = 20;

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  Set<String> _seeking = {};

  // 初始值，用於判斷是否有未儲存變更
  String _initialName = '';
  String _initialBio = '';
  Set<String> _initialSeeking = {};

  bool _isInitialized = false;
  bool _isSaving = false;

  bool get _isDirty =>
      _nameController.text.trim() != _initialName ||
      _bioController.text.trim() != _initialBio ||
      !_setEquals(_seeking, _initialSeeking);

  static bool _setEquals(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _initFromProfile(Map<String, dynamic> profile) {
    if (_isInitialized) return;
    _initialName = (profile['display_name'] as String? ?? '').trim();
    _initialBio  = (profile['bio'] as String? ?? '').trim();
    _initialSeeking = Set<String>.from(
      (profile['seeking'] as List?)?.cast<String>() ?? [],
    );
    _nameController.text = _initialName;
    _bioController.text  = _initialBio;
    _seeking = Set<String>.from(_initialSeeking);
    _isInitialized = true;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) return;

      await ref.read(supabaseProvider).from('profiles').update({
        'display_name': name,
        'bio': _bioController.text.trim(),
        'seeking': _seeking.toList(),
      }).eq('id', userId);

      ref.invalidate(myProfileProvider);

      // 更新 initial 值：儲存後 _isDirty 回到 false
      _initialName    = name;
      _initialBio     = _bioController.text.trim();
      _initialSeeking = Set<String>.from(_seeking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.editProfileSaved),
            backgroundColor: Theme.of(context).extension<AppColors>()!.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.editProfileSaveFailed),
            backgroundColor: Theme.of(context).extension<AppColors>()!.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _showUnsavedDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(l10n.editProfileUnsavedTitle),
        content: Text(l10n.editProfileUnsavedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.commonCancel,
              style: TextStyle(color: colors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.editProfileUnsavedDiscard,
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return result == true;
  }

  /// 更換照片警告對話框。
  /// 用戶確認後才允許進入照片管理流程。
  Future<bool> _showPhotoChangeWarning() async {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: colors.warning, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.editProfilePhotoChangeTitle,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      color: colors.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.editProfilePhotoChangeBody,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: colors.primaryText,
                height: 1.6,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.commonCancel,
              style: TextStyle(color: colors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.editProfilePhotoChangeContinue,
              style: TextStyle(
                color: colors.forestGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(myProfileProvider);
    final photoUrlsAsync = ref.watch(myProfilePhotoThumbnailUrlsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!_isDirty) { Navigator.of(context).pop(); return; }
        final discard = await _showUnsavedDialog();
        if (discard && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
      backgroundColor: colors.backgroundWarm,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: colors.backgroundWarm,
        elevation: 0,
        surfaceTintColor: colors.backgroundWarm,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            if (!_isDirty) { Navigator.of(context).pop(); return; }
            final discard = await _showUnsavedDialog();
            if (discard && context.mounted) Navigator.of(context).pop();
          },
        ),
        title: Text(
          l10n.editProfileTitle,
          style: textTheme.titleMedium?.copyWith(
            color: colors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.forestGreen,
                      ),
                    )
                  : Text(
                      l10n.commonSave,
                      style: textTheme.labelLarge?.copyWith(
                        color: colors.forestGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: colors.forestGreen),
        ),
        error: (_, __) => Center(
          child: Text(l10n.profileLoadError,
              style: textTheme.bodyMedium?.copyWith(color: colors.secondaryText)),
        ),
        data: (profile) {
          if (profile == null) return const SizedBox.shrink();
          _initFromProfile(profile);

          final interests =
              (profile['interests'] as List?)?.cast<String>() ?? [];
          final questionAnswers =
              (profile['question_answers'] as List?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              [];
          final photoPending =
              profile['photo_pending_review'] as bool? ?? false;

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: ListView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
              children: [
                // ── 照片 ───────────────────────────────────────────────
                _SectionHeader(
                  title: l10n.editProfileSectionPhotos,
                  colors: colors,
                ),
                _PhotosSection(
                  photoUrlsAsync: photoUrlsAsync,
                  photoPending: photoPending,
                  colors: colors,
                  onManageTap: photoPending ? null : () async {
                    final router = GoRouter.of(context);
                    final confirmed = await _showPhotoChangeWarning();
                    if (confirmed && mounted) {
                      router.push('/me/edit/photos');
                    }
                  },
                ),

                // ── 基本資料 ────────────────────────────────────────────
                _SectionHeader(
                  title: l10n.editProfileSectionBasic,
                  colors: colors,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(
                        label: l10n.editProfileNameLabel,
                        colors: colors,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _TextField(
                        controller: _nameController,
                        maxLength: _maxName,
                        colors: colors,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _FieldLabel(
                        label: l10n.editProfileBioLabel,
                        colors: colors,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _BioField(
                        controller: _bioController,
                        maxLength: _maxBio,
                        hint: l10n.editProfileBioHint,
                        helperText: l10n.editProfileBioHelper(_maxBio),
                        colors: colors,
                      ),
                    ],
                  ),
                ),

                // ── 想認識 ──────────────────────────────────────────────
                _SectionHeader(
                  title: l10n.editProfileSectionSeeking,
                  colors: colors,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding,
                  ),
                  child: StatefulBuilder(
                    builder: (_, setLocal) => Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _SeekingChip(
                          label: l10n.editProfileSeekingMale,
                          isSelected: _seeking.contains('male'),
                          colors: colors,
                          onTap: () => setState(() {
                            if (_seeking.contains('male')) {
                              _seeking.remove('male');
                            } else {
                              _seeking.add('male');
                            }
                          }),
                        ),
                        _SeekingChip(
                          label: l10n.editProfileSeekingFemale,
                          isSelected: _seeking.contains('female'),
                          colors: colors,
                          onTap: () => setState(() {
                            if (_seeking.contains('female')) {
                              _seeking.remove('female');
                            } else {
                              _seeking.add('female');
                            }
                          }),
                        ),
                        _SeekingChip(
                          label: l10n.editProfileSeekingOther,
                          isSelected: _seeking.contains('other'),
                          colors: colors,
                          onTap: () => setState(() {
                            if (_seeking.contains('other')) {
                              _seeking.remove('other');
                            } else {
                              _seeking.add('other');
                            }
                          }),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── 興趣 ────────────────────────────────────────────────
                _SectionHeader(
                  title: l10n.editProfileSectionInterests,
                  colors: colors,
                ),
                _NavigationRow(
                  label: l10n.editProfileInterestsCount(interests.length),
                  buttonLabel: l10n.editProfileInterestsEdit,
                  colors: colors,
                  onTap: () => context.push('/me/edit/interests'),
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── 個人問答 ────────────────────────────────────────────
                _SectionHeader(
                  title: l10n.editProfileSectionQuestions,
                  colors: colors,
                ),
                _NavigationRow(
                  label: l10n.editProfileQuestionsCount(
                    questionAnswers.where((q) {
                      final a = q['answer'] as String?;
                      return a != null && a.isNotEmpty;
                    }).length,
                  ),
                  buttonLabel: l10n.editProfileQuestionsEdit,
                  colors: colors,
                  onTap: () => context.push('/me/edit/questions'),
                ),
              ],
            ),
          );
        },
      ),
    )); // PopScope
  }
}


// ── 區塊標題 ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.colors});
  final String title;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding, AppSpacing.xl,
        AppSpacing.pagePadding, AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.secondaryText,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(height: 1, thickness: 1, color: colors.divider),
        ],
      ),
    );
  }
}

// ── 欄位標籤 ─────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.colors});
  final String label;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.secondaryText,
            fontWeight: FontWeight.w500,
          ),
    );
  }
}

// ── 文字輸入框 ───────────────────────────────────────────────────────────────

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.maxLength,
    required this.colors,
  });
  final TextEditingController controller;
  final int maxLength;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return TextField(
      controller: controller,
      maxLength: maxLength,
      style: textTheme.bodyLarge?.copyWith(color: colors.primaryText),
      decoration: InputDecoration(
        counterStyle: textTheme.bodySmall?.copyWith(color: colors.secondaryText),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        filled: true,
        fillColor: colors.cardSurface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: colors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: colors.forestGreen, width: 1.5),
        ),
      ),
    );
  }
}

// ── Bio 多行輸入框 ────────────────────────────────────────────────────────────

class _BioField extends StatelessWidget {
  const _BioField({
    required this.controller,
    required this.maxLength,
    required this.hint,
    required this.helperText,
    required this.colors,
  });
  final TextEditingController controller;
  final int maxLength;
  final String hint;
  final String helperText;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          maxLines: null,
          minLines: 4,
          maxLength: maxLength,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          style: textTheme.bodyLarge?.copyWith(color: colors.primaryText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: textTheme.bodyLarge?.copyWith(
              color: colors.secondaryText.withValues(alpha: 0.5),
            ),
            counterText: '',
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            filled: true,
            fillColor: colors.cardSurface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(color: colors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(color: colors.forestGreen, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              helperText,
              style: textTheme.bodySmall?.copyWith(color: colors.secondaryText),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, __) {
                final count = value.text.length;
                final isNear = count >= maxLength * 0.9;
                return Text(
                  '$count / $maxLength',
                  style: textTheme.bodySmall?.copyWith(
                    color: isNear ? colors.warning : colors.secondaryText,
                    fontWeight: isNear ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

// ── 想認識 Chip ──────────────────────────────────────────────────────────────

class _SeekingChip extends StatelessWidget {
  const _SeekingChip({
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.forestGreenSubtle : colors.cardSurface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected
                ? colors.forestGreen.withValues(alpha: 0.7)
                : colors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: isSelected ? colors.forestGreen : colors.primaryText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── 照片區塊 ──────────────────────────────────────────────────────────────────

class _PhotosSection extends StatelessWidget {
  const _PhotosSection({
    required this.photoUrlsAsync,
    required this.photoPending,
    required this.colors,
    required this.onManageTap,
  });
  final AsyncValue<List<String>> photoUrlsAsync;
  final bool photoPending;
  final AppColors colors;
  final VoidCallback? onManageTap; // null = disabled (審核中)

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: photoUrlsAsync.when(
        loading: () => SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(
              color: colors.forestGreen, strokeWidth: 2,
            ),
          ),
        ),
        error: (_, __) => const SizedBox(height: 8),
        data: (urls) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 照片小縮圖列
            if (urls.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: urls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: CachedNetworkImage(
                      imageUrl: urls[i],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 80,
                        height: 80,
                        color: colors.forestDeep,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: colors.forestDeep,
                        child: Icon(Icons.broken_image_outlined,
                            color: colors.secondaryText, size: 24),
                      ),
                    ),
                  ),
                ),
              ),
            if (urls.isNotEmpty) const SizedBox(height: AppSpacing.md),
            // 管理照片按鈕（審核中時禁用）
            OutlinedButton.icon(
              onPressed: onManageTap,
              icon: Icon(
                Icons.photo_library_outlined,
                size: 18,
                color: onManageTap != null
                    ? colors.forestGreen
                    : colors.secondaryText.withValues(alpha: 0.4),
              ),
              label: Text(
                urls.isEmpty ? l10n.editProfileSectionPhotos : '管理照片',
                style: textTheme.labelMedium?.copyWith(
                  color: onManageTap != null
                      ? colors.forestGreen
                      : colors.secondaryText.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: onManageTap != null
                      ? colors.forestGreen.withValues(alpha: 0.5)
                      : colors.divider,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),

            // 審核中狀態說明（按鈕下方）
            if (photoPending) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.hourglass_top_rounded,
                    size: 14,
                    color: colors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.editPhotosPendingStatus,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.warning,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 跳轉行（興趣 / 問答）────────────────────────────────────────────────────

class _NavigationRow extends StatelessWidget {
  const _NavigationRow({
    required this.label,
    required this.buttonLabel,
    required this.colors,
    required this.onTap,
  });
  final String label;
  final String buttonLabel;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: colors.secondaryText),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  buttonLabel,
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.forestGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 18, color: colors.forestGreen),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
