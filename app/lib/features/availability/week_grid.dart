import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/ui.dart';
import '../../core/week.dart';

/// A 7-day × 24-hour grid. Tap a cell to toggle it; long-press and drag to
/// paint a range. Scrolling vertically works as usual.
class WeekGrid extends StatefulWidget {
  const WeekGrid({
    super.key,
    required this.weekStart,
    required this.cellBuilder,
    this.onTap,
    this.onDayTap,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.initialHour = 8,
    this.cellHeight = 40,
  });

  final DateTime weekStart;
  final Widget Function(BuildContext context, Slot slot) cellBuilder;
  final ValueChanged<Slot>? onTap;
  final ValueChanged<int>? onDayTap;
  final ValueChanged<Slot>? onDragStart;
  final ValueChanged<Slot>? onDragUpdate;
  final VoidCallback? onDragEnd;
  final int initialHour;
  final double cellHeight;

  static const hourLabelWidth = 44.0;

  @override
  State<WeekGrid> createState() => _WeekGridState();
}

class _WeekGridState extends State<WeekGrid> {
  late final ScrollController _scroll = ScrollController(initialScrollOffset: widget.initialHour * widget.cellHeight);
  final _viewportKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Slot _slotAt(Offset local, double width) {
    final day = (local.dx / (width / daysPerWeek)).floor().clamp(0, daysPerWeek - 1);
    final hour = (local.dy / widget.cellHeight).floor().clamp(0, hoursPerDay - 1);
    return (day: day, hour: hour);
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
    final theme = Theme.of(context);
    final locale = localeName(context);
    final today = DateTime.now();
    final days = weekDays(widget.weekStart);
    final dragEnabled = widget.onDragStart != null;

    return Column(
      children: [
        // Day headers.
        Padding(
          padding: const EdgeInsets.only(left: WeekGrid.hourLabelWidth),
          child: Row(
            children: [
              for (var d = 0; d < daysPerWeek; d++)
                Expanded(
                  child: _DayHeader(
                    weekday: DateFormat.E(locale).format(days[d]),
                    dayOfMonth: DateFormat.d(locale).format(days[d]),
                    isToday: DateUtils.isSameDay(days[d], today),
                    onTap: widget.onDayTap == null ? null : () => widget.onDayTap!(d),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            key: _viewportKey,
            controller: _scroll,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: WeekGrid.hourLabelWidth,
                  child: Column(
                    children: [
                      for (var h = 0; h < hoursPerDay; h++)
                        SizedBox(
                          height: widget.cellHeight,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(formatHour(context, h), style: theme.textTheme.labelSmall),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        // Each cell exposes its own tap action to screen readers below.
                        excludeFromSemantics: true,
                        onTapUp: widget.onTap == null ? null : (d) => widget.onTap!(_slotAt(d.localPosition, width)),
                        onLongPressStart: dragEnabled
                            ? (d) => widget.onDragStart!(_slotAt(d.localPosition, width))
                            : null,
                        onLongPressMoveUpdate: dragEnabled
                            ? (d) {
                                _autoScroll(d.globalPosition);
                                widget.onDragUpdate?.call(_slotAt(d.localPosition, width));
                              }
                            : null,
                        onLongPressEnd: dragEnabled ? (_) => widget.onDragEnd?.call() : null,
                        onLongPressCancel: dragEnabled ? widget.onDragEnd : null,
                        child: Column(
                          children: [
                            for (var h = 0; h < hoursPerDay; h++)
                              SizedBox(
                                height: widget.cellHeight,
                                child: Row(
                                  children: [
                                    for (var d = 0; d < daysPerWeek; d++)
                                      Expanded(
                                        child: Semantics(
                                          button: widget.onTap != null,
                                          label:
                                              '${DateFormat.MMMMEEEEd(locale).format(days[d])}, ${formatHour(context, h)}',
                                          onTap: widget.onTap == null ? null : () => widget.onTap!((day: d, hour: h)),
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
                                                left: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
                                              ),
                                            ),
                                            child: widget.cellBuilder(context, (day: d, hour: h)),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.weekday, required this.dayOfMonth, required this.isToday, this.onTap});

  final String weekday;
  final String dayOfMonth;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Text(weekday, style: text.labelSmall, maxLines: 1, overflow: TextOverflow.clip),
            const SizedBox(height: 2),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: isToday ? BoxDecoration(color: scheme.primary, shape: BoxShape.circle) : null,
              child: Text(dayOfMonth, style: text.titleSmall?.copyWith(color: isToday ? scheme.onPrimary : null)),
            ),
          ],
        ),
      ),
    );
  }
}

/// "← 10 – 16 Nov →" week switcher used above the grid.
class WeekSwitcher extends StatelessWidget {
  const WeekSwitcher({super.key, required this.weekStart, required this.onChanged, this.trailing});

  final DateTime weekStart;
  final ValueChanged<DateTime> onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => onChanged(addWeeks(weekStart, -1))),
          Expanded(
            child: TextButton(
              onPressed: () => onChanged(weekStartOf(DateTime.now())),
              child: Text(formatWeekRange(context, weekStart), style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => onChanged(addWeeks(weekStart, 1))),
          ?trailing,
        ],
      ),
    );
  }
}
