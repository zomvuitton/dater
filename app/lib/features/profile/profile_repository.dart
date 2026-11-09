import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models.dart';
import '../../core/supabase.dart';

class ProfileRepository {
  ProfileRepository(this._client);
  final SupabaseClient _client;

  String get _me => _client.auth.currentUser!.id;

  Future<Profile?> fetchMine() async {
    final row = await _client.from('profiles').select().eq('id', _me).maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  }

  /// Throws [UsernameTakenException] if the username is in use.
  Future<void> updateMine({String? username, String? displayName}) async {
    try {
      await _client
          .from('profiles')
          .update({'username': ?username?.trim().toLowerCase(), 'display_name': ?displayName?.trim()})
          .eq('id', _me);
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw const UsernameTakenException();
      rethrow;
    }
  }

  /// Profiles whose username starts with [query], excluding the caller.
  Future<List<Profile>> searchByUsername(String query) async {
    final q = query.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (q.isEmpty) return const [];
    final rows = await _client
        .from('profiles')
        .select()
        .like('username', '$q%')
        .neq('id', _me)
        .order('username')
        .limit(20);
    return rows.map(Profile.fromJson).toList();
  }
}

class UsernameTakenException implements Exception {
  const UsernameTakenException();
}

final usernamePattern = RegExp(r'^[a-z0-9_]{3,20}$');

final profileRepositoryProvider = Provider((ref) => ProfileRepository(ref.watch(supabaseProvider)));
