import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/luko_button.dart';
import '../../../../../core/widgets/luko_text_field.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../providers/apply_provider.dart';

/// 申請 Step 2 — 基本資料
///
/// 路由：/apply/info（正式流程）或 /dev/apply-info（開發測試）
/// 填寫：顯示名稱、生日（需滿 18 歲）、性別、想認識的對象
/// 完成後導向 /apply/photos（正式）或 /dev/apply-photos（dev 模式）
class ApplyInfoPage extends ConsumerStatefulWidget {
  const ApplyInfoPage({super.key, this.isDevMode = false});

  /// true → 跳過 applyFormProvider 寫入並返回 dev 選擇器，不進入正式流程
  final bool isDevMode;

  @override
  ConsumerState<ApplyInfoPage> createState() => _ApplyInfoPageState();
}

class _ApplyInfoPageState extends ConsumerState<ApplyInfoPage> {
  final _nameController = TextEditingController();
  DateTime? _birthDate;
  String _gender = '';
  String _seeking = '';

  // 錯誤訊息
  String? _nameError;
  String? _birthDateError;
  String? _genderError;
  String? _seekingError;

  @override
  void initState() {
    super.initState();
    // Dev 模式不從 provider 預填，避免汙染真實流程的資料
    if (!widget.isDevMode) {
      final saved = ref.read(applyFormProvider);
      _nameController.text = saved.displayName;
      _birthDate = saved.birthDate;
      _gender = saved.gender;
      _seeking = saved.seeking.isNotEmpty ? saved.seeking.first : '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ── 驗證 ────────────────────────────────────────────────────────────────────
  bool _validate(AppLocalizations l10n) {
    final name = _nameController.text.trim();
    String? nameErr, birthErr, genderErr, seekingErr;

    if (name.isEmpty) nameErr = l10n.applyNameEmpty;
    if (_birthDate == null) {
      birthErr = l10n.applyBirthDateEmpty;
    } else if (!_isAtLeast18(_birthDate!)) {
      birthErr = l10n.applyAgeError;
    }
    if (_gender.isEmpty) genderErr = l10n.applyGenderEmpty;
    if (_seeking.isEmpty) seekingErr = l10n.applySeekingEmpty;

    setState(() {
      _nameError = nameErr;
      _birthDateError = birthErr;
      _genderError = genderErr;
      _seekingError = seekingErr;
    });

    return nameErr == null && birthErr == null && genderErr == null && seekingErr == null;
  }

  bool _isAtLeast18(DateTime birthDate) {
    final now = DateTime.now();
    final threshold = DateTime(now.year - 18, now.month, now.day);
    return birthDate.compareTo(threshold) <= 0;
  }

  // ── 生日選擇器 ──────────────────────────────────────────────────────────────
  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1940),
      // lastDate 為 18 年前，UI 層阻止選未成年日期
      lastDate: DateTime(now.year - 18, now.month, now.day),
      locale: Localizations.localeOf(context),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateError = null;
      });
    }
  }

  // ── 儲存並前進 ──────────────────────────────────────────────────────────────
  void _onNext(AppLocalizations l10n) {
    if (!_validate(l10n)) return;

    final seekingList = [_seeking];

    ref.read(applyFormProvider.notifier).setInfo(
      displayName: _nameController.text.trim(),
      birthDate: _birthDate!,
      gender: _gender,
      seeking: seekingList,
    );

    context.go(widget.isDevMode ? '/dev/apply-photos' : '/apply/photos');
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.backgroundWarm,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: colors.backgroundWarm,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go(
            widget.isDevMode ? '/dev/state-picker' : '/apply/phone',
          ),
        ),
        title: Text(
          l10n.applyStep(2, 6),
          style: textTheme.labelMedium?.copyWith(
            color: colors.secondaryText,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            left: AppSpacing.pagePadding,
            right: AppSpacing.pagePadding,
            top: AppSpacing.lg,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 頁面標題 ──────────────────────────────────────────────
              Text(
                l10n.applyInfoTitle,
                style: textTheme.headlineMedium?.copyWith(
                  color: colors.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.applyInfoSubtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.secondaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── 顯示名稱 ──────────────────────────────────────────────
              LukoTextField(
                controller: _nameController,
                label: l10n.applyNameLabel,
                hint: l10n.applyNameHint,
                helperText: l10n.applyNameHelper,
                errorText: _nameError,
                maxLength: 20,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── 生日 ──────────────────────────────────────────────────
              _BirthDateField(
                birthDate: _birthDate,
                errorText: _birthDateError,
                label: l10n.applyBirthDateLabel,
                hint: l10n.applyBirthDateHint,
                onTap: _pickBirthDate,
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── 性別 ──────────────────────────────────────────────────
              _SelectionRow(
                selected: _gender,
                label: l10n.applyGenderLabel,
                errorText: _genderError,
                options: [
                  _Option('male',   l10n.applyGenderMale),
                  _Option('female', l10n.applyGenderFemale),
                  _Option('other',  l10n.applyGenderOther),
                ],
                onChanged: (value) {
                  setState(() {
                    _gender = value;
                    _genderError = null;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── 想認識 ────────────────────────────────────────────────
              _SelectionRow(
                selected: _seeking,
                label: l10n.applySeekingLabel,
                errorText: _seekingError,
                options: [
                  _Option('male',     l10n.applySeekingMen),
                  _Option('female',   l10n.applySeekingWomen),
                  _Option('everyone', l10n.applySeekingEveryone),
                ],
                onChanged: (value) {
                  setState(() {
                    _seeking = value;
                    _seekingError = null;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // ── 下一步 ────────────────────────────────────────────────
              LukoButton.primary(
                label: l10n.commonNext,
                onPressed: () => _onNext(l10n),
              ),
            ],
          ),
        ),
      ),
      ), // GestureDetector
    );
  }
}

// ── 生日輸入框（只讀，點擊開 DatePicker）────────────────────────────────────────

class _BirthDateField extends StatelessWidget {
  const _BirthDateField({
    required this.birthDate,
    required this.errorText,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  final DateTime? birthDate;
  final String? errorText;
  final String label;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final hasError = errorText != null;

    final displayText = birthDate != null
        ? DateFormat('yyyy / MM / dd').format(birthDate!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: hasError ? colors.error : colors.secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.cardSurface,
              border: Border.all(
                color: hasError ? colors.error : colors.divider,
                width: hasError ? 1.5 : 1.0,
              ),
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayText ?? hint,
                    style: textTheme.bodyLarge?.copyWith(
                      color: displayText != null
                          ? colors.primaryText
                          : colors.secondaryText.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: colors.secondaryText,
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: textTheme.bodySmall?.copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }
}

// ── 選項列（性別 / 想認識 共用）──────────────────────────────────────────────────

class _Option {
  const _Option(this.value, this.label);
  final String value;
  final String label;
}

class _SelectionRow extends StatelessWidget {
  const _SelectionRow({
    required this.selected,
    required this.label,
    required this.errorText,
    required this.options,
    required this.onChanged,
  });

  final String selected;
  final String label;
  final String? errorText;
  final List<_Option> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: hasError ? colors.error : colors.secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: options.map((opt) {
            final isSelected = opt.value == selected;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: opt == options.last ? 0 : AppSpacing.sm,
                ),
                child: _SelectionButton(
                  label: opt.label,
                  isSelected: isSelected,
                  hasError: hasError,
                  onTap: () => onChanged(opt.value),
                ),
              ),
            );
          }).toList(),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: textTheme.bodySmall?.copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }
}

class _SelectionButton extends StatelessWidget {
  const _SelectionButton({
    required this.label,
    required this.isSelected,
    required this.hasError,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final borderColor = isSelected
        ? colors.forestGreen
        : hasError
            ? colors.error
            : colors.divider;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? colors.forestGreenSubtle : colors.cardSurface,
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            color: isSelected ? colors.forestGreen : colors.primaryText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
