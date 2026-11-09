import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models.dart';
import '../../core/supabase.dart';

class PlansRepository {
  PlansRepository(this._client);
  final SupabaseClient _client;

  static const _select = '*, plan_responses(user_id, status)';

  /// Plans of a circle that have not ended yet, soonest first.
  Future<List<Plan>> fetchUpcoming(String circleId) async {
    final rows = await _client
        .from('plans')
        .select(_select)
        .eq('circle_id', circleId)
        .gte('ends_at', DateTime.now().toUtc().toIso8601String())
        .order('starts_at');
    return rows.map(Plan.fromJson).toList();
  }

  Future<Plan> create({
    required String circleId,
    required String title,
    String? note,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final row = await _client
        .from('plans')
        .insert({
          'circle_id': circleId,
          'created_by': _client.auth.currentUser!.id,
          'title': title.trim(),
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          'starts_at': startsAt.toUtc().toIso8601String(),
          'ends_at': endsAt.toUtc().toIso8601String(),
        })
        .select('id')
        .single();
    // Re-read so the proposer's automatic "going" (added by a trigger after the
    // insert) is included.
    final created = await _client.from('plans').select(_select).eq('id', row['id'] as String).single();
    return Plan.fromJson(created);
  }

  Future<void> respond(String planId, PlanResponseStatus status) => _client.from('plan_responses').upsert({
    'plan_id': planId,
    'user_id': _client.auth.currentUser!.id,
    'status': status.name,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  });

  Future<void> delete(String planId) => _client.from('plans').delete().eq('id', planId);
}

final plansRepositoryProvider = Provider((ref) => PlansRepository(ref.watch(supabaseProvider)));

final circlePlansProvider = FutureProvider.family<List<Plan>, String>((ref, circleId) {
  requireUserId(ref);
  return ref.watch(plansRepositoryProvider).fetchUpcoming(circleId);
});
