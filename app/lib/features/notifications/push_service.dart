import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../core/locale.dart';
import '../../core/router.dart';
import '../../core/session.dart';
import '../../core/ui.dart';
import '../../l10n/app_localizations.dart';
import 'notifications_repository.dart';

/// Push needs a Firebase project (see README › Bildirimler). Build with
/// `--dart-define=PUSH_ENABLED=true` once its config files are in place;
/// otherwise Firebase is never touched and only the in-app inbox works.
const pushEnabled = bool.fromEnvironment('PUSH_ENABLED') && !kIsWeb;

/// Registers this device for push while someone is signed in, shows pushes
/// that arrive in the foreground, and opens the right screen when a push is
/// tapped.
class PushService {
  PushService(this._ref) {
    if (!pushEnabled) return;
    final session = _ref.read(appSessionProvider)..addListener(_onSessionChanged);
    _session = session;
    _onSessionChanged();
  }

  final Ref _ref;
  AppSession? _session;
  bool _firebaseReady = false;
  String? _token;
  String? _registeredFor;
  final _subscriptions = <StreamSubscription<Object?>>[];

  void _onSessionChanged() {
    final session = _session!;
    final userId = session.session?.user.id;
    if (userId != null && session.profile?.username != null && _registeredFor != userId) {
      unawaited(register());
    }
  }

  Future<void> _ensureFirebase() async {
    if (_firebaseReady) return;
    await Firebase.initializeApp();
    _firebaseReady = true;
    final messaging = FirebaseMessaging.instance;
    _subscriptions
      ..add(FirebaseMessaging.onMessage.listen(_onForegroundMessage))
      ..add(FirebaseMessaging.onMessageOpenedApp.listen(_open))
      // FCM registration tokens (getToken/onTokenRefresh) are what the push
      // Edge Function sends to via HTTP v1 `message.token`. firebase_messaging 17
      // deprecates them in favour of FID registration, but they keep working;
      // move once FID direct-send is verified end to end.
      // ignore: deprecated_member_use
      ..add(messaging.onTokenRefresh.listen((_) => register()));
    final initial = await messaging.getInitialMessage();
    if (initial != null) _open(initial);
  }

  /// Asks for permission (first time only) and stores the device token.
  /// Also called again when the app language changes.
  Future<void> register() async {
    if (!pushEnabled) return;
    final userId = _session?.session?.user.id;
    if (userId == null) return;
    try {
      await _ensureFirebase();
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // The FCM token is only available once APNs has handed out its token.
        for (var i = 0; i < 10 && await messaging.getAPNSToken() == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token == null) return;
      final locale = _ref.read(localeProvider) ?? PlatformDispatcher.instance.locale;
      final timeZone = (await FlutterTimezone.getLocalTimezone()).identifier;
      await _ref
          .read(notificationsRepositoryProvider)
          .registerDeviceToken(
            token: token,
            platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
            locale: locale.languageCode,
            timeZone: timeZone,
          );
      _token = token;
      _registeredFor = userId;
    } catch (e) {
      debugPrint('Push registration failed: $e');
    }
  }

  /// Stops pushes to this device; call before signing out.
  Future<void> unregister() async {
    final token = _token;
    _token = null;
    _registeredFor = null;
    if (token == null) return;
    try {
      await _ref.read(notificationsRepositoryProvider).deleteDeviceToken(token);
    } catch (e) {
      debugPrint('Push unregistration failed: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    _ref.invalidate(notificationsProvider);
    final messenger = rootMessengerKey.currentState;
    final notification = message.notification;
    if (messenger == null || notification == null) return;
    final l10n = AppLocalizations.of(messenger.context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text([notification.title, notification.body].whereType<String>().join('\n')),
          action: SnackBarAction(label: l10n.open, onPressed: () => _open(message)),
        ),
      );
  }

  void _open(RemoteMessage message) {
    final id = message.data['notification_id'];
    if (id is String) unawaited(_ref.read(notificationsRepositoryProvider).markRead([id]).catchError((_) {}));
    _ref.invalidate(notificationsProvider);
    final route = message.data['route'];
    if (route is String && route.startsWith('/')) _ref.read(routerProvider).go(route);
  }

  void dispose() {
    _session?.removeListener(_onSessionChanged);
    for (final s in _subscriptions) {
      s.cancel();
    }
  }
}

final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService(ref);
  ref.listen(localeProvider, (_, _) => service.register());
  ref.onDispose(service.dispose);
  return service;
});
