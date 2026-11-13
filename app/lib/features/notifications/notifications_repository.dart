import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models.dart';
import '../../core/supabase.dart';

class NotificationsRepository {
  NotificationsRepository(this._client);
  final SupabaseClient _client;

  static const _select =
      '*, '
      'actor:profiles!notifications_actor_id_fkey(*), '
      'circle:circles(name, emoji), '
      'plan:plans(title, starts_at)';

  /// The caller's latest notifications, newest first (RLS limits the rows).
  Future<List<AppNotification>> fetchRecent({int limit = 50}) async {
    final rows = await _client.from('notifications').select(_select).order('created_at', ascending: false).limit(limit);
    return rows.map(AppNotification.fromJson).toList();
  }

  /// Marks [ids] as read, or every notification when [ids] is null.
  Future<void> markRead([List<String>? ids]) => _client.rpc('mark_notifications_read', params: {'ids': ids});

  /// Calls [onInsert] whenever a notification for [userId] is created.
  ///
  /// The channel reports "subscribed" before the server's replication is live,
  /// so [onReady] fires separately once inserts are actually being delivered;
  /// refresh then to catch anything created in between.
  RealtimeChannel subscribe(String userId, void Function() onInsert, {void Function()? onReady}) => _client
      .channel('notifications:$userId', opts: const RealtimeChannelConfig(replicationReady: true))
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
        callback: (_) => onInsert(),
      )
      .onSystemEvents((payload) {
        // "Subscribed to PostgreSQL": inserts are delivered from now on.
        if (payload is Map && payload['extension'] == 'postgres_changes' && payload['status'] == 'ok') {
          onReady?.call();
        }
      })
      .subscribe();

  /// Registers this device's push token for the caller (moves it if another
  /// account had it).
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    required String locale,
    required String timeZone,
  }) => _client.rpc(
    'register_device_token',
    params: {'token': token, 'platform': platform, 'locale': locale, 'time_zone': timeZone},
  );

  Future<void> deleteDeviceToken(String token) => _client.from('device_tokens').delete().eq('token', token);
}

final notificationsRepositoryProvider = Provider((ref) => NotificationsRepository(ref.watch(supabaseProvider)));

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  requireUserId(ref);
  return ref.watch(notificationsRepositoryProvider).fetchRecent();
});

final unreadCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider).value ?? const <AppNotification>[];
  return list.where((n) => !n.isRead).length;
});

/// Keeps the inbox live while watched: refreshes it when a notification
/// arrives, once the live connection is ready, and when the app comes back
/// to the foreground.
final notificationsRealtimeProvider = Provider<void>((ref) {
  final userId = requireUserId(ref);
  void refresh() => ref.invalidate(notificationsProvider);
  final channel = ref.watch(notificationsRepositoryProvider).subscribe(userId, refresh, onReady: refresh);
  final lifecycle = AppLifecycleListener(onResume: refresh);
  ref.onDispose(() {
    lifecycle.dispose();
    channel.unsubscribe();
  });
});
