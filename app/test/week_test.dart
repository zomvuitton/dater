import 'package:dater/core/week.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('weekStartOf', () {
    test('returns Monday midnight for any day of the week', () {
      final monday = DateTime(2026, 11, 9);
      for (var d = 0; d < 7; d++) {
        expect(weekStartOf(DateTime(2026, 11, 9 + d, 15, 30)), monday);
      }
    });

    test('crosses month and year boundaries', () {
      expect(weekStartOf(DateTime(2026, 1, 1)), DateTime(2025, 12, 29));
      expect(weekStartOf(DateTime(2026, 3, 1)), DateTime(2026, 2, 23));
    });
  });

  test('addWeeks keeps local midnight', () {
    final ws = DateTime(2026, 10, 19);
    expect(addWeeks(ws, 1), DateTime(2026, 10, 26));
    expect(addWeeks(ws, -1), DateTime(2026, 10, 12));
    expect(addWeeks(ws, 2).hour, 0);
  });

  group('slots', () {
    final ws = DateTime(2026, 11, 9);

    test('slotStart and slotOf are inverse', () {
      for (final slot in [(day: 0, hour: 0), (day: 3, hour: 19), (day: 6, hour: 23)]) {
        final start = slotStart(ws, slot);
        expect(slotOf(ws, start), slot);
        expect(slotOf(ws, start.toUtc()), slot, reason: 'UTC instants map back to local slots');
      }
    });

    test('slotOf returns null outside the week', () {
      expect(slotOf(ws, DateTime(2026, 11, 8, 23)), isNull);
      expect(slotOf(ws, DateTime(2026, 11, 16)), isNull);
    });

    test('weekRangeUtc spans 7 days', () {
      final range = weekRangeUtc(ws);
      expect(range.start, ws.toUtc());
      expect(range.end, DateTime(2026, 11, 16).toUtc());
    });
  });

  test('slots keep their local hour across a daylight-saving change', () {
    // In Europe DST ends on 25 Oct 2026; run with TZ=Europe/Berlin to exercise it.
    final before = DateTime(2026, 10, 19);
    final after = addWeeks(before, 1);
    for (final slot in [(day: 0, hour: 19), (day: 6, hour: 23), (day: 6, hour: 0)]) {
      expect(slotOf(after, slotStart(after, slot).toUtc()), slot);
      expect(slotStart(after, slot).hour, slotStart(before, slot).hour);
    }
  });

  test('slotRect covers the rectangle in any drag direction', () {
    final rect = slotRect((day: 2, hour: 10), (day: 1, hour: 8));
    expect(rect.length, 6);
    expect(rect, containsAll([(day: 1, hour: 8), (day: 2, hour: 10), (day: 1, hour: 10)]));
  });

  test('slotRuns merges consecutive hours per day', () {
    final runs = slotRuns({
      (day: 1, hour: 9),
      (day: 1, hour: 10),
      (day: 1, hour: 11),
      (day: 1, hour: 14),
      (day: 0, hour: 20),
    });
    expect(runs, [
      (day: 0, fromHour: 20, toHour: 21),
      (day: 1, fromHour: 9, toHour: 12),
      (day: 1, fromHour: 14, toHour: 15),
    ]);
  });

  group('GridSelection', () {
    test('toggle adds and removes', () {
      final s = GridSelection()..toggle((day: 0, hour: 9));
      expect(s.contains((day: 0, hour: 9)), isTrue);
      s.toggle((day: 0, hour: 9));
      expect(s.isEmpty, isTrue);
    });

    test('toggleDay selects then clears a whole day', () {
      final s = GridSelection()..toggle((day: 2, hour: 5));
      s.toggleDay(2);
      expect(s.selected.length, 24);
      s.toggleDay(2);
      expect(s.isEmpty, isTrue);
    });

    test('drag from an empty cell paints, and shrinking restores', () {
      final s = GridSelection({(day: 5, hour: 1)});
      s.startDrag((day: 0, hour: 9));
      s.updateDrag((day: 1, hour: 11));
      expect(s.selected.length, 1 + 6);
      s.updateDrag((day: 0, hour: 10));
      expect(s.selected, {(day: 5, hour: 1), (day: 0, hour: 9), (day: 0, hour: 10)});
      s.endDrag();
      expect(s.isDragging, isFalse);
    });

    test('drag from a selected cell erases', () {
      final s = GridSelection(slotRect((day: 0, hour: 8), (day: 0, hour: 12)));
      s.startDrag((day: 0, hour: 9));
      s.updateDrag((day: 0, hour: 10));
      s.endDrag();
      expect(s.selected, {(day: 0, hour: 8), (day: 0, hour: 11), (day: 0, hour: 12)});
    });
  });
}
