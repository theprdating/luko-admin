import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/luko_button.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../providers/apply_provider.dart';

/// 申請 Step 5 — 自我介紹（選填）
///
/// 路由：/apply/bio（正式）或 /dev/apply-bio（開發測試）
/// 最多 150 字，可略過直接前往 Step 6
class ApplyBioPage extends ConsumerStatefulWidget {
  const ApplyBioPage({super.key, this.isDevMode = false});

  /// true → back 回 /dev/apply-verify，next/skip 跳 /dev/apply-confirm
  final bool isDevMode;

  @override
  ConsumerState<ApplyBioPage> createState() => _ApplyBioPageState();
}

class _ApplyBioPageState extends ConsumerState<ApplyBioPage> {
  static const int _maxLength = 150;

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // 返回此頁面時恢復已輸入的 bio
    _controller = TextEditingController(
      text: ref.read(applyFormProvider).bio,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _proceed() {
    ref.read(applyFormProvider.notifier).setBio(_controller.text.trim());
    context.go(widget.isDevMode ? '/dev/apply-confirm' : '/apply/confirm');
  }

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
            widget.isDevMode ? '/dev/apply-verify' : '/apply/verify',
          ),
        ),
        title: Text(
          l10n.applyStep(5, 6),
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
                l10n.applyBioTitle,
                style: textTheme.headlineMedium?.copyWith(
                  color: colors.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.applyBioSubtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.secondaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Bio 輸入框 + 字數計數 ─────────────────────────────────
              _BioInputField(
                controller: _controller,
                maxLength: _maxLength,
                hint: l10n.applyBioHint,
                helperText: l10n.applyBioHelper,
              ),

              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
      ), // GestureDetector

      // ── 底部按鈕 ──────────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.sm,
            AppSpacing.pagePadding,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              // 略過
              Expanded(
                child: LukoButton.secondary(
                  label: l10n.commonSkip,
                  onPressed: () {
                    // 略過時清空 bio
                    ref.read(applyFormProvider.notifier).setBio('');
                    context.go(
                      widget.isDevMode ? '/dev/apply-confirm' : '/apply/confirm',
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // 下一步
              Expanded(
                flex: 2,
                child: LukoButton.primary(
                  label: l10n.commonNext,
                  onPressed: _proceed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bio 輸入框（多行 + 自訂字數計數）────────────────────────────────────────────
//
// 用 ValueListenableBuilder 監聽 controller，只有字數改變時才 rebuild 計數器，
// 不需要整個 State rebuild。

class _BioInputField extends StatelessWidget {
  const _BioInputField({
    required this.controller,
    required this.maxLength,
    required this.hint,
    required this.helperText,
  });

  final TextEditingController controller;
  final int maxLength;
  final String hint;
  final String helperText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 輸入框 ─────────────────────────────────────────────────────
        TextField(
          controller: controller,
          maxLines: null,     // 無限換行
          minLines: 5,        // 初始顯示高度
          maxLength: maxLength,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          style: textTheme.bodyLarge?.copyWith(color: colors.primaryText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: textTheme.bodyLarge?.copyWith(
              color: colors.secondaryText.withValues(alpha: 0.6),
            ),
            counterText: '',   // 隱藏預設計數，用下方自訂版本
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

        // ── 字數計數（右對齊）+ 說明文字（左對齊）───────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              helperText,
              style: textTheme.bodySmall?.copyWith(
                color: colors.secondaryText,
              ),
            ),
            // ValueListenableBuilder：只在 controller 內容改變時重建計數器
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, __) {
                final count = value.text.length;
                final isNearLimit = count >= maxLength * 0.9;
                return Text(
                  '$count / $maxLength',
                  style: textTheme.bodySmall?.copyWith(
                    color: isNearLimit ? colors.warning : colors.secondaryText,
                    fontWeight:
                        isNearLimit ? FontWeight.w600 : FontWeight.normal,
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
