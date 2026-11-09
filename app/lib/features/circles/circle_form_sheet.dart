import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../l10n/app_localizations.dart';

typedef CircleFormResult = ({String name, String emoji, String colorHex});

/// Create a new circle, or edit [existing].
Future<CircleFormResult?> showCircleForm(BuildContext context, {Circle? existing}) {
  return showModalBottomSheet<CircleFormResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _CircleForm(existing: existing),
    ),
  );
}

class _CircleForm extends StatefulWidget {
  const _CircleForm({this.existing});

  final Circle? existing;

  @override
  State<_CircleForm> createState() => _CircleFormState();
}

class _CircleFormState extends State<_CircleForm> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late String _emoji = widget.existing?.emoji ?? circleEmojiChoices.first;
  late Color _color = widget.existing?.color ?? circleColorChoices.first;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, (name: name, emoji: _emoji, colorHex: colorToHex(_color)));
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
            Text(widget.existing == null ? l10n.newCircle : l10n.editCircle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              autofocus: widget.existing == null,
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.circleName, hintText: l10n.circleNameHint),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            Text(l10n.circleIcon, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final emoji in circleEmojiChoices)
                  ChoiceChip(
                    label: Text(emoji, style: const TextStyle(fontSize: 18)),
                    selected: _emoji == emoji,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _emoji = emoji),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.circleColor, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final color in circleColorChoices)
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _color = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: _color.toARGB32() == color.toARGB32()
                            ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _name.text.trim().isEmpty ? null : _submit,
              child: Text(widget.existing == null ? l10n.createCircle : l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
