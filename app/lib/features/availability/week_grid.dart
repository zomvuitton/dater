import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

/// A 7-day × 24-hour grid with zebra-striped hour rows. Tap a cell to toggle
/// it; long-press and drag to paint a range. Scrolling vertically works as
/// usual. Content is drawn either per cell ([cellBuilder]) or as blocks that
/// span several hours ([blocks]); blocks never take touches away from the grid.
class WeekGrid extends StatefulWidget {
  const WeekGrid({
    super.key,
    required this.weekStart,
    this.cellBuilder,
    this.blocks = const [],
    this.onTap,
    this.onDayTap,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.initialHour = 8,
    this.cellHeight = 40,
  });

  final DateTime weekStart;
  final Widget Function(BuildContext context, Slot slot)? cellBuilder;
  final List<WeekGridBlock> blocks;
  final ValueChanged<Slot>? onTap;
  final ValueChanged<int>? onDayTap;
  final ValueChanged<Slot>? onDragStart;
  final ValueChanged<Slot>? onDragUpdate;
  final VoidCallback? onDragEnd;
  final int initialHour;
  final double cellHeight;

  static const hourLabelWidth = 44.0;

  /// Space between a block and its column edges / the hour lines.
  static const blockInsetX = 3.0;
  static const blockInsetY = 2.0;

  /// Background of every other hour row.
  static Color stripeColor(ThemeData theme) => theme.colorScheme.onSurface.withValues(alpha: 0.055);

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
    final scheme = theme.colorScheme;
    final locale = localeName(context);
    final today = DateTime.now();
    final days = weekDays(widget.weekStart);
    final dragEnabled = widget.onDragStart != null;
    final h = widget.cellHeight;
    final stripe = WeekGrid.stripeColor(theme);
    final separator = theme.dividerColor.withValues(alpha: 0.18);

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
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final columnWidth = width / daysPerWeek;
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              // Each cell exposes its own tap action to screen readers below.
                              excludeFromSemantics: true,
                              onTapUp: widget.onTap == null
                                  ? null
                                  : (d) => widget.onTap!(_slotAt(d.localPosition, width)),
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
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Faint day separators; today's column slightly tinted.
                                  Row(
                                    children: [
                                      for (var d = 0; d < daysPerWeek; d++)
                                        Expanded(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: DateUtils.isSameDay(days[d], today)
                                                  ? scheme.primary.withValues(alpha: 0.06)
                                                  : null,
                                              border: Border(left: BorderSide(color: separator)),
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
                                                Expanded(
                                                  child: Semantics(
                                                    button: widget.onTap != null,
                                                    label:
                                                        '${DateFormat.MMMMEEEEd(locale).format(days[d])}, ${formatHour(context, hour)}',
                                                    onTap: widget.onTap == null
                                                        ? null
                                                        : () => widget.onTap!((day: d, hour: hour)),
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
                                      left: block.day * columnWidth + WeekGrid.blockInsetX,
                                      top: block.fromHour * h + WeekGrid.blockInsetY,
                                      width: columnWidth - 2 * WeekGrid.blockInsetX,
                                      height: (block.toHour - block.fromHour) * h - 2 * WeekGrid.blockInsetY,
                                      child: IgnorePointer(child: ExcludeSemantics(child: block.child)),
                                    ),
                                ],
                              ),
                            );
                          },
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
