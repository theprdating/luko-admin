import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_spacing.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens（與 welcome_page / onboarding_page 完全一致）
// ─────────────────────────────────────────────────────────────────────────────

const _kBgBase   = Color(0xFF0F1E15);
const _kBgHeader = Color(0xFF0C1912); // 比底色略深，讓 header 有層次
const _kBgCard   = Color(0xFF162E24);
const _kGold     = Color(0xFFC9A96E);
const _kTitle    = Color(0xFFF0FDF4);
const _kBody     = Color(0x99E8F5EB); // 60% 微綠白
const _kMuted    = Color(0x4DE8F5EB); // 30%
const _kCaption  = Color(0x61FFFFFF); // 38%

// 公開常數供 TermsPage / PrivacyPage 使用
const kLegalCompany = 'Luko Inc.';
const kLegalEmail   = 'legal@luko.tw';

// ─────────────────────────────────────────────────────────────────────────────
// LegalScaffold — 法律文件頁面共用骨架
//
// 提供：
//   ① 吸頂品牌列（LUKO logo + 金色捲動進度條）
//   ② 入場動畫（鏡像 welcome_page 四段 Phase：標題 → 金線展開 → 副標 → 內容）
//   ③ 全頁捲動容器（children 為各章節 Widget）
// ─────────────────────────────────────────────────────────────────────────────

class LegalScaffold extends StatefulWidget {
  const LegalScaffold({
    super.key,
    required this.docTitle,
    required this.docSubtitle,
    required this.version,
    required this.date,
    required this.children,
  });

  /// 中文大標，e.g. '使用者條款'
  final String docTitle;

  /// 英文副標，e.g. 'Terms of Service'
  final String docSubtitle;

  final String version;
  final String date;
  final List<Widget> children;

  @override
  State<LegalScaffold> createState() => _LegalScaffoldState();
}

class _LegalScaffoldState extends State<LegalScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _scrollCtrl = ScrollController();
  double _scrollProgress = 0.0;

  // 入場動畫（鏡像 welcome_page 的四段時序）
  late final Animation<double> _titleFade;
  late final Animation<double> _lineWidth;
  late final Animation<double> _captionFade;
  late final Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    _titleFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.00, 0.45, curve: Curves.easeOut),
    );
    _lineWidth = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.20, 0.68, curve: Curves.easeOut),
    );
    _captionFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.38, 0.75, curve: Curves.easeOut),
    );
    _contentFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.52, 1.00, curve: Curves.easeOut),
    );

    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final max = _scrollCtrl.position.maxScrollExtent;
    if (max <= 0) return;
    final v = (_scrollCtrl.offset / max).clamp(0.0, 1.0);
    if ((v - _scrollProgress).abs() > 0.004) {
      setState(() => _scrollProgress = v);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad    = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _kBgBase,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── ① 吸頂品牌列 ────────────────────────────────────────────────
          _StickyHeader(
            topPadding: topPad,
            progress: _scrollProgress,
            onBack: () => Navigator.maybePop(context),
          ),

          // ── ② 捲動正文（入場動畫包裹） ──────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  0,
                  AppSpacing.pagePadding,
                  bottomPad + 56,
                ),
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 36),

                      // ── Hero：大標題 ─────────────────────────────────
                      Opacity(
                        opacity: _titleFade.value,
                        child: Transform.translate(
                          offset: Offset(0, 26 * (1 - _titleFade.value)),
                          child: Text(
                            widget.docTitle,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 44,
                              fontWeight: FontWeight.w300,
                              letterSpacing: -0.5,
                              height: 1.08,
                              color: _kTitle,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Hero：金線（鏡像 welcome_page 展開效果）──────
                      Opacity(
                        opacity: _titleFade.value,
                        child: _ExpandingLine(progress: _lineWidth.value),
                      ),

                      const SizedBox(height: 14),

                      // ── Hero：英文副標（「CURATED DATING」風格）───────
                      Opacity(
                        opacity: _captionFade.value,
                        child: Text(
                          widget.docSubtitle.toUpperCase(),
                          style: GoogleFonts.dmSans(
                            fontSize: 9.0,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 4.5,
                            color: _kCaption,
                            height: 1.0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ── Hero：版本 badge ──────────────────────────────
                      Opacity(
                        opacity: _captionFade.value,
                        child: _VersionBadge(
                          version: widget.version,
                          date: widget.date,
                        ),
                      ),

                      const SizedBox(height: 44),

                      // ── 分隔線 ────────────────────────────────────────
                      Opacity(
                        opacity: _captionFade.value,
                        child: Container(
                          height: 0.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _kGold.withValues(alpha: 0.0),
                                _kGold.withValues(alpha: 0.28),
                                _kGold.withValues(alpha: 0.28),
                                _kGold.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.2, 0.8, 1.0],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── 內容區（延遲淡入） ─────────────────────────────
                      Opacity(
                        opacity: _contentFade.value,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.children,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 吸頂品牌列
// ─────────────────────────────────────────────────────────────────────────────

class _StickyHeader extends StatelessWidget {
  const _StickyHeader({
    required this.topPadding,
    required this.progress,
    required this.onBack,
  });
  final double topPadding;
  final double progress;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBgHeader,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(4, topPadding + 8, AppSpacing.pagePadding, 8),
            child: Row(
              children: [
                // 返回
                GestureDetector(
                  onTap: onBack,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0x55FFFFFF),
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Image.asset(
                  'assets/images/app_icon_white.png',
                  height: 20,
                  width: 17,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const SizedBox(width: 17, height: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  'LUKO',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 5.0,
                    color: _kTitle.withValues(alpha: 0.70),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          // 金色捲動進度條
          _ProgressBar(progress: progress),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 捲動進度條
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) => Stack(
        children: [
          Container(
            height: 1.5,
            color: _kGold.withValues(alpha: 0.07),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            height: 1.5,
            width: constraints.maxWidth * progress,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _kGold.withValues(alpha: 0.45),
                  _kGold,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 金線（從左向右展開，鏡像 welcome_page 的 _ExpandingLine）
// ─────────────────────────────────────────────────────────────────────────────

class _ExpandingLine extends StatelessWidget {
  const _ExpandingLine({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    const maxWidth = 48.0;
    return SizedBox(
      width: maxWidth,
      height: 1.0,
      child: ClipRect(
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: progress,
          child: Container(
            width: maxWidth,
            height: 1.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _kGold,
                  _kGold,
                  _kGold.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.65, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 版本 Badge
// ─────────────────────────────────────────────────────────────────────────────

class _VersionBadge extends StatelessWidget {
  const _VersionBadge({required this.version, required this.date});
  final String version;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kBgCard,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: _kGold.withValues(alpha: 0.18),
          width: 0.8,
        ),
      ),
      child: Text(
        '$version　·　$date',
        style: GoogleFonts.dmSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.3,
          color: _kGold.withValues(alpha: 0.60),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 以下為公開 Widget，供 TermsPage / PrivacyPage 直接使用
// ═════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// LegalSection — 章節標題
//
// 視覺設計（Wick 風格）：
//   大型裝飾數字（Playfair Display，極低透明度金色，60px）
//   + 右側小標題組（短金線 + DM Sans 金色文字）
//   編輯感排版，空間留白讓數字成為背景層
// ─────────────────────────────────────────────────────────────────────────────

class LegalSection extends StatelessWidget {
  const LegalSection({super.key, required this.number, required this.title});
  final String number; // e.g. '01'
  final String title;  // e.g. '服務性質與精選機制'

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 大裝飾數字（背景層，極淡）
          Text(
            number,
            style: GoogleFonts.playfairDisplay(
              fontSize: 62,
              fontWeight: FontWeight.w300,
              letterSpacing: -2.0,
              color: _kGold.withValues(alpha: 0.09),
              height: 0.95,
            ),
          ),
          const SizedBox(width: 16),
          // 標題組（短線 + 文字）
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 0.8,
                    color: _kGold.withValues(alpha: 0.45),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.4,
                      color: _kGold,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LegalClause — 條文段落
// ─────────────────────────────────────────────────────────────────────────────

class LegalClause extends StatelessWidget {
  const LegalClause(this.text, {super.key, this.isBold = false});
  final String text;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: isBold ? FontWeight.w500 : FontWeight.w400,
          letterSpacing: 0.05,
          height: 1.90,
          color: isBold
              ? _kTitle.withValues(alpha: 0.88)
              : _kBody,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LegalBullet — 圓點列舉
// ─────────────────────────────────────────────────────────────────────────────

class LegalBullet extends StatelessWidget {
  const LegalBullet(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              width: 2.5,
              height: 2.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kGold.withValues(alpha: 0.42),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.05,
                height: 1.90,
                color: _kBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LegalNotice — 重要提示框（左側金色邊線）
// ─────────────────────────────────────────────────────────────────────────────

class LegalNotice extends StatelessWidget {
  const LegalNotice(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 4),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: _kBgCard,
        borderRadius: BorderRadius.circular(7),
        border: Border(
          left: BorderSide(
            color: _kGold.withValues(alpha: 0.55),
            width: 2,
          ),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.05,
          height: 1.80,
          color: _kGold.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LegalSubheading — 小節子標題
// ─────────────────────────────────────────────────────────────────────────────

class LegalSubheading extends StatelessWidget {
  const LegalSubheading(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          height: 1.4,
          color: _kTitle.withValues(alpha: 0.78),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LegalFooter — 頁底版權標示
// ─────────────────────────────────────────────────────────────────────────────

class LegalFooter extends StatelessWidget {
  const LegalFooter(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _kGold.withValues(alpha: 0.0),
                  _kGold.withValues(alpha: 0.16),
                  _kGold.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
              color: _kMuted,
            ),
          ),
        ],
      ),
    );
  }
}
