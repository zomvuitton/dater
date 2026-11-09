/// Week and hour-slot arithmetic.
///
/// Weeks start on Monday at local midnight. A [Slot] is a one-hour block
/// identified by its day index in the week (0 = Monday) and its local start
/// hour. All conversions build local [DateTime]s from calendar fields so that
/// daylight-saving changes never shift a slot to a different hour.
library;

typedef Slot = ({int day, int hour});

const daysPerWeek = 7;
const hoursPerDay = 24;

/// Monday 00:00 (local) of the week containing [date].
DateTime weekStartOf(DateTime date) {
  final local = date.isUtc ? date.toLocal() : date;
  return DateTime(local.year, local.month, local.day - (local.weekday - DateTime.monday));
}

/// The Monday [weeks] weeks after [weekStart] (negative goes back).
DateTime addWeeks(DateTime weekStart, int weeks) =>
    DateTime(weekStart.year, weekStart.month, weekStart.day + weeks * daysPerWeek);

/// Local midnight of each day in the week.
List<DateTime> weekDays(DateTime weekStart) => [
  for (var d = 0; d < daysPerWeek; d++) DateTime(weekStart.year, weekStart.month, weekStart.day + d),
];

/// The local start time of [slot] in the week starting at [weekStart].
DateTime slotStart(DateTime weekStart, Slot slot) =>
    DateTime(weekStart.year, weekStart.month, weekStart.day + slot.day, slot.hour);

/// The slot a point in time falls in, or null if it is outside the week.
Slot? slotOf(DateTime weekStart, DateTime time) {
  final local = time.isUtc ? time.toLocal() : time;
  // Compare calendar dates in UTC so DST-length days don't skew the count.
  final day = DateTime.utc(
    local.year,
    local.month,
    local.day,
  ).difference(DateTime.utc(weekStart.year, weekStart.month, weekStart.day)).inDays;
  if (day < 0 || day >= daysPerWeek) return null;
  return (day: day, hour: local.hour);
}

/// [start, end) of the week as UTC instants, for querying the database.
({DateTime start, DateTime end}) weekRangeUtc(DateTime weekStart) =>
    (start: weekStart.toUtc(), end: addWeeks(weekStart, 1).toUtc());

/// All slots in the rectangle spanned by [a] and [b] (inclusive).
Set<Slot> slotRect(Slot a, Slot b) {
  final d0 = a.day < b.day ? a.day : b.day;
  final d1 = a.day < b.day ? b.day : a.day;
  final h0 = a.hour < b.hour ? a.hour : b.hour;
  final h1 = a.hour < b.hour ? b.hour : a.hour;
  return {
    for (var d = d0; d <= d1; d++)
      for (var h = h0; h <= h1; h++) (day: d, hour: h),
  };
}

/// Every slot of [day].
Set<Slot> daySlots(int day) => {for (var h = 0; h < hoursPerDay; h++) (day: day, hour: h)};

/// Groups slots of one day into consecutive runs of hours, e.g. 9,10,11,14 ->
/// [9..11], [14..14]. Used to describe availability as time ranges.
List<({int day, int fromHour, int toHour})> slotRuns(Iterable<Slot> slots) {
  final sorted = slots.toList()..sort((a, b) => a.day != b.day ? a.day.compareTo(b.day) : a.hour.compareTo(b.hour));
  final runs = <({int day, int fromHour, int toHour})>[];
  for (final s in sorted) {
    if (runs.isNotEmpty && runs.last.day == s.day && runs.last.toHour == s.hour) {
      final last = runs.removeLast();
      runs.add((day: last.day, fromHour: last.fromHour, toHour: s.hour + 1));
    } else {
      runs.add((day: s.day, fromHour: s.hour, toHour: s.hour + 1));
    }
  }
  return runs;
}

/// Drag-to-paint selection over the grid.
///
/// A drag starting on an unselected cell adds the rectangle between the start
/// cell and the current cell; a drag starting on a selected cell removes it.
class GridSelection {
  GridSelection([Set<Slot>? initial]) : _selected = {...?initial};

  Set<Slot> _selected;
  Set<Slot>? _base;
  Slot? _anchor;
  bool _adding = true;

  Set<Slot> get selected => Set.unmodifiable(_selected);
  bool get isEmpty => _selected.isEmpty;
  bool get isDragging => _anchor != null;
  bool contains(Slot slot) => _selected.contains(slot);

  void toggle(Slot slot) {
    if (!_selected.remove(slot)) _selected.add(slot);
  }

  /// Selects the whole day, or clears it if it was already fully selected.
  void toggleDay(int day) {
    final all = daySlots(day);
    if (_selected.containsAll(all)) {
      _selected.removeAll(all);
    } else {
      _selected.addAll(all);
    }
  }

  void startDrag(Slot slot) {
    _anchor = slot;
    _base = {..._selected};
    _adding = !_selected.contains(slot);
    updateDrag(slot);
  }

  /// Recomputes the selection from the pre-drag snapshot, so shrinking the
  /// rectangle restores the cells it no longer covers.
  void updateDrag(Slot slot) {
    final anchor = _anchor;
    final base = _base;
    if (anchor == null || base == null) return;
    final rect = slotRect(anchor, slot);
    _selected = _adding ? base.union(rect) : base.difference(rect);
  }

  void endDrag() {
    _anchor = null;
    _base = null;
  }

  void clear() => _selected.clear();
}
