import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models.dart';
import '../../core/supabase.dart';

class CirclesRepository {
  CirclesRepository(this._client);
  final SupabaseClient _client;

  /// Circles the caller belongs to (RLS limits the rows), with member counts.
  Future<List<Circle>> fetchMine() async {
    final rows = await _client.from('circles').select('*, circle_members(count)').order('created_at');
    return rows.map(Circle.fromJson).toList();
  }

  Future<Circle> fetch(String id) async {
    final row = await _client.from('circles').select('*, circle_members(count)').eq('id', id).single();
    return Circle.fromJson(row);
  }

  Future<Circle> create({required String name, required String emoji, required String colorHex}) async {
    final row = await _client
        .from('circles')
        .insert({'owner_id': _client.auth.currentUser!.id, 'name': name.trim(), 'emoji': emoji, 'color': colorHex})
        .select()
        .single();
    return Circle.fromJson(row);
  }

  Future<void> update(String id, {required String name, required String emoji, required String colorHex}) =>
      _client.from('circles').update({'name': name.trim(), 'emoji': emoji, 'color': colorHex}).eq('id', id);

  Future<void> delete(String id) => _client.from('circles').delete().eq('id', id);

  Future<List<CircleMember>> fetchMembers(String circleId) async {
    final rows = await _client
        .from('circle_members')
        .select('role, profiles(*)')
        .eq('circle_id', circleId)
        .order('joined_at');
    return rows.map(CircleMember.fromJson).toList();
  }

  /// Owner only, and only accepted friends.
  Future<void> addMember(String circleId, String userId) =>
      _client.from('circle_members').insert({'circle_id': circleId, 'user_id': userId});

  /// Removes a member (owner) or leaves the circle (self).
  Future<void> removeMember(String circleId, String userId) =>
      _client.from('circle_members').delete().eq('circle_id', circleId).eq('user_id', userId);

  /// Returns the joined circle's id. Throws [InvalidInviteCodeException].
  Future<String> joinByCode(String code) async {
    try {
      return await _client.rpc<String>('join_circle_by_code', params: {'code': code});
    } on PostgrestException catch (e) {
      if (e.code == 'P0002') throw const InvalidInviteCodeException();
      rethrow;
    }
  }

  Future<String> regenerateInviteCode(String circleId) =>
      _client.rpc<String>('regenerate_invite_code', params: {'circle_id': circleId});
}

class InvalidInviteCodeException implements Exception {
  const InvalidInviteCodeException();
}

final circlesRepositoryProvider = Provider((ref) => CirclesRepository(ref.watch(supabaseProvider)));

final myCirclesProvider = FutureProvider<List<Circle>>((ref) {
  requireUserId(ref);
  return ref.watch(circlesRepositoryProvider).fetchMine();
});

final circleProvider = FutureProvider.family<Circle, String>((ref, id) {
  requireUserId(ref);
  return ref.watch(circlesRepositoryProvider).fetch(id);
});

final circleMembersProvider = FutureProvider.family<List<CircleMember>, String>((ref, id) {
  requireUserId(ref);
  return ref.watch(circlesRepositoryProvider).fetchMembers(id);
});

/// Refreshes everything that depends on circle membership.
void invalidateCircles(WidgetRef ref) {
  ref.invalidate(myCirclesProvider);
  ref.invalidate(circleProvider);
  ref.invalidate(circleMembersProvider);
}
