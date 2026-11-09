import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configure with `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...` (the
/// project's publishable or anon key).
/// The defaults point at a local `supabase start` stack.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'http://127.0.0.1:54321');
const supabaseKey = String.fromEnvironment(
  'SUPABASE_KEY',
  // Public anon key of every local Supabase stack (not a secret).
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
);

/// Deep link scheme registered on Android/iOS, e.g. `dater://app/join/ABCD2345`.
const deepLinkScheme = 'dater';

String inviteLink(String code) => '$deepLinkScheme://app/join/$code';

final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

/// Emits the signed-in user's id (null when signed out).
final currentUserIdProvider = StreamProvider<String?>((ref) {
  final auth = ref.watch(supabaseProvider).auth;
  return auth.onAuthStateChange.map((state) => state.session?.user.id).distinct();
});

/// The signed-in user's id; throws if nobody is signed in. Only use it on
/// screens behind the auth guard.
String requireUserId(Ref ref) {
  final id = ref.watch(currentUserIdProvider).value ?? ref.read(supabaseProvider).auth.currentUser?.id;
  if (id == null) throw StateError('Not signed in');
  return id;
}
