import 'package:dater/core/week.dart';
import 'package:dater/features/availability/week_grid.dart';
import 'package:dater/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping a cell reports its slot; day headers are localized', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final tapped = <Slot>[];
    final tappedDays = <int>[];
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
            initialHour: 0,
            cellHeight: 40,
            onTap: tapped.add,
            onDayTap: tappedDays.add,
            cellBuilder: (context, slot) => const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pzt'), findsOneWidget);
    expect(find.text('Paz'), findsOneWidget);

    // Grid area starts after the hour labels (44px) and the header.
    final gridTopLeft = tester.getTopLeft(find.byType(GestureDetector).last);
    final cellWidth = (400 - WeekGrid.hourLabelWidth) / 7;
    await tester.tapAt(gridTopLeft + Offset(cellWidth * 2.5, 40 * 3.5));
    expect(tapped, [(day: 2, hour: 3)]);

    await tester.tap(find.text('Paz'));
    expect(tappedDays, [6]);
  });

  testWidgets('blocks span their hours, sit on zebra rows and let taps through', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final tapped = <Slot>[];
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
            initialHour: 0,
            cellHeight: 40,
            onTap: tapped.add,
            blocks: const [
              WeekGridBlock(
                day: 1,
                fromHour: 2,
                toHour: 4,
                child: ColoredBox(key: Key('block'), color: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rowTop = tester.getTopLeft(find.byKey(const ValueKey('week-grid-row-0')));
    final columnWidth = (400 - WeekGrid.hourLabelWidth) / 7;
    final block = tester.getRect(find.byKey(const Key('block')));
    expect(block.height, 2 * 40 - 2 * WeekGrid.blockInsetY, reason: 'one block for two hours');
    expect(block.top, rowTop.dy + 2 * 40 + WeekGrid.blockInsetY);
    expect(block.left, WeekGrid.hourLabelWidth + columnWidth + WeekGrid.blockInsetX);
    expect(block.width, closeTo(columnWidth - 2 * WeekGrid.blockInsetX, 0.01));

    // Tapping the block's second hour still reaches the grid.
    await tester.tapAt(block.center + const Offset(0, 15));
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
