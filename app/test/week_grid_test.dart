import 'package:dater/core/week.dart';
import 'package:dater/features/availability/week_grid.dart';
import 'package:dater/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const screenWidth = 400.0;
const gridWidth = screenWidth - WeekGrid.hourLabelWidth;
const cell = 40.0;

Future<void> pumpGrid(
  WidgetTester tester, {
  int focus = 0,
  List<Slot>? tapped,
  List<int>? dayTaps,
  List<int>? edges,
  List<WeekGridBlock> blocks = const [],
}) async {
  tester.view.physicalSize = const Size(screenWidth, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: WeekGrid(
          weekStart: DateTime(2026, 11, 9),
          initialFocusDay: focus,
          initialHour: 0,
          cellHeight: cell,
          onTap: tapped?.add,
          onDayTap: dayTaps?.add,
          onWeekEdge: edges?.add,
          blocks: blocks,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Global position of the middle of [slot] when [focus] is the wide day.
Offset slotCenter(WidgetTester tester, Slot slot, int focus) {
  final top = tester.getTopLeft(find.byKey(const ValueKey('week-grid-row-0'))).dy;
  final columns = DayColumns(width: gridWidth, focus: focus.toDouble());
  return Offset(
    WeekGrid.hourLabelWidth + columns.leftOf(slot.day) + columns.widthOf(slot.day) / 2,
    top + (slot.hour + 0.5) * cell,
  );
}

void main() {
  group('DayColumns', () {
    test('focused day is wide, others share the rest, total stays constant', () {
      for (final focus in [0.0, 2.4, 3.0, 6.0]) {
        final c = DayColumns(width: 350, focus: focus);
        final total = [for (var d = 0; d < 7; d++) c.widthOf(d)].reduce((a, b) => a + b);
        expect(total, closeTo(350, 1e-9), reason: 'focus $focus');
      }
      final c = DayColumns(width: 350, focus: 3);
      expect(c.widthOf(3), closeTo(350 * 0.36, 1e-9));
      expect(c.widthOf(0), closeTo(c.widthOf(6), 1e-9));
      expect(c.widthOf(3), greaterThan(3 * c.widthOf(0)));
    });

    test('while animating the extra width flows between two neighbours', () {
      final c = DayColumns(width: 350, focus: 2.25);
      expect(c.widthOf(2), greaterThan(c.widthOf(3)));
      expect(c.widthOf(3), greaterThan(c.widthOf(4)));
    });

    test('dayAt matches the column edges', () {
      final c = DayColumns(width: 350, focus: 4);
      for (var d = 0; d < 7; d++) {
        expect(c.dayAt(c.leftOf(d) + 0.5), d);
        expect(c.dayAt(c.leftOf(d) + c.widthOf(d) - 0.5), d);
      }
      expect(c.dayAt(-5), 0);
      expect(c.dayAt(1000), 6);
    });
  });

  testWidgets('focused day header is spelled out, others are short', (tester) async {
    await pumpGrid(tester, focus: 1);
    expect(find.text('Salı'), findsOneWidget);
    expect(find.text('Pzt'), findsOneWidget);
    expect(find.text('Paz'), findsOneWidget);
    expect(find.text('Pazartesi'), findsNothing);
  });

  testWidgets('tapping a narrow day focuses it; tapping the focused day selects', (tester) async {
    final tapped = <Slot>[];
    await pumpGrid(tester, focus: 0, tapped: tapped);

    await tester.tapAt(slotCenter(tester, (day: 4, hour: 3), 0));
    await tester.pumpAndSettle();
    expect(tapped, isEmpty, reason: 'first tap only focuses Friday');
    expect(find.text('Cuma'), findsOneWidget);

    await tester.tapAt(slotCenter(tester, (day: 4, hour: 3), 4));
    expect(tapped, [(day: 4, hour: 3)]);
  });

  testWidgets('swiping moves the focus and asks for the next week past Sunday', (tester) async {
    final edges = <int>[];
    await pumpGrid(tester, focus: 5, edges: edges);

    await tester.dragFrom(slotCenter(tester, (day: 5, hour: 4), 5), const Offset(-150, 0));
    await tester.pumpAndSettle();
    expect(find.text('Pazar'), findsOneWidget, reason: 'swipe left: Saturday → Sunday');
    expect(edges, isEmpty);

    await tester.dragFrom(slotCenter(tester, (day: 6, hour: 4), 6), const Offset(-150, 0));
    await tester.pumpAndSettle();
    expect(edges, [1]);

    await tester.dragFrom(slotCenter(tester, (day: 6, hour: 4), 6), const Offset(150, 0));
    await tester.pumpAndSettle();
    expect(find.text('Cumartesi'), findsOneWidget, reason: 'swipe right goes back a day');
  });

  testWidgets('tapping the focused day name reports it; other names focus', (tester) async {
    final dayTaps = <int>[];
    await pumpGrid(tester, focus: 0, dayTaps: dayTaps);
    await tester.tap(find.text('Pazartesi'));
    expect(dayTaps, [0]);
    await tester.tap(find.text('Çar'));
    await tester.pumpAndSettle();
    expect(dayTaps, [0]);
    expect(find.text('Çarşamba'), findsOneWidget);
  });

  testWidgets('blocks follow their column, span their hours and let taps through', (tester) async {
    final tapped = <Slot>[];
    await pumpGrid(
      tester,
      focus: 1,
      tapped: tapped,
      blocks: const [
        WeekGridBlock(
          day: 1,
          fromHour: 2,
          toHour: 4,
          child: ColoredBox(key: Key('wide'), color: Colors.green),
        ),
        WeekGridBlock(
          day: 5,
          fromHour: 2,
          toHour: 3,
          child: ColoredBox(key: Key('narrow'), color: Colors.red),
        ),
      ],
    );

    final columns = DayColumns(width: gridWidth, focus: 1);
    final rowTop = tester.getTopLeft(find.byKey(const ValueKey('week-grid-row-0'))).dy;
    final wide = tester.getRect(find.byKey(const Key('wide')));
    expect(wide.height, 2 * cell - 2 * WeekGrid.blockInsetY, reason: 'one block for two hours');
    expect(wide.top, rowTop + 2 * cell + WeekGrid.blockInsetY);
    expect(wide.left, closeTo(WeekGrid.hourLabelWidth + columns.leftOf(1) + WeekGrid.blockInsetX, 0.01));
    expect(wide.width, closeTo(columns.widthOf(1) - 2 * WeekGrid.blockInsetX, 0.01));
    final narrow = tester.getRect(find.byKey(const Key('narrow')));
    expect(narrow.width, closeTo(columns.widthOf(5) - 2 * WeekGrid.blockInsetX, 0.01));
    expect(narrow.width, lessThan(wide.width / 2));

    await tester.tapAt(wide.center + const Offset(0, 15));
    expect(tapped, [(day: 1, hour: 3)]);

    // Rows alternate between the stripe color and transparent.
    Color rowColor(int hour) => tester
        .widget<ColoredBox>(
          find.descendant(of: find.byKey(ValueKey('week-grid-row-$hour')), matching: find.byType(ColoredBox)),
        )
        .color;
    expect(rowColor(0), isNot(Colors.transparent));
    expect(rowColor(1), Colors.transparent);
    expect(rowColor(2), rowColor(0));
  });
}
