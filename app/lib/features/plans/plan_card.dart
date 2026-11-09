import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/ui.dart';
import '../../l10n/app_localizations.dart';
import 'plans_repository.dart';

/// A proposed plan with everyone's answers and the caller's own answer.
class PlanCard extends ConsumerWidget {
  const PlanCard({super.key, required this.plan, required this.members, required this.myId, required this.canDelete});

  final Plan plan;
  final Map<String, Profile> members;
  final String myId;
  final bool canDelete;

  Future<void> _respond(BuildContext context, WidgetRef ref, PlanResponseStatus status) async {
    try {
      await ref.read(plansRepositoryProvider).respond(plan.id, status);
      ref.invalidate(circlePlansProvider(plan.circleId));
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirm(context, title: l10n.deletePlanTitle, action: l10n.delete);
    if (!ok) return;
    try {
      await ref.read(plansRepositoryProvider).delete(plan.id);
      ref.invalidate(circlePlansProvider(plan.circleId));
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final creator = members[plan.createdBy];
    final going = [
      for (final MapEntry(key: id, value: status) in plan.responses.entries)
        if (status == PlanResponseStatus.going) members[id]?.label ?? '?',
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(plan.title, style: theme.textTheme.titleMedium)),
                if (canDelete)
                  IconButton(
                    tooltip: l10n.delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(context, ref),
                  ),
              ],
            ),
            Text(formatTimeRange(context, plan.startsAt, plan.endsAt), style: theme.textTheme.bodyMedium),
            if (creator != null) Text(l10n.proposedBy(creator.label), style: theme.textTheme.bodySmall),
            if (plan.note != null) ...[const SizedBox(height: 8), Text(plan.note!)],
            const SizedBox(height: 8),
            Text(
              l10n.planCounts(
                plan.count(PlanResponseStatus.going),
                plan.count(PlanResponseStatus.maybe),
                plan.count(PlanResponseStatus.no),
              ),
              style: theme.textTheme.labelMedium,
            ),
            if (going.isNotEmpty) Text(going.join(', '), style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            SegmentedButton<PlanResponseStatus>(
              emptySelectionAllowed: true,
              showSelectedIcon: true,
              selected: {?plan.responses[myId]},
              onSelectionChanged: (s) {
                if (s.isNotEmpty) _respond(context, ref, s.first);
              },
              segments: [
                ButtonSegment(value: PlanResponseStatus.going, label: Text(l10n.going)),
                ButtonSegment(value: PlanResponseStatus.maybe, label: Text(l10n.maybe)),
                ButtonSegment(value: PlanResponseStatus.no, label: Text(l10n.notGoing)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
