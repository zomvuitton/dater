import 'package:dater/core/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
    await initializeDateFormatting('en');
  });

  test('week ranges follow the locale order', () {
    final mon = DateTime(2026, 11, 9);
    final sun = DateTime(2026, 11, 15);
    expect(formatDayRange('tr', mon, sun), '9 – 15 Kas');
    expect(formatDayRange('en', mon, sun), 'Nov 9 – 15');
    expect(formatDayRange('en', DateTime(2026, 11, 30), DateTime(2026, 12, 6)), 'Nov 30 – Dec 6');
    expect(formatDayRange('tr', DateTime(2026, 11, 30), DateTime(2026, 12, 6)), '30 Kas – 6 Ara');
  });
}
