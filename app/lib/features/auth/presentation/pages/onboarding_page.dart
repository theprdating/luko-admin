import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/analytics/analytics_events.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/shared_prefs_provider.dart';
import '../../../../l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — app icon (#1E3D2F) + welcome page gold (#C9A96E) 同一色系
// ─────────────────────────────────────────────────────────────────────────────

const _kBgTop    = Color(0xFF0F1E15); // 深森林綠底色
const _kBgBottom = Color(0xFF0F1E15); // 與頂部同色，純色背景更沉穩

const _kGold    = Color(0xFFC9A96E); // 品牌金（與 welcome_page 一致）
const _kPageNum = Color(0xFF8CB8A3); // 鼠尾草綠，頁碼專用（低調輔助）

// 文字
const _kTitle = Color(0xFFF0FDF4); // 微綠調近白
const _kBody  = Color(0x8CE8F5EB); // 55% 微綠白
const _kQuote = Color(0x61FFFFFF); // 38% 白（背景層）

// 進度條
const _kSegActive   = _kBtnGhostText;   // 與「繼續」按鈕文字同色，視覺呼應
const _kSegInactive = Color(0xFF1C3223); // 深森林綠 inactive，貼近背景

// 按鈕
const _kBtnSolidBg     = Color(0xFFEDF7F0);
const _kBtnSolidText   = Color(0xFF0F1E15);
const _kBtnGhostBorder = Color(0xFF4A7A5E);
const _kBtnGhostText   = Color(0xFF7AB595);

// ─────────────────────────────────────────────────────────────────────────────
// 背景引號系統（版面與文字分離）
// ─────────────────────────────────────────────────────────────────────────────

class _Q {
  const _Q({required this.text, required this.topFraction, this.left, this.right, required this.delay});
  final String text;
  final double topFraction;
  final double? left;
  final double? right;
  final double delay;
}

class _QLayout {
  const _QLayout({required this.topFraction, this.left, this.right, required this.delay});
  final double topFraction;
  final double? left;
  final double? right;
  final double delay;
}

const _kQuoteLayout = [
  _QLayout(topFraction: 0.044, left:  22, delay: 0.40),
  _QLayout(topFraction: 0.147, right: 50, delay: 0.52),
  _QLayout(topFraction: 0.279, left:  50, delay: 0.62),
  _QLayout(topFraction: 0.560, right: 24, delay: 0.70),
  _QLayout(topFraction: 0.810, left:  20, delay: 0.77),
  _QLayout(topFraction: 0.935, right: 22, delay: 0.83),
];

List<String> _quoteTexts(AppLocalizations l10n, int pageIndex) {
  switch (pageIndex) {
    case 0: return [
      l10n.onboarding1Quote1, l10n.onboarding1Quote2, l10n.onboarding1Quote3,
      l10n.onboarding1Quote4, l10n.onboarding1Quote5, l10n.onboarding1Quote6,
    ];
    case 1: return [
      l10n.onboarding2Quote1, l10n.onboarding2Quote2, l10n.onboarding2Quote3,
      l10n.onboarding2Quote4, l10n.onboarding2Quote5, l10n.onboarding2Quote6,
    ];
    case 2: return [
      l10n.onboarding3Quote1, l10n.onboarding3Quote2, l10n.onboarding3Quote3,
      l10n.onboarding3Quote4, l10n.onboarding3Quote5, l10n.onboarding3Quote6,
    ];
    default: return List.filled(6, '');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingPage
// ─────────────────────────────────────────────────────────────────────────────

/// Onboarding 理念頁 — 3 頁 PageView，路由：/onboarding，無略過按鈕
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;
  static const _totalPages = 3;

  // 按鈕可見性：由投影片動畫閾值驅動，而非固定 Timer
  bool _btnVisible = false;

  // 水印：只在第一次進入時從透明淡入，之後固定顯示
  bool _watermarkVisible = false;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).track(AnalyticsEvents.onboardingStarted);
    // 標題 Interval [0.22, 0.58]，動畫 2750ms + initialDelay 200ms
    // 標題開始時間 = 200 + 0.22×2750 ≈ 805ms
    Future.delayed(const Duration(milliseconds: 805), () {
      if (mounted) setState(() => _watermarkVisible = true);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 由 _SlidePage 在動畫到達閾值時呼叫
  void _onSlideReady() {
    if (mounted && !_btnVisible) setState(() => _btnVisible = true);
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _btnVisible = false;  // 換頁時隱藏，等新頁動畫跑到閾值再浮現
    });
    ref.read(analyticsProvider).onboardingSlide(page + 1);
  }

  void _next() {
    if (!_btnVisible) return;       // 動畫未就緒，忽略
    setState(() => _btnVisible = false); // 立即鎖定，防快速連按
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 440),
        curve: Curves.easeInOut,
      );
    } else {
      _markSeenAndProceed();
    }
  }

  void _markSeenAndProceed() {
    ref.read(analyticsProvider).track(AnalyticsEvents.onboardingCompleted);
    // setBool in-memory 立即更新，disk 寫入背景進行，不需 await 才能導航
    ref.read(sharedPreferencesProvider).setBool('luko.onboarding_shown', true);
    context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLastPage = _currentPage == _totalPages - 1;

    final slides = [
      _SlideData(index: 1, title: l10n.onboarding1Title, body: l10n.onboarding1Body),
      _SlideData(index: 2, title: l10n.onboarding2Title, body: l10n.onboarding2Body),
      _SlideData(index: 3, title: l10n.onboarding3Title, body: l10n.onboarding3Body),
    ];

    return Scaffold(
      backgroundColor: _kBgTop,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kBgTop, _kBgBottom],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 品牌頂欄（logo mark + wordmark + 金色分隔線）──────────
              const _BrandHeader(),

              // ── 投影片 ─────────────────────────────────────────────
              // LayoutBuilder 取得可用高度，讓水印比例與原設計一致
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final h = constraints.maxHeight;
                    return Stack(
                      children: [
                        // 固定水印：PageView 外層，滑動換頁時不跟著位移
                        // 只在第一次進入時淡入（_watermarkVisible 不因換頁重置）
                        Positioned(
                          right: -h * 0.12,
                          top: h * 0.08,
                          child: IgnorePointer(
                            child: AnimatedOpacity(
                              opacity: _watermarkVisible ? 0.055 : 0.0,
                              duration: const Duration(milliseconds: 990),
                              curve: Curves.easeOut,
                              child: Image.asset(
                                'assets/images/app_icon_white.png',
                                height: h * 0.70,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                        // 換頁內容（文字、引號）在此滑動
                        PageView.builder(
                          controller: _pageController,
                          physics: _btnVisible
                              ? null
                              : const NeverScrollableScrollPhysics(),
                          onPageChanged: _onPageChanged,
                          itemCount: _totalPages,
                          itemBuilder: (context, index) => _SlidePage(
                            key: ValueKey(index),
                            data: slides[index],
                            initialDelay: index == 0
                                ? const Duration(milliseconds: 200)
                                : Duration.zero,
                            onReady: _onSlideReady,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ── 底部：進度條 + 按鈕 ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, 0,
                  AppSpacing.pagePadding, 36,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SegmentBar(total: _totalPages, current: _currentPage),
                    const SizedBox(height: 22),
                    // 動畫到閾值前完全透明且不可互動
                    // AnimatedSwitcher 已移除：按鈕在 opacity=0 時 label
                    // 瞬間切換不可見，不需要額外動畫，也避免 onPageChanged
                    // 在滑動 50% 時提早觸發 isLastPage 導致 label 閃現。
                    AnimatedOpacity(
                      opacity: _btnVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                      child: IgnorePointer(
                        ignoring: !_btnVisible,
                        child: _CtaButton(
                          label: isLastPage
                              ? l10n.onboardingGetStarted
                              : l10n.onboardingContinue,
                          isLast: isLastPage,
                          onTap: _btnVisible ? _next : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 品牌頂欄
//
// 展示 app icon 雙側臉標誌 + LUKO wordmark + 金色分隔線
// 與 welcome page 的視覺語言建立連貫性
// ─────────────────────────────────────────────────────────────────────────────

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App icon mark（白色雙側臉輪廓）
              Image.asset(
                'assets/images/app_icon_white.png',
                height: 26,
                width: 22,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 22,
                  height: 26,
                ),
              ),
              const SizedBox(width: 10),
              // LUKO wordmark
              Text(
                'PR Dating',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 5.5,
                  color: _kTitle.withValues(alpha: 0.85),
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 金色分隔線
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
          child: Container(
            height: 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _kGold.withValues(alpha: 0.0),
                  _kGold.withValues(alpha: 0.35),
                  _kGold.withValues(alpha: 0.35),
                  _kGold.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 進度條
// ─────────────────────────────────────────────────────────────────────────────

class _SegmentBar extends StatefulWidget {
  const _SegmentBar({required this.total, required this.current});
  final int total;
  final int current;

  @override
  State<_SegmentBar> createState() => _SegmentBarState();
}

class _SegmentBarState extends State<_SegmentBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fill;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 680))
      ..forward();
    _fill = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(_SegmentBar old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current) _ctrl.forward(from: 0.0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const segW = 32.0;
    const h    = 2.0;
    const gap  = 8.0;

    return SizedBox(
      height: h,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < widget.total; i++) ...[
            if (i > 0) const SizedBox(width: gap),
            ClipRRect(
              borderRadius: BorderRadius.circular(h),
              child: SizedBox(
                width: segW,
                height: h,
                child: i < widget.current
                    ? const ColoredBox(color: _kSegActive)
                    : i == widget.current
                        ? AnimatedBuilder(
                            animation: _fill,
                            builder: (_, __) => Stack(
                              fit: StackFit.expand,
                              children: [
                                const ColoredBox(color: _kSegInactive),
                                FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _fill.value,
                                  child: const ColoredBox(color: _kSegActive),
                                ),
                              ],
                            ),
                          )
                        : const ColoredBox(color: _kSegInactive),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 投影片資料
// ─────────────────────────────────────────────────────────────────────────────

class _SlideData {
  const _SlideData({required this.index, required this.title, required this.body});
  final int index;
  final String title;
  final String body;
}

// ─────────────────────────────────────────────────────────────────────────────
// 單頁投影片
//
// Stack(fit: StackFit.expand) 讓整頁可放 Positioned 元素
//
// 新增：
//   - 右側雙側臉水印（app icon，極低透明度）— 呼應品牌圖示
//   - 頁碼改為品牌金色
//   - 分隔線改為品牌金色
//
// 動畫時間軸（TweenAnimationBuilder 0→1，1600ms）：
//   頁碼     [0.14 → 0.44]
//   標題     [0.22 → 0.58]
//   內文     [0.40 → 0.68]
//   引號 Q1–Q6  依序浮現
// ─────────────────────────────────────────────────────────────────────────────

class _SlidePage extends StatefulWidget {
  const _SlidePage({
    super.key,
    required this.data,
    this.initialDelay = Duration.zero,
    this.onReady,
  });
  final _SlideData data;
  final Duration initialDelay;
  /// 動畫到達閾值（v ≥ 0.72）時呼叫一次，通知父層可顯示按鈕
  final VoidCallback? onReady;

  @override
  State<_SlidePage> createState() => _SlidePageState();
}

class _SlidePageState extends State<_SlidePage> {
  bool _animating = false;
  bool _readyCalled = false; // 確保 onReady 每頁只觸發一次

  @override
  void initState() {
    super.initState();
    if (widget.initialDelay == Duration.zero) {
      _animating = true;
    } else {
      Future.delayed(widget.initialDelay, () {
        if (mounted) setState(() => _animating = true);
      });
    }
  }

  static double _ease(double v, double start, double end) {
    if (v <= start) return 0.0;
    if (v >= end) return 1.0;
    return Curves.easeOut.transform((v - start) / (end - start));
  }

  Widget _quote(double v, _Q q, double stackHeight) {
    final qV = _ease(v, q.delay, q.delay + 0.28);
    return Positioned(
      top: q.topFraction * stackHeight,
      left: q.left,
      right: q.right,
      child: IgnorePointer(
        child: Opacity(
          opacity: qV * 0.42,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - qV)),
            child: Text(
              q.text,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: _kQuote,
                height: 1.5,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final texts = _quoteTexts(l10n, widget.data.index - 1);
    final quotes = List.generate(
      6,
      (i) => _Q(
        text: texts[i],
        topFraction: _kQuoteLayout[i].topFraction,
        left: _kQuoteLayout[i].left,
        right: _kQuoteLayout[i].right,
        delay: _kQuoteLayout[i].delay,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackHeight = constraints.maxHeight;

        return TweenAnimationBuilder<double>(
          key: ValueKey(_animating),
          tween: Tween(begin: 0.0, end: _animating ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 2750),
          builder: (context, v, _) {
            final numV   = _ease(v, 0.14, 0.44);
            final titleV = _ease(v, 0.22, 0.58);
            final bodyV  = _ease(v, 0.40, 0.68);

            // v=0.72：body 已完整顯示後的一幀，通知父層浮現按鈕
            if (!_readyCalled && v >= 0.72 && widget.onReady != null) {
              _readyCalled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) widget.onReady!();
              });
            }

            return Stack(
              fit: StackFit.expand,
              children: [

                // ── 背景：引號抱怨文字 ───────────────────────────────
                for (final q in quotes) _quote(v, q, stackHeight),

                // ── 前景：主文字內容 ────────────────────────────────
                Positioned(
                  top: stackHeight * 0.32,
                  left: AppSpacing.pagePadding,
                  right: AppSpacing.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 頁碼（金色）
                      Opacity(
                        opacity: numV,
                        child: Transform.translate(
                          offset: Offset(0, 8 * (1 - numV)),
                          child: Text(
                            '0${widget.data.index}',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 4.0,
                              color: _kPageNum, // 鼠尾草綠頁碼
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 主標題
                      Opacity(
                        opacity: titleV,
                        child: Transform.translate(
                          offset: Offset(0, 36 * (1 - titleV)),
                          child: Text(
                            widget.data.title,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 40,
                              fontWeight: FontWeight.w300,
                              letterSpacing: -0.5,
                              height: 1.14,
                              color: _kTitle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 分隔線（金色）
                      Opacity(
                        opacity: titleV,
                        child: Container(
                          width: 24,
                          height: 1.5,
                          decoration: BoxDecoration(
                            color: _kPageNum.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 內文
                      Opacity(
                        opacity: bodyV,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - bodyV)),
                          child: Text(
                            widget.data.body,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.1,
                              height: 1.90,
                              color: _kBody,
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA 按鈕
// Pages 1-2 : ghost / Page 3 : solid
// ─────────────────────────────────────────────────────────────────────────────

class _CtaButton extends StatelessWidget {
  const _CtaButton({
    super.key,
    required this.label,
    required this.isLast,
    required this.onTap,
  });

  final String label;
  final bool isLast;
  final VoidCallback? onTap;  // null = 停用狀態，GestureDetector 不觸發

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
        height: 54,
        decoration: BoxDecoration(
          color: isLast ? _kBtnSolidBg : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLast ? Colors.transparent : _kBtnGhostBorder,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeInOut,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: isLast ? _kBtnSolidText : _kBtnGhostText,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
