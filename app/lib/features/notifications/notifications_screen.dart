import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models.dart';
import '../../core/ui.dart';
import '../../l10n/app_localizations.dart';
import 'notifications_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markRead(BuildContext context, WidgetRef ref, [List<String>? ids]) async {
    try {
      await ref.read(notificationsRepositoryProvider).markRead(ids);
      ref.invalidate(notificationsProvider);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    ref.watch(notificationsRealtimeProvider);
    final async = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          IconButton(
            tooltip: l10n.markAllRead,
            icon: const Icon(Icons.done_all),
            onPressed: unread == 0 ? null : () => _markRead(context, ref),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(notificationsProvider)),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.notifications_none,
                title: l10n.notificationsEmptyTitle,
                body: l10n.notificationsEmptyBody,
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(notificationsProvider.future),
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _NotificationTile(
                    notification: items[i],
                    onTap: () {
                      final n = items[i];
                      if (!n.isRead) _markRead(context, ref, [n.id]);
                      context.go(n.route);
                    },
                  ),
                ),
              ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final n = notification;
    final actor = n.actor.label;
    final text = switch ((n.type, n.response)) {
      (NotificationType.planProposed, _) => l10n.notifPlanProposed(actor, n.planTitle),
      (NotificationType.planResponse, PlanResponseStatus.maybe) => l10n.notifPlanMaybe(actor, n.planTitle),
      (NotificationType.planResponse, PlanResponseStatus.no) => l10n.notifPlanNo(actor, n.planTitle),
      (NotificationType.planResponse, _) => l10n.notifPlanGoing(actor, n.planTitle),
    };
    final when = DateFormat.MMMEd(localeName(context)).add_Hm().format(n.planStartsAt);

    return ListTile(
      onTap: onTap,
      tileColor: n.isRead ? null : theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      leading: Badge(
        backgroundColor: Colors.transparent,
        alignment: AlignmentDirectional.bottomEnd,
        offset: const Offset(4, 4),
        label: Text(n.circleEmoji, style: const TextStyle(fontSize: 14)),
        child: ProfileAvatar(n.actor),
      ),
      title: Text(text, style: n.isRead ? null : const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${n.circleName} · $when\n${formatRelative(context, n.createdAt)}'),
      isThreeLine: true,
      trailing: n.isRead ? null : Icon(Icons.circle, size: 10, color: theme.colorScheme.primary),
    );
  }
}

/// "now", "5 min ago", "3 h ago", then a date.
String formatRelative(BuildContext context, DateTime time, {DateTime? now}) {
  final l10n = AppLocalizations.of(context);
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return l10n.timeJustNow;
  if (diff.inHours < 1) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return l10n.timeHoursAgo(diff.inHours);
  return DateFormat.MMMd(localeName(context)).format(time);
}
