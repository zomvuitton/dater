import 'package:dater/core/models.dart';
import 'package:dater/features/notifications/notifications_repository.dart';
import 'package:dater/features/notifications/notifications_screen.dart';
import 'package:dater/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification notification({
  required String id,
  required NotificationType type,
  PlanResponseStatus? response,
  bool read = false,
  Duration age = const Duration(minutes: 5),
}) => AppNotification(
  id: id,
  type: type,
  actor: const Profile(id: 'b', username: 'bob', displayName: 'Bob'),
  circleId: 'c1',
  circleName: 'Tırmanış',
  circleEmoji: '🧗',
  planTitle: 'Bouldering',
  planStartsAt: DateTime(2026, 11, 17, 20),
  response: response,
  createdAt: DateTime.now().subtract(age),
  readAt: read ? DateTime.now() : null,
);

Widget app(List<AppNotification> items, Locale locale) => ProviderScope(
  overrides: [
    notificationsProvider.overrideWith((ref) async => items),
    notificationsRealtimeProvider.overrideWith((ref) {}),
  ],
  child: MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('tr'), Locale('en')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: const NotificationsScreen(),
  ),
);

void main() {
  testWidgets('lists notifications in Turkish with unread markers', (tester) async {
    await tester.pumpWidget(
      app([
        notification(id: '1', type: NotificationType.planProposed),
        notification(
          id: '2',
          type: NotificationType.planResponse,
          response: PlanResponseStatus.maybe,
          read: true,
          age: const Duration(hours: 3),
        ),
      ], const Locale('tr')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bildirimler'), findsOneWidget);
    expect(find.text('Bob yeni bir plan önerdi: Bouldering'), findsOneWidget);
    expect(find.text('Bob “Bouldering” planı için “belki” dedi'), findsOneWidget);
    expect(find.textContaining('5 dk önce'), findsOneWidget);
    expect(find.textContaining('3 sa önce'), findsOneWidget);
    // Only the unread one has the dot.
    expect(find.byIcon(Icons.circle), findsOneWidget);
  });

  testWidgets('empty inbox in English', (tester) async {
    await tester.pumpWidget(app(const [], const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('No notifications yet'), findsOneWidget);
    final markAll = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.done_all));
    expect(markAll.onPressed, isNull);
  });
}
