// 系統收件匣（Luko 官方通知）
//
// 後端：system_messages 表（migration 20260430000001）
// 觸發點：
//   - review-application 通過 → welcome_approved
//   - review-photo-change 通過 → photo_change_approved
//   - review-report → warning / sanction_temp / sanction_perm
//   - 停權自動解除（cron）→ sanction_lifted
//   - admin 後台手動公告 → announcement
//
// UX：
//   - 在 messages 列表頂部顯示一個固定 entry「Luko 官方」
//   - 點進去 = 唯讀訊息列表，無輸入框
//   - 不可離開、不可檢舉、不可封鎖

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/supabase/supabase_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class SystemMessage {
  const SystemMessage({
    required this.id,
    required this.userId,
    required this.type,
    required this.body,
    required this.createdAt,
    this.title,
    this.metadata,
    this.readAt,
  });

  final String id;
  final String userId;
  final String type;
  final String? title;
  final String body;
  final Map<String, dynamic>? metadata;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isUnread => readAt == null;

  factory SystemMessage.fromJson(Map<String, dynamic> json) => SystemMessage(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        type: json['type'] as String,
        title: json['title'] as String?,
        body: json['body'] as String,
        metadata: json['metadata'] as Map<String, dynamic>?,
        readAt: json['read_at'] == null
            ? null
            : DateTime.parse(json['read_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

// ── Providers ─────────────────────────────────────────────────────────────────

final systemMessagesProvider = FutureProvider<List<SystemMessage>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final res = await supabase
      .from('system_messages')
      .select()
      .order('created_at', ascending: false)
      .limit(100);
  return (res as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map(SystemMessage.fromJson)
      .toList();
});

final systemUnreadCountProvider = FutureProvider<int>((ref) async {
  final list = await ref.watch(systemMessagesProvider.future);
  return list.where((m) => m.isUnread).length;
});

/// 最新一筆系統訊息（用於 messages 列表 tile 的預覽 + 排序時間）
/// list 已 order by created_at DESC，取 first
final latestSystemMessageProvider = FutureProvider<SystemMessage?>((ref) async {
  final list = await ref.watch(systemMessagesProvider.future);
  return list.isEmpty ? null : list.first;
});

Future<void> markSystemMessageRead(WidgetRef ref, String id) async {
  final supabase = ref.read(supabaseProvider);
  await supabase
      .from('system_messages')
      .update({'read_at': DateTime.now().toIso8601String()})
      .eq('id', id)
      .filter('read_at', 'is', null);
}

Future<void> markAllSystemMessagesRead(WidgetRef ref) async {
  final supabase = ref.read(supabaseProvider);
  await supabase
      .from('system_messages')
      .update({'read_at': DateTime.now().toIso8601String()})
      .filter('read_at', 'is', null);
  ref.invalidate(systemMessagesProvider);
}

// ── Page ──────────────────────────────────────────────────────────────────────

class SystemInboxPage extends ConsumerStatefulWidget {
  const SystemInboxPage({super.key});

  @override
  ConsumerState<SystemInboxPage> createState() => _SystemInboxPageState();
}

class _SystemInboxPageState extends ConsumerState<SystemInboxPage> {
  @override
  void initState() {
    super.initState();
    // 進入頁面後標所有未讀為已讀
    WidgetsBinding.instance.addPostFrameCallback((_) {
      markAllSystemMessagesRead(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final messagesAsync = ref.watch(systemMessagesProvider);

    return Scaffold(
      backgroundColor: colors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: colors.backgroundWarm,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.systemInboxTitle,
          style: isZh
              ? GoogleFonts.notoSerifTc(
                  color: colors.primaryText,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                )
              : GoogleFonts.cormorantGaramond(
                  color: colors.primaryText,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(systemMessagesProvider),
        child: messagesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (msgs) {
            if (msgs.isEmpty) {
              return Center(
                child: Text(
                  l10n.systemInboxEmpty,
                  style: TextStyle(color: colors.secondaryText),
                ),
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              itemCount: msgs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _SystemMessageCard(message: msgs[i]),
            );
          },
        ),
      ),
    );
  }
}

class _SystemMessageCard extends StatelessWidget {
  const _SystemMessageCard({required this.message});
  final SystemMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.divider.withValues(alpha: 0.6),
          width: 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                message.title!,
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Text(
            message.body,
            style: TextStyle(
              color: colors.primaryText.withValues(alpha: 0.92),
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatDate(message.createdAt),
            style: TextStyle(color: colors.secondaryText, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime t) {
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}'
        ' ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}

// ── Tile（樣式比照 _ChatTile，與一般對話一起依時間排序）──────────────────────

class SystemInboxListTile extends ConsumerWidget {
  const SystemInboxListTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final unreadAsync = ref.watch(systemUnreadCountProvider);
    final latestAsync = ref.watch(latestSystemMessageProvider);
    final unread = unreadAsync.valueOrNull ?? 0;
    final latest = latestAsync.valueOrNull;
    final hasUnread = unread > 0;

    final preview = latest != null
        ? (latest.title?.isNotEmpty == true ? latest.title! : latest.body)
        : l10n.systemInboxListEntryPreview;

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SystemInboxPage()),
        );
        ref.invalidate(systemMessagesProvider);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App icon 頭貼
            CircleAvatar(
              radius: 28,
              backgroundColor: colors.forestGreen.withValues(alpha: 0.10),
              backgroundImage: const AssetImage(
                'assets/images/app_icon_fill.png',
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
                          l10n.systemInboxListEntryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: colors.primaryText,
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                letterSpacing: 0.4,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (latest != null)
                        Text(
                          _formatTime(latest.createdAt, l10n),
                          style: TextStyle(
                            color: hasUnread
                                ? colors.forestGreen
                                : colors.secondaryText,
                            fontSize: 11,
                            fontWeight: hasUnread
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
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: hasUnread
                                    ? colors.primaryText
                                    : colors.secondaryText,
                                fontWeight: hasUnread
                                    ? FontWeight.w500
                                    : FontWeight.w300,
                                letterSpacing: 0.3,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (hasUnread) _SystemUnreadBadge(count: unread),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return l10n.chatTimeJustNow;
    if (diff.inHours < 1) return l10n.chatTimeMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) return l10n.chatTimeDaysAgo(diff.inDays);
    return '${t.month}/${t.day}';
  }
}

class _SystemUnreadBadge extends StatelessWidget {
  const _SystemUnreadBadge({required this.count});
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
