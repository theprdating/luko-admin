import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/auth/sign_out.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/exit_on_double_back_scope.dart';
import '../../../../../core/widgets/luko_button.dart';
import '../../../../../core/widgets/luko_text_field.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/app_user_status.dart';
import '../../../providers/apply_provider.dart';
import '../../../providers/auth_provider.dart';

/// 申請 Step 2 — 基本資料（正式）或 Step 1 — 基本資料（Beta 精簡流程）
///
/// 路由：/apply/info（正式流程）或 /dev/apply-info（開發測試）
/// 填寫：顯示名稱、生日（需滿 18 歲，Beta 流程略過）、性別、想認識的對象
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

  /// beta 預填是否已執行（避免 watch 觸發重複覆蓋用戶已修改的值）
  bool _betaPrefillDone = false;

  @override
  void initState() {
    super.initState();
    // Dev 模式不從 provider 預填，避免汙染真實流程的資料
    if (!widget.isDevMode) {
      final saved = ref.read(applyFormProvider);
      debugPrint('[ApplyInfo] initState saved=$saved displayName=${saved.displayName} gender=${saved.gender} seeking=${saved.seeking}');
      _nameController.text = saved.displayName;
      _birthDate = saved.birthDate;
      _gender = saved.gender;
      _seeking = saved.seeking.isNotEmpty ? saved.seeking.first : '';
      // 若 applyFormProvider 已有資料（例如用戶返回此頁），視為預填已完成
      if (saved.displayName.isNotEmpty) _betaPrefillDone = true;
      debugPrint('[ApplyInfo] initState _betaPrefillDone=$_betaPrefillDone');
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
  void _onNext(AppLocalizations l10n, {bool isBetaMode = false}) {
    if (!_validate(l10n)) return;

    final notifier = ref.read(applyFormProvider.notifier);
    final seekingList = [_seeking];

    if (isBetaMode) {
      // Beta 模式：先用 setInfo 存基本資料（含生日），再保留 bio + photos
      final saved = ref.read(applyFormProvider);
      notifier.setInfo(
        displayName: _nameController.text.trim(),
        birthDate: _birthDate!,
        gender: _gender,
        seeking: seekingList,
      );
      // setInfo 會 copyWith，不會清掉 bio/uploadedPhotoPaths
      // 但 prefillForBeta 會重建整個 state，改成直接用 copyWith 補回
      notifier.restoreBetaExtras(
        bio: saved.bio,
        uploadedPhotoPaths: saved.uploadedPhotoPaths,
      );
    } else {
      notifier.setInfo(
        displayName: _nameController.text.trim(),
        birthDate: _birthDate!,
        gender: _gender,
        seeking: seekingList,
      );
    }

    context.go(widget.isDevMode ? '/dev/apply-photos' : '/apply/photos');
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final isBetaMode = ref.watch(appUserStatusProvider).when(
      data: (s) => s == AppUserStatus.betaOnboarding,
      loading: () => false,
      error: (_, __) => false,
    );

    // Beta 預填：betaUserDataProvider 與 appUserStatusProvider 並行 fetch，
    // 不 gate 在 isBetaMode 後面，避免 magic link 多次 auth event 導致 isBetaMode
    // 一直停在 loading=false 而永遠不觸發 watch。
    // betaUserDataProvider 對非白名單用戶回傳 null → whenData no-op，無副作用。
    if (!_betaPrefillDone && !widget.isDevMode) {
      final betaAsync = ref.watch(betaUserDataProvider);
      debugPrint('[ApplyInfo] betaAsync=${betaAsync.runtimeType} value=${betaAsync.valueOrNull} isBetaMode=$isBetaMode');
      betaAsync.whenData((betaData) {
        debugPrint('[ApplyInfo] betaData=$betaData _betaPrefillDone=$_betaPrefillDone');
        if (betaData == null) return;
        // addPostFrameCallback 確保不在 build 執行期間呼叫 setState
        WidgetsBinding.instance.addPostFrameCallback((_) {
          debugPrint('[ApplyInfo] postFrame mounted=$mounted _betaPrefillDone=$_betaPrefillDone');
          if (!mounted || _betaPrefillDone) return;
          final name = betaData['display_name'] as String? ?? '';
          final gender = betaData['gender'] as String? ?? '';
          final rawSeeking = betaData['seeking'] as List?;
          final seekingFirst = rawSeeking?.isNotEmpty == true
              ? rawSeeking!.first as String
              : '';
          debugPrint('[ApplyInfo] prefilling name=$name gender=$gender seeking=$seekingFirst');
          // ["male","female"] 在封測資料代表「都可以」，對應 UI 的 'everyone'
          final resolvedSeeking = (rawSeeking != null &&
                  rawSeeking.length >= 2 &&
                  rawSeeking.contains('male') &&
                  rawSeeking.contains('female'))
              ? 'everyone'
              : seekingFirst;
          _betaPrefillDone = true;
          setState(() {
            if (_nameController.text.isEmpty) _nameController.text = name;
            if (_gender.isEmpty) _gender = gender;
            if (_seeking.isEmpty) _seeking = resolvedSeeking;
          });
          // prefillForBeta 同步到 provider，讓 bio / photos 頁面也能讀到預填資料
          ref.read(applyFormProvider.notifier).prefillForBeta(
            displayName: _nameController.text,
            gender: _gender,
            seeking: _seeking.isNotEmpty ? [_seeking] : [],
            bio: betaData['bio'] as String? ?? '',
            uploadedPhotoPaths:
                (betaData['photo_paths'] as List?)?.cast<String>().toList() ??
                const [],
          );
        });
      });
    }

    // 第一步無上一步：硬體返回鍵攔截為雙按退出 APP
    return ExitOnDoubleBackScope(
      child: Scaffold(
      backgroundColor: colors.backgroundWarm,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: colors.backgroundWarm,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () async {
            if (widget.isDevMode) {
              context.go('/dev/state-picker');
              return;
            }
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) {
                final l10n = AppLocalizations.of(ctx)!;
                return AlertDialog(
                  title: Text(l10n.applyLeaveDialogTitle),
                  content: Text(l10n.applyLeaveDialogBody),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(l10n.commonCancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(l10n.applyLeaveDialogConfirm),
                    ),
                  ],
                );
              },
            );
            if (confirmed != true) return;
            await signOutAll();
            // signOut 後 authStateProvider emit → _RouterNotifier 觸發 redirect
            // GoRouter 自動導向 /onboarding 或 /welcome，無需手動 context.go()
          },
        ),
        title: Text(
          isBetaMode ? l10n.applyStep(1, 3) : l10n.applyStep(2, 6),
          style: textTheme.labelMedium?.copyWith(
            color: colors.secondaryText,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
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
                isBetaMode ? l10n.betaApplyInfoSubtitle : l10n.applyInfoSubtitle,
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

              // ── 生日（所有用戶都需填寫）──────────────────────────────────
              ...[
                _BirthDateField(
                  birthDate: _birthDate,
                  errorText: _birthDateError,
                  label: l10n.applyBirthDateLabel,
                  hint: l10n.applyBirthDateHint,
                  onTap: _pickBirthDate,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

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
                onPressed: () => _onNext(l10n, isBetaMode: isBetaMode),
              ),
            ],
          ),
        ),
      ),
      ), // GestureDetector
    ),   // Scaffold
    );   // ExitOnDoubleBackScope
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
          onTap: () {
            // 先收鍵盤焦點，再開日期選擇器
            FocusManager.instance.primaryFocus?.unfocus();
            onTap();
          },
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
      onTap: () {
        // 收鍵盤焦點後再觸發選取
        FocusManager.instance.primaryFocus?.unfocus();
        onTap();
      },
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
