import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui.dart';
import '../../l10n/app_localizations.dart';
import 'plans_repository.dart';

/// Propose a plan in a circle, starting from a free hour of the heatmap.
Future<bool?> showProposePlanSheet(
  BuildContext context, {
  required String circleId,
  required DateTime start,
  required DateTime end,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _ProposePlan(circleId: circleId, start: start, end: end),
    ),
  );
}

class _ProposePlan extends ConsumerStatefulWidget {
  const _ProposePlan({required this.circleId, required this.start, required this.end});

  final String circleId;
  final DateTime start;
  final DateTime end;

  @override
  ConsumerState<_ProposePlan> createState() => _ProposePlanState();
}

class _ProposePlanState extends ConsumerState<_ProposePlan> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  late DateTime _day = DateUtils.dateOnly(widget.start);
  late TimeOfDay _from = TimeOfDay.fromDateTime(widget.start);
  late TimeOfDay _to = TimeOfDay.fromDateTime(widget.end);
  bool _busy = false;

  DateTime get _startsAt => DateTime(_day.year, _day.month, _day.day, _from.hour, _from.minute);

  /// An end time before the start time means the plan runs past midnight.
  DateTime get _endsAt {
    final sameDay = DateTime(_day.year, _day.month, _day.day, _to.hour, _to.minute);
    return sameDay.isAfter(_startsAt) ? sameDay : DateTime(_day.year, _day.month, _day.day + 1, _to.hour, _to.minute);
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(plansRepositoryProvider)
          .create(
            circleId: widget.circleId,
            title: _title.text,
            note: _note.text,
            startsAt: _startsAt,
            endsAt: _endsAt,
          );
      ref.invalidate(circlePlansProvider(widget.circleId));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.proposePlan, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              autofocus: true,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.planTitle, hintText: l10n.planTitleHint),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.event, size: 18),
                  label: Text(MaterialLocalizations.of(context).formatMediumDate(_day)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _day,
                      firstDate: DateUtils.dateOnly(DateTime.now()),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _day = picked);
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.schedule, size: 18),
                  label: Text('${_from.format(context)} – ${_to.format(context)}'),
                  onPressed: () async {
                    final from = await showTimePicker(context: context, initialTime: _from, helpText: l10n.startTime);
                    if (from == null || !context.mounted) return;
                    final to = await showTimePicker(context: context, initialTime: _to, helpText: l10n.endTime);
                    if (to == null) return;
                    setState(() {
                      _from = from;
                      _to = to;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(labelText: l10n.planNote),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy || _title.text.trim().isEmpty ? null : _submit,
              child: Text(l10n.proposePlanAction),
            ),
          ],
        ),
      ),
    );
  }
}
