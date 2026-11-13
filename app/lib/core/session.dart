import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/notifications/push_service.dart';
import '../features/profile/profile_repository.dart';
import 'models.dart';
import 'supabase.dart';

/// Tracks the auth session and the signed-in user's profile, and notifies the
/// router whenever either changes.
class AppSession extends ChangeNotifier {
  AppSession(this._client, this._profiles) {
    _sub = _client.auth.onAuthStateChange.listen((state) => _onAuth(state.session));
    _onAuth(_client.auth.currentSession);
  }

  final SupabaseClient _client;
  final ProfileRepository _profiles;
  late final StreamSubscription<AuthState> _sub;

  Session? session;
  Profile? profile;
  bool loadingProfile = false;
  Object? profileError;

  bool get signedIn => session != null;
  bool get needsOnboarding => signedIn && !loadingProfile && (profile?.username == null);

  Future<void> _onAuth(Session? next) async {
    final userChanged = next?.user.id != session?.user.id;
    session = next;
    if (next == null) {
      profile = null;
      notifyListeners();
      return;
    }
    if (userChanged || profile == null) {
      await refreshProfile();
    } else {
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    loadingProfile = true;
    profileError = null;
    notifyListeners();
    try {
      profile = await _profiles.fetchMine();
    } catch (e) {
      profileError = e;
    } finally {
      loadingProfile = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final appSessionProvider = Provider<AppSession>((ref) {
  final session = AppSession(ref.watch(supabaseProvider), ref.watch(profileRepositoryProvider));
  ref.onDispose(session.dispose);
  return session;
});

/// Signs out, first removing this device's push token so the next person
/// using the phone does not get the previous account's notifications.
Future<void> signOut(WidgetRef ref) async {
  await ref.read(pushServiceProvider).unregister();
  await ref.read(supabaseProvider).auth.signOut();
}
