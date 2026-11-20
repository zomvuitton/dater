import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models.dart';
import '../../core/ui.dart';
import '../../core/week.dart';
import '../../l10n/app_localizations.dart';
import '../notifications/notification_bell.dart';
import '../circles/circles_repository.dart';
import 'availability_repository.dart';
import 'circle_picker_sheet.dart';
import 'week_grid.dart';

/// Mark your free hours for a week and choose which circles see each of them.
class MyWeekScreen extends ConsumerStatefulWidget {
  const MyWeekScreen({super.key});

  @override
  ConsumerState<MyWeekScreen> createState() => _MyWeekScreenState();
}

class _MyWeekScreenState extends ConsumerState<MyWeekScreen> {
  DateTime _weekStart = weekStartOf(DateTime.now());
  final _selection = GridSelection();
  bool _busy = false;

  void _changeWeek(DateTime week) => setState(() {
    _weekStart = week;
    _selection.clear();
  });

  Future<void> _share(Map<Slot, Set<String>> week, List<Circle> circles) async {
    final l10n = AppLocalizations.of(context);
    if (circles.isEmpty) {
      final go = await confirm(
        context,
        title: l10n.noCirclesTitle,
        body: l10n.noCirclesBody,
        action: l10n.createCircle,
      );
      if (go && mounted) context.go('/circles');
      return;
    }
    final selected = _selection.selected;
    final existing = [for (final s in selected) week[s]].whereType<Set<String>>().toList();
    final validIds = circles.map((c) => c.id).toSet();
    // Prefill with circles every selected (already shared) hour has in common;
    // brand-new hours default to every circle.
    final initial = existing.isEmpty ? validIds : existing.reduce((a, b) => a.intersection(b)).intersection(validIds);

    final picked = await showCirclePicker(context, circles: circles, initial: initial, hourCount: selected.length);
    if (picked == null) return;
    await _save(selected, picked, l10n.sharedHours(selected.length, picked.length));
  }

  Future<void> _remove() async {
    final l10n = AppLocalizations.of(context);
    final selected = _selection.selected;
    await _save(selected, const {}, l10n.removedHours(selected.length));
  }

  Future<void> _save(Set<Slot> slots, Set<String> circleIds, String doneMessage) async {
    setState(() => _busy = true);
    try {
      await ref.read(availabilityRepositoryProvider).setSlots(_weekStart, slots, circleIds);
      ref.invalidate(myWeekProvider(_weekStart));
      ref.invalidate(circleWeekProvider);
      if (!mounted) return;
      setState(_selection.clear);
      showMessage(context, doneMessage);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyPreviousWeek() async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirm(context, title: l10n.copyWeekTitle, body: l10n.copyWeekBody, action: l10n.copyWeekAction);
    if (!ok) return;
    setState(() => _busy = true);
    try {
      final copied = await ref
          .read(availabilityRepositoryProvider)
          .copyWeek(fromWeek: addWeeks(_weekStart, -1), toWeek: _weekStart);
      ref.invalidate(myWeekProvider(_weekStart));
      ref.invalidate(circleWeekProvider);
      if (mounted) showMessage(context, l10n.copyWeekDone(copied));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final weekAsync = ref.watch(myWeekProvider(_weekStart));
    final circles = ref.watch(myCirclesProvider).value ?? const <Circle>[];
    final circleById = {for (final c in circles) c.id: c};
    final week = weekAsync.value ?? const <Slot, Set<String>>{};
    final selectedHasShared = _selection.selected.any(week.containsKey);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myWeekTitle),
        actions: [
          const NotificationBell(),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'copy') _copyPreviousWeek();
            },
            itemBuilder: (context) => [PopupMenuItem(value: 'copy', child: Text(l10n.copyPreviousWeek))],
          ),
        ],
      ),
      body: Column(
        children: [
          WeekSwitcher(weekStart: _weekStart, onChanged: _changeWeek),
          if (_busy || weekAsync.isLoading) const LinearProgressIndicator(minHeight: 2) else const SizedBox(height: 2),
          if (weekAsync.hasError)
            Expanded(
              child: ErrorView(error: weekAsync.error!, onRetry: () => ref.invalidate(myWeekProvider(_weekStart))),
            )
          else
            Expanded(
              child: WeekGrid(
                weekStart: _weekStart,
                onTap: (slot) => setState(() => _selection.toggle(slot)),
                onDayTap: (day) => setState(() => _selection.toggleDay(day)),
                onDragStart: (slot) => setState(() => _selection.startDrag(slot)),
                onDragUpdate: (slot) => setState(() => _selection.updateDrag(slot)),
                onDragEnd: () => setState(_selection.endDrag),
                blocks: [
                  // Saved hours: consecutive hours shared with the same circles form one block.
                  for (final run in valueRuns(week, equals: setEquals))
                    WeekGridBlock(
                      day: run.day,
                      fromHour: run.fromHour,
                      toHour: run.toHour,
                      child: AvailabilityBlock(
                        fromHour: run.fromHour,
                        toHour: run.toHour,
                        colors: [for (final id in run.value) ?circleById[id]?.color],
                      ),
                    ),
                  // The current selection, drawn on top.
                  for (final run in slotRuns(_selection.selected))
                    WeekGridBlock(
                      day: run.day,
                      fromHour: run.fromHour,
                      toHour: run.toHour,
                      child: AvailabilityBlock(fromHour: run.fromHour, toHour: run.toHour, selected: true),
                    ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 150),
        child: _selection.isEmpty
            ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(l10n.myWeekHint, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              )
            : Material(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(l10n.hoursSelected(_selection.selected.length))),
                      IconButton(
                        tooltip: l10n.clearSelection,
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(_selection.clear),
                      ),
                      if (selectedHasShared)
                        IconButton(
                          tooltip: l10n.removeAvailability,
                          icon: const Icon(Icons.event_busy),
                          onPressed: _busy ? null : _remove,
                        ),
                      const SizedBox(width: 4),
                      FilledButton.icon(
                        icon: const Icon(Icons.event_available),
                        onPressed: _busy || weekAsync.isLoading ? null : () => _share(week, circles),
                        label: Text(l10n.markAvailable),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// One continuous stretch of free (or selected) hours in a day column.
class AvailabilityBlock extends StatelessWidget {
  const AvailabilityBlock({
    super.key,
    required this.fromHour,
    required this.toHour,
    this.colors = const [],
    this.selected = false,
  });

  final int fromHour;
  final int toHour;

  /// Colors of the circles these hours are shared with.
  final List<Color> colors;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? scheme.onPrimary : scheme.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.fromLTRB(3, 3, 3, 4),
      decoration: BoxDecoration(
        color: selected ? scheme.primary.withValues(alpha: 0.6) : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: selected ? Border.all(color: scheme.primary, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Narrow columns: shrink the label rather than cut it off.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '$fromHour–$toHour',
              maxLines: 1,
              softWrap: false,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: foreground, fontWeight: FontWeight.w600, height: 1.1),
            ),
          ),
          const Spacer(),
          if (colors.isNotEmpty)
            Wrap(
              spacing: 2,
              runSpacing: 2,
              children: [
                for (final color in colors.take(4))
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
