import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../core/week.dart';

/// A rectangle drawn over one day column, spanning [fromHour, toHour).
class WeekGridBlock {
  const WeekGridBlock({required this.day, required this.fromHour, required this.toHour, required this.child});

  final int day;
  final int fromHour;
  final int toHour;
  final Widget child;
}

/// Horizontal layout of the seven day columns: the focused day takes
/// [focusShare] of the width and the others share the rest. [focus] may be
/// fractional while animating; the extra width then flows between the two
/// neighbouring days and the total stays constant.
class DayColumns {
  DayColumns({required this.width, required this.focus, this.focusShare = 0.36})
    : assert(focus >= 0 && focus <= daysPerWeek - 1);

  final double width;
  final double focus;
  final double focusShare;

  /// Width of a day that is not focused at all.
  double get narrow => width * (1 - focusShare) / (daysPerWeek - 1);

  /// Extra width the focused day gets on top of [narrow].
  double get extra => width * focusShare - narrow;

  double widthOf(int day) => narrow + extra * math.max(0, 1 - (day - focus).abs());

  double leftOf(int day) {
    var x = 0.0;
    for (var d = 0; d < day; d++) {
      x += widthOf(d);
    }
    return x;
  }

  /// The day column under horizontal position [x].
  int dayAt(double x) {
    var right = 0.0;
    for (var d = 0; d < daysPerWeek; d++) {
      right += widthOf(d);
      if (x < right) return d;
    }
    return daysPerWeek - 1;
  }
}

/// A week of hour rows where one day is focused and wide and the others are
/// narrow. Swipe sideways to move the focus (past Sunday / Monday it asks for
/// the next / previous week), tap a narrow day to focus it, tap an hour of
/// the focused day to toggle it, long-press and drag to paint a range.
class WeekGrid extends StatefulWidget {
  const WeekGrid({
    super.key,
    required this.weekStart,
    this.initialFocusDay,
    this.cellBuilder,
    this.blocks = const [],
    this.onTap,
    this.onDayTap,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onWeekEdge,
    this.onFocusChanged,
    this.initialHour = 8,
    this.cellHeight = 44,
  });

  final DateTime weekStart;

  /// Day to focus when the grid (or a new week) is shown; defaults to today
  /// in the current week, Monday otherwise.
  final int? initialFocusDay;
  final Widget Function(BuildContext context, Slot slot)? cellBuilder;
  final List<WeekGridBlock> blocks;

  /// Tap on an hour of the focused day.
  final ValueChanged<Slot>? onTap;

  /// Tap on the focused day's header.
  final ValueChanged<int>? onDayTap;
  final ValueChanged<Slot>? onDragStart;
  final ValueChanged<Slot>? onDragUpdate;
  final VoidCallback? onDragEnd;

  /// Swiped past the last (+1) or first (−1) day of the week.
  final ValueChanged<int>? onWeekEdge;
  final ValueChanged<int>? onFocusChanged;
  final int initialHour;
  final double cellHeight;

  static const hourLabelWidth = 44.0;

  /// Space between a block and its column edges / the hour lines.
  static const blockInsetX = 3.0;
  static const blockInsetY = 2.0;

  /// Columns at least this wide show full labels.
  static const wideColumn = 72.0;

  /// Background of every other hour row.
  static Color stripeColor(ThemeData theme) => theme.colorScheme.onSurface.withValues(alpha: 0.045);

  @override
  State<WeekGrid> createState() => _WeekGridState();
}

class _WeekGridState extends State<WeekGrid> with SingleTickerProviderStateMixin {
  late final ScrollController _scroll = ScrollController(initialScrollOffset: widget.initialHour * widget.cellHeight);
  final _viewportKey = GlobalKey();
  late int _focusDay = _initialFocus();
  late final AnimationController _focus = AnimationController(
    vsync: this,
    lowerBound: 0,
    upperBound: daysPerWeek - 1.0,
    value: _focusDay.toDouble(),
    duration: const Duration(milliseconds: 260),
  );
  double _dragDx = 0;

  int _initialFocus() => widget.initialFocusDay ?? defaultFocusDay(widget.weekStart);

  @override
  void didUpdateWidget(WeekGrid old) {
    super.didUpdateWidget(old);
    if (old.weekStart != widget.weekStart) {
      _focusDay = _initialFocus();
      _focus.value = _focusDay.toDouble();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _setFocus(int day) {
    if (day == _focusDay) return;
    setState(() => _focusDay = day);
    _focus.animateTo(day.toDouble(), curve: Curves.easeOutCubic);
    widget.onFocusChanged?.call(day);
  }

  void _step(int direction) {
    final target = _focusDay + direction;
    if (target < 0 || target >= daysPerWeek) {
      widget.onWeekEdge?.call(direction);
    } else {
      _setFocus(target);
    }
  }

  /// Taps on a narrow day focus it; taps on the focused day go to [WeekGrid.onTap].
  void _tapSlot(Slot slot) {
    if (slot.day != _focusDay) {
      _setFocus(slot.day);
    } else {
      widget.onTap?.call(slot);
    }
  }

  Slot _slotAt(Offset local, DayColumns columns) {
    final hour = (local.dy / widget.cellHeight).floor().clamp(0, hoursPerDay - 1);
    return (day: columns.dayAt(local.dx), hour: hour);
  }

  /// Scrolls a little when a drag gets close to the top or bottom edge.
  void _autoScroll(Offset globalPosition) {
    final box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !_scroll.hasClients) return;
    final y = box.globalToLocal(globalPosition).dy;
    const edge = 48.0;
    double delta = 0;
    if (y < edge) delta = -widget.cellHeight / 2;
    if (y > box.size.height - edge) delta = widget.cellHeight / 2;
    if (delta == 0) return;
    final position = _scroll.position;
    _scroll.jumpTo((_scroll.offset + delta).clamp(position.minScrollExtent, position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Sideways swipes move the focus; vertical drags still scroll the hours.
      onHorizontalDragStart: (_) => _dragDx = 0,
      onHorizontalDragUpdate: (d) => _dragDx += d.delta.dx,
      onHorizontalDragEnd: (d) {
        final velocity = d.primaryVelocity ?? 0;
        if (_dragDx.abs() > 40 || velocity.abs() > 350) {
          _step((_dragDx != 0 ? _dragDx : velocity) < 0 ? 1 : -1);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gridWidth = constraints.maxWidth - WeekGrid.hourLabelWidth;
          return AnimatedBuilder(
            animation: _focus,
            builder: (context, _) =>
                _buildGrid(context, DayColumns(width: gridWidth, focus: _focus.value.clamp(0, daysPerWeek - 1))),
          );
        },
      ),
    );
  }

  Widget _buildGrid(BuildContext context, DayColumns columns) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = localeName(context);
    final today = DateTime.now();
    final days = weekDays(widget.weekStart);
    final dragEnabled = widget.onDragStart != null;
    final h = widget.cellHeight;
    final stripe = WeekGrid.stripeColor(theme);
    final separator = scheme.outlineVariant.withValues(alpha: 0.7);

    return Column(
      children: [
        // Day headers, sized like their columns.
        Padding(
          padding: const EdgeInsets.only(left: WeekGrid.hourLabelWidth),
          child: Row(
            children: [
              for (var d = 0; d < daysPerWeek; d++)
                SizedBox(
                  width: columns.widthOf(d),
                  child: _DayHeader(
                    date: days[d],
                    locale: locale,
                    wide: columns.widthOf(d) >= WeekGrid.wideColumn,
                    focused: d == _focusDay,
                    isToday: DateUtils.isSameDay(days[d], today),
                    onTap: () => d == _focusDay ? widget.onDayTap?.call(d) : _setFocus(d),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            key: _viewportKey,
            controller: _scroll,
            child: SizedBox(
              height: hoursPerDay * h,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Zebra rows, running under the hour labels too.
                  Column(
                    children: [
                      for (var hour = 0; hour < hoursPerDay; hour++)
                        SizedBox(
                          key: ValueKey('week-grid-row-$hour'),
                          height: h,
                          width: double.infinity,
                          child: ColoredBox(color: hour.isEven ? stripe : Colors.transparent),
                        ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: WeekGrid.hourLabelWidth,
                        child: Column(
                          children: [
                            for (var hour = 0; hour < hoursPerDay; hour++)
                              SizedBox(
                                height: h,
                                child: Center(
                                  child: Text(
                                    formatHour(context, hour),
                                    style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          // Each cell exposes its own tap action to screen readers below.
                          excludeFromSemantics: true,
                          onTapUp: (d) => _tapSlot(_slotAt(d.localPosition, columns)),
                          onLongPressStart: dragEnabled
                              ? (d) => widget.onDragStart!(_slotAt(d.localPosition, columns))
                              : null,
                          onLongPressMoveUpdate: dragEnabled
                              ? (d) {
                                  _autoScroll(d.globalPosition);
                                  widget.onDragUpdate?.call(_slotAt(d.localPosition, columns));
                                }
                              : null,
                          onLongPressEnd: dragEnabled ? (_) => widget.onDragEnd?.call() : null,
                          onLongPressCancel: dragEnabled ? widget.onDragEnd : null,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Day separators; the focused day is softly lit.
                              Row(
                                children: [
                                  for (var d = 0; d < daysPerWeek; d++)
                                    SizedBox(
                                      width: columns.widthOf(d),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: scheme.primary.withValues(
                                            alpha: 0.07 * math.max(0, 1 - (d - columns.focus).abs()),
                                          ),
                                          border: d == 0 ? null : Border(left: BorderSide(color: separator)),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              // Cells: per-hour content and screen-reader tap targets.
                              Column(
                                children: [
                                  for (var hour = 0; hour < hoursPerDay; hour++)
                                    SizedBox(
                                      height: h,
                                      child: Row(
                                        children: [
                                          for (var d = 0; d < daysPerWeek; d++)
                                            SizedBox(
                                              width: columns.widthOf(d),
                                              child: Semantics(
                                                button: true,
                                                label:
                                                    '${DateFormat.MMMMEEEEd(locale).format(days[d])}, ${formatHour(context, hour)}',
                                                onTap: () => _tapSlot((day: d, hour: hour)),
                                                child:
                                                    widget.cellBuilder?.call(context, (day: d, hour: hour)) ??
                                                    const SizedBox.expand(),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              // Multi-hour blocks on top.
                              for (final block in widget.blocks)
                                Positioned(
                                  left: columns.leftOf(block.day) + WeekGrid.blockInsetX,
                                  top: block.fromHour * h + WeekGrid.blockInsetY,
                                  width: math.max(0, columns.widthOf(block.day) - 2 * WeekGrid.blockInsetX),
                                  height: (block.toHour - block.fromHour) * h - 2 * WeekGrid.blockInsetY,
                                  child: IgnorePointer(child: ExcludeSemantics(child: block.child)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.date,
    required this.locale,
    required this.wide,
    required this.focused,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final String locale;
  final bool wide;
  final bool focused;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ink = AppTheme.ink(scheme);
    final weekday = wide ? DateFormat.EEEE(locale).format(date) : DateFormat.E(locale).format(date);
    final dayColor = isToday ? ink : (focused ? scheme.onSurface : scheme.onSurfaceVariant);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
        child: Column(
          children: [
            Text(
              weekday,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: (wide ? theme.textTheme.labelLarge : theme.textTheme.labelSmall)?.copyWith(
                color: focused ? scheme.onSurface : scheme.onSurfaceVariant,
                fontWeight: focused ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat.d(locale).format(date),
              style: (wide ? theme.textTheme.headlineSmall : theme.textTheme.titleSmall)?.copyWith(
                color: dayColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: focused ? 28 : 0,
              decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

/// "‹  16 – 22 Kas  ›" week switcher used above the grid.
class WeekSwitcher extends StatelessWidget {
  const WeekSwitcher({super.key, required this.weekStart, required this.onChanged, this.trailing});

  final DateTime weekStart;
  final ValueChanged<DateTime> onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: () => onChanged(addWeeks(weekStart, -1))),
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onSurface),
              onPressed: () => onChanged(weekStartOf(DateTime.now())),
              child: Text(formatWeekRange(context, weekStart), style: theme.textTheme.titleMedium),
            ),
          ),
          IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: () => onChanged(addWeeks(weekStart, 1))),
          ?trailing,
        ],
      ),
    );
  }
}
