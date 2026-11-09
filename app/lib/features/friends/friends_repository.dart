import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models.dart';
import '../../core/supabase.dart';

class FriendsRepository {
  FriendsRepository(this._client);
  final SupabaseClient _client;

  static const _select =
      '*, '
      'requester:profiles!friendships_requester_id_fkey(*), '
      'addressee:profiles!friendships_addressee_id_fkey(*)';

  /// All friendships and pending requests involving the caller.
  Future<List<Friendship>> fetchAll() async {
    final rows = await _client.from('friendships').select(_select).order('created_at');
    return rows.map(Friendship.fromJson).toList();
  }

  /// Sends a request, or accepts theirs if they already asked.
  Future<void> sendRequest(String username) =>
      _client.rpc('send_friend_request', params: {'target_username': username});

  Future<void> accept(String friendshipId) =>
      _client.rpc('accept_friend_request', params: {'request_id': friendshipId});

  /// Declines, cancels or unfriends.
  Future<void> remove(String friendshipId) => _client.from('friendships').delete().eq('id', friendshipId);
}

final friendsRepositoryProvider = Provider((ref) => FriendsRepository(ref.watch(supabaseProvider)));

final friendshipsProvider = FutureProvider<List<Friendship>>((ref) {
  requireUserId(ref);
  return ref.watch(friendsRepositoryProvider).fetchAll();
});

/// Accepted friends of the caller.
final friendsProvider = FutureProvider<List<Profile>>((ref) async {
  final me = requireUserId(ref);
  final all = await ref.watch(friendshipsProvider.future);
  return [
    for (final f in all)
      if (f.status == FriendshipStatus.accepted) f.other(me),
  ]..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
});
