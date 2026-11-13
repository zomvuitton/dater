import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_screen.dart';
import '../features/auth/onboarding_screen.dart';
import '../features/availability/my_week_screen.dart';
import '../features/circles/circle_detail_screen.dart';
import '../features/circles/circles_screen.dart';
import '../features/circles/join_screen.dart';
import '../features/friends/friends_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/profile/profile_screen.dart';
import 'home_shell.dart';
import 'session.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(appSessionProvider);

  final router = GoRouter(
    initialLocation: '/week',
    refreshListenable: session,
    redirect: (context, state) {
      final location = state.uri.toString();
      final path = state.uri.path;
      final from = state.uri.queryParameters['from'];

      // e.g. the dater://login-callback auth link, which supabase_flutter handles.
      if (path.isEmpty || path == '/') return '/week';

      if (!session.signedIn) {
        if (path == '/auth') return null;
        return Uri(path: '/auth', queryParameters: {if (path != '/week') 'from': location}).toString();
      }
      if (session.loadingProfile && session.profile == null) {
        return path == '/loading' ? null : _withFrom('/loading', path, location, from);
      }
      if (session.needsOnboarding) {
        return path == '/onboarding' ? null : _withFrom('/onboarding', path, location, from);
      }
      if (const {'/auth', '/onboarding', '/loading'}.contains(path)) {
        return from ?? '/week';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/loading', builder: (context, state) => const _LoadingScreen()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(
        path: '/join/:code',
        builder: (context, state) => JoinScreen(code: state.pathParameters['code']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/week', builder: (context, state) => const MyWeekScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/circles',
                builder: (context, state) => const CirclesScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => CircleDetailScreen(
                      // A new tab parameter (e.g. from a notification) rebuilds the screen on that tab.
                      key: ValueKey(state.uri.toString()),
                      circleId: state.pathParameters['id']!,
                      initialTab: CircleTab.fromQuery(state.uri.queryParameters['tab']),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/friends', builder: (context, state) => const FriendsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Sends the user to [target] while remembering where they wanted to go.
String _withFrom(String target, String path, String location, String? from) {
  final destination = from ?? (const {'/auth', '/onboarding', '/loading', '/week'}.contains(path) ? null : location);
  return Uri(path: target, queryParameters: {'from': ?destination}).toString();
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
