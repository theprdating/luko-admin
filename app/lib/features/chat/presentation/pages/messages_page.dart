import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../discover/application/match_providers.dart';
import '../../../discover/data/models/user_quota.dart';
import '../../../discover/discover_types.dart';
import '../../../inbox/system_inbox.dart';
import '../../data/models/chat_preview.dart';

/// 對話列表頁
///
/// 路由：/messages（ShellRoute tab 2）
/// - mutual / chatted / dm_pending 顯示
/// - 未讀標記
/// - 依最新訊息時間排序
/// - 對方為最後傳送方 / 雙方還沒都開口 → 顯示倒數
///
/// Realtime：訂閱 messages 表的 INSERT / UPDATE，每次事件刷新
/// chatPreviewsProvider — RLS 會限制 caller 只看到自己參與的 chat_room，
/// 因此不需要前端再過濾。涵蓋：對方傳新訊息（INSERT）、自己進聊天室標已讀
/// （UPDATE read_at）後回來，列表的未讀數會自動掉回 0。
class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage>
    with WidgetsBindingObserver {
  RealtimeChannel? _channel;
  // 把 SupabaseClient 在 initState 抓下來。dispose 階段 ref 已不能用，
  // 但拆 channel 還是要 client，所以提早綁好。
  late final SupabaseClient _supabase;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _supabase = ref.read(supabaseProvider);
    _subscribe();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final ch = _channel;
    if (ch != null) {
      // 不能透過 ref.read（state 已標記 disposed）— 用 initState 抓下來的 client
      _supabase.removeChannel(ch);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App 從背景回前景時刷一次列表（推播期間 realtime 連線可能斷掉）
    // 同步刷新系統收件匣（公告 / 警告 / 審核結果可能在背景時收到）
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(chatPreviewsProvider);
      ref.invalidate(systemMessagesProvider);
    }
  }

  void _subscribe() {
    final myId = _supabase.auth.currentUser?.id;
    var channel = _supabase
        .channel('messages-list')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (_) {
            if (mounted) ref.invalidate(chatPreviewsProvider);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          callback: (_) {
            if (mounted) ref.invalidate(chatPreviewsProvider);
          },
        )
        // both_spoken 由 DB trigger 在訊息插入後 commit 內 UPDATE 到 chat_rooms。
        // 訂閱 chat_rooms 改動，當倒數該關掉時列表立即跟上。
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chat_rooms',
          callback: (_) {
            if (mounted) ref.invalidate(chatPreviewsProvider);
          },
        );

    // 系統收件匣 realtime — 公告 / 警告 / 審核結果寫入時即時反映未讀紅點。
    // RLS 已限制只看自己的，filter 是雙重保險（避免接到別人的事件）。
    if (myId != null) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'system_messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: myId,
        ),
        callback: (_) {
          if (mounted) ref.invalidate(systemMessagesProvider);
        },
      );
    }

    _channel = channel.subscribe();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final previewsAsync = ref.watch(chatPreviewsProvider);

    return Scaffold(
      backgroundColor: colors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: colors.backgroundWarm,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.messagesPageTitle,
          style: isZh
              ? GoogleFonts.notoSerifTc(
                  color: colors.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2.0,
                )
              : GoogleFonts.cormorantGaramond(
                  color: colors.primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 5.0,
                  fontStyle: FontStyle.italic,
                ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(chatPreviewsProvider);
            await ref.read(chatPreviewsProvider.future);
          },
          child: previewsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '${l10n.matchLoadFailed}\n\n$e',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.secondaryText, fontSize: 12),
                ),
              ),
            ),
            data: (items) {
              // 過濾：超過 3 天且尚未開始對話 → 隱藏
              // 已對話 (bothSpoken) 永遠保留
              final filtered = items.where((p) {
                if (p.bothSpoken) return true;
                return p.daysSinceMatch() <= 3;
              }).toList();

              // 系統收件匣以最新訊息時間融入排序，與一般對話一起依時間遞減排列
              final latestSystem = ref.watch(latestSystemMessageProvider).valueOrNull;
              final rows = <_InboxRow>[
                ...filtered.map((p) => _InboxRow.chat(p, p.sortAt)),
                if (latestSystem != null)
                  _InboxRow.system(latestSystem.createdAt),
              ]..sort((a, b) => b.sortAt.compareTo(a.sortAt));

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: rows.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, indent: 80, color: colors.divider),
                itemBuilder: (_, i) {
                  final row = rows[i];
                  if (row.isSystem) return const SystemInboxListTile();
                  return _ChatTile(item: row.chat!);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Row descriptor：合併 system inbox 與對話列，共用同一份排序基準 ─────────

class _InboxRow {
  const _InboxRow._({required this.isSystem, required this.sortAt, this.chat});
  factory _InboxRow.system(DateTime sortAt) =>
      _InboxRow._(isSystem: true, sortAt: sortAt);
  factory _InboxRow.chat(ChatPreview chat, DateTime sortAt) =>
      _InboxRow._(isSystem: false, sortAt: sortAt, chat: chat);

  final bool isSystem;
  final DateTime sortAt;
  final ChatPreview? chat;
}

// ── 聊天列 tile ───────────────────────────────────────────────────────────────

class _ChatTile extends ConsumerWidget {
  const _ChatTile({required this.item});
  final ChatPreview item;

  Future<void> _openPartnerDetail(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(chatPreviewRepositoryProvider);
    final candidate = await repo.fetchProfileAsCandidate(item.otherUserId);
    if (!context.mounted || candidate == null) return;
    context.pushNamed(
      AppRoutes.discoverCandidate,
      extra: CandidateDetailArgs(
        candidate: candidate,
        quota: UserQuota.empty,
        candidateIndex: 0,
        readOnly: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: () => context.push('/messages/${item.matchId}', extra: item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 點頭貼 → 詳細頁；點 tile 其他位置 → 聊天室
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openPartnerDetail(context, ref),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: colors.forestGreen.withValues(alpha: 0.10),
                backgroundImage: item.avatarUrl != null
                    ? NetworkImage(item.avatarUrl!)
                    : null,
                child: item.avatarUrl == null
                    ? Icon(Icons.person_outline, color: colors.forestGreen)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          item.otherDisplayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: colors.primaryText,
                                fontWeight: item.hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                letterSpacing: 0.4,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (item.lastMessageAt != null)
                        Text(
                          _formatTime(item.lastMessageAt!, l10n),
                          style: TextStyle(
                            color: item.hasUnread
                                ? colors.forestGreen
                                : colors.secondaryText,
                            fontSize: 11,
                            fontWeight: item.hasUnread
                                ? FontWeight.w500
                                : FontWeight.w300,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _previewText(item, l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: item.hasUnread
                                    ? colors.primaryText
                                    : colors.secondaryText,
                                fontWeight: item.hasUnread
                                    ? FontWeight.w500
                                    : FontWeight.w300,
                                letterSpacing: 0.3,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (item.hasUnread) _UnreadBadge(count: item.unreadCount),
                    ],
                  ),
                  if (item.shouldShowCountdown) ...[
                    const SizedBox(height: 6),
                    _CountdownChip(item: item),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _previewText(ChatPreview p, AppLocalizations l10n) {
    if (p.lastMessageContent != null && p.lastMessageContent!.isNotEmpty) {
      final prefix = p.isLastSenderMe ? '${l10n.chatMeLabel}：' : '';
      return '$prefix${p.lastMessageContent}';
    }
    if (!p.bothSpoken) return l10n.chatNotStarted;
    return l10n.matchOpenChat;
  }

  String _formatTime(DateTime t, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return l10n.chatTimeJustNow;
    if (diff.inHours < 1) return l10n.chatTimeMinutesAgo(diff.inMinutes);
    final local = t.toLocal();
    if (diff.inDays < 1) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) return l10n.chatTimeDaysAgo(diff.inDays);
    return '${local.month}/${local.day}';
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.forestGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── 倒數計時 chip（每分鐘 tick） ────────────────────────────────────────────

class _CountdownChip extends StatefulWidget {
  const _CountdownChip({required this.item});
  final ChatPreview item;

  @override
  State<_CountdownChip> createState() => _CountdownChipState();
}

class _CountdownChipState extends State<_CountdownChip> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final expires = widget.item.countdownExpiresAt;
    if (expires == null) return const SizedBox.shrink();

    final remaining = expires.difference(DateTime.now());
    if (remaining.isNegative) {
      return Text(
        l10n.matchExpired,
        style: TextStyle(
          color: colors.secondaryText.withValues(alpha: 0.7),
          fontSize: 11,
        ),
      );
    }

    final urgent = remaining.inHours < 24;
    final label = remaining.inHours >= 24
        ? l10n.matchRemainDays(remaining.inDays)
        : remaining.inHours >= 1
            ? l10n.matchRemainHours(remaining.inHours)
            : l10n.matchRemainMinutes(remaining.inMinutes);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: urgent
            ? colors.error.withValues(alpha: 0.10)
            : colors.forestGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 12,
            color: urgent ? colors.error : colors.forestGreen,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: urgent ? colors.error : colors.forestGreen,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 空狀態 ────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colors, required this.l10n});
  final AppColors colors;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 44),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 0.8,
                  color: colors.primaryText.withValues(alpha: 0.32),
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.messagesEmptyTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.primaryText,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2.4,
                      ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.messagesEmptyBody,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.secondaryText,
                        fontWeight: FontWeight.w300,
                        height: 1.9,
                        letterSpacing: 0.3,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
