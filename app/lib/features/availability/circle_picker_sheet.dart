import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../l10n/app_localizations.dart';

/// "Who can see these hours?" — pick the circles to share the selected hours
/// with. Returns the chosen circle ids, or null if dismissed.
Future<Set<String>?> showCirclePicker(
  BuildContext context, {
  required List<Circle> circles,
  required Set<String> initial,
  required int hourCount,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _CirclePicker(circles: circles, initial: initial, hourCount: hourCount),
  );
}

class _CirclePicker extends StatefulWidget {
  const _CirclePicker({required this.circles, required this.initial, required this.hourCount});

  final List<Circle> circles;
  final Set<String> initial;
  final int hourCount;

  @override
  State<_CirclePicker> createState() => _CirclePickerState();
}

class _CirclePickerState extends State<_CirclePicker> {
  late final Set<String> _selected = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final allSelected = _selected.length == widget.circles.length;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(l10n.pickerTitle, style: theme.textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: Text(l10n.pickerSubtitle(widget.hourCount)),
            ),
            CheckboxListTile(
              value: allSelected,
              title: Text(l10n.pickerAllCircles),
              onChanged: (v) => setState(() {
                _selected.clear();
                if (v == true) _selected.addAll(widget.circles.map((c) => c.id));
              }),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final circle in widget.circles)
                    CheckboxListTile(
                      value: _selected.contains(circle.id),
                      secondary: CircleAvatar(
                        backgroundColor: circle.color.withValues(alpha: 0.2),
                        child: Text(circle.emoji),
                      ),
                      title: Text(circle.name),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _selected.add(circle.id);
                        } else {
                          _selected.remove(circle.id);
                        }
                      }),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                icon: const Icon(Icons.check),
                onPressed: _selected.isEmpty ? null : () => Navigator.pop(context, _selected),
                label: Text(l10n.pickerSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
