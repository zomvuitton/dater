import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase.dart';
import '../../core/week.dart';

class AvailabilityRepository {
  AvailabilityRepository(this._client);
  final SupabaseClient _client;

  String get _me => _client.auth.currentUser!.id;

  /// The caller's availability in the week: slot -> circle ids it is shared with.
  Future<Map<Slot, Set<String>>> fetchMyWeek(DateTime weekStart) async {
    final range = weekRangeUtc(weekStart);
    final rows = await _client
        .from('availability')
        .select('circle_id, starts_at')
        .eq('user_id', _me)
        .gte('starts_at', range.start.toIso8601String())
        .lt('starts_at', range.end.toIso8601String());
    return _group(weekStart, rows, 'circle_id');
  }

  /// Everyone's availability shared with a circle: slot -> user ids.
  Future<Map<Slot, Set<String>>> fetchCircleWeek(String circleId, DateTime weekStart) async {
    final range = weekRangeUtc(weekStart);
    final rows = await _client
        .from('availability')
        .select('user_id, starts_at')
        .eq('circle_id', circleId)
        .gte('starts_at', range.start.toIso8601String())
        .lt('starts_at', range.end.toIso8601String());
    return _group(weekStart, rows, 'user_id');
  }

  /// Shares [slots] with exactly [circleIds]; an empty set clears them.
  Future<void> setSlots(DateTime weekStart, Set<Slot> slots, Set<String> circleIds) => _client.rpc(
    'set_availability',
    params: {
      'slots': [for (final s in slots) slotStart(weekStart, s).toUtc().toIso8601String()],
      'circle_ids': circleIds.toList(),
    },
  );

  /// Replaces [toWeek] with a copy of [fromWeek], keeping local hours (also
  /// across daylight-saving changes). Returns how many hours were copied.
  Future<int> copyWeek({required DateTime fromWeek, required DateTime toWeek}) async {
    final source = await fetchMyWeek(fromWeek);
    final range = weekRangeUtc(toWeek);
    final entries = [
      for (final MapEntry(key: slot, value: circles) in source.entries)
        for (final circleId in circles)
          {'circle_id': circleId, 'starts_at': slotStart(toWeek, slot).toUtc().toIso8601String()},
    ];
    await _client.rpc(
      'replace_availability_range',
      params: {
        'range_start': range.start.toIso8601String(),
        'range_end': range.end.toIso8601String(),
        'entries': entries,
      },
    );
    return source.length;
  }

  static Map<Slot, Set<String>> _group(DateTime weekStart, List<Map<String, dynamic>> rows, String key) {
    final result = <Slot, Set<String>>{};
    for (final row in rows) {
      final slot = slotOf(weekStart, DateTime.parse(row['starts_at'] as String));
      if (slot == null) continue;
      result.putIfAbsent(slot, () => {}).add(row[key] as String);
    }
    return result;
  }
}

final availabilityRepositoryProvider = Provider((ref) => AvailabilityRepository(ref.watch(supabaseProvider)));

final myWeekProvider = FutureProvider.family<Map<Slot, Set<String>>, DateTime>((ref, weekStart) {
  requireUserId(ref);
  return ref.watch(availabilityRepositoryProvider).fetchMyWeek(weekStart);
});

final circleWeekProvider = FutureProvider.family<Map<Slot, Set<String>>, ({String circleId, DateTime weekStart})>((
  ref,
  key,
) {
  requireUserId(ref);
  return ref.watch(availabilityRepositoryProvider).fetchCircleWeek(key.circleId, key.weekStart);
});
