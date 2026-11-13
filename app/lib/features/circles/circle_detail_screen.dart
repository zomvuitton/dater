import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models.dart';
import '../../core/supabase.dart';
import '../../core/ui.dart';
import '../../core/week.dart';
import '../../l10n/app_localizations.dart';
import '../availability/availability_repository.dart';
import '../availability/week_grid.dart';
import '../friends/friends_repository.dart';
import '../plans/plan_card.dart';
import '../plans/plans_repository.dart';
import '../plans/propose_plan_sheet.dart';
import 'circle_form_sheet.dart';
import 'circles_repository.dart';
import 'invite_sheet.dart';

enum CircleTab {
  week,
  plans,
  members;

  static CircleTab fromQuery(String? value) => values.firstWhere((t) => t.name == value, orElse: () => week);
}

class CircleDetailScreen extends ConsumerWidget {
  const CircleDetailScreen({super.key, required this.circleId, this.initialTab = CircleTab.week});

  final String circleId;
  final CircleTab initialTab;

  Future<void> _onMenu(BuildContext context, WidgetRef ref, Circle circle, String action) async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(circlesRepositoryProvider);
    try {
      switch (action) {
        case 'edit':
          final result = await showCircleForm(context, existing: circle);
          if (result == null) return;
          await repo.update(circle.id, name: result.name, emoji: result.emoji, colorHex: result.colorHex);
          invalidateCircles(ref);
        case 'regenerate':
          final ok = await confirm(
            context,
            title: l10n.regenerateCodeTitle,
            body: l10n.regenerateCodeBody,
            action: l10n.regenerateCode,
          );
          if (!ok) return;
          await repo.regenerateInviteCode(circle.id);
          invalidateCircles(ref);
        case 'leave':
          final ok = await confirm(
            context,
            title: l10n.leaveCircleTitle(circle.name),
            body: l10n.leaveCircleBody,
            action: l10n.leaveCircle,
          );
          if (!ok) return;
          await repo.removeMember(circle.id, ref.read(supabaseProvider).auth.currentUser!.id);
          invalidateCircles(ref);
          if (context.mounted) context.go('/circles');
        case 'delete':
          final ok = await confirm(
            context,
            title: l10n.deleteCircleTitle(circle.name),
            body: l10n.deleteCircleBody,
            action: l10n.delete,
          );
          if (!ok) return;
          await repo.delete(circle.id);
          invalidateCircles(ref);
          if (context.mounted) context.go('/circles');
      }
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final circleAsync = ref.watch(circleProvider(circleId));
    final me = ref.watch(currentUserIdProvider).value;

    return circleAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(error: e, onRetry: () => ref.invalidate(circleProvider(circleId))),
      ),
      data: (circle) {
        final isOwner = circle.ownerId == me;
        return DefaultTabController(
          length: 3,
          initialIndex: initialTab.index,
          child: Scaffold(
            appBar: AppBar(
              title: Text('${circle.emoji} ${circle.name}'),
              actions: [
                IconButton(
                  tooltip: l10n.invite,
                  icon: const Icon(Icons.person_add_alt),
                  onPressed: () => showInviteSheet(context, circle),
                ),
                PopupMenuButton<String>(
                  onSelected: (a) => _onMenu(context, ref, circle, a),
                  itemBuilder: (context) => [
                    if (isOwner) ...[
                      PopupMenuItem(value: 'edit', child: Text(l10n.editCircle)),
                      PopupMenuItem(value: 'regenerate', child: Text(l10n.regenerateCode)),
                      PopupMenuItem(value: 'delete', child: Text(l10n.deleteCircle)),
                    ] else
                      PopupMenuItem(value: 'leave', child: Text(l10n.leaveCircle)),
                  ],
                ),
              ],
              bottom: TabBar(
                tabs: [
                  Tab(text: l10n.tabWeek),
                  Tab(text: l10n.tabPlans),
                  Tab(text: l10n.tabMembers),
                ],
              ),
            ),
            body: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _CircleWeekTab(circle: circle),
                _CirclePlansTab(circle: circle, isOwner: isOwner),
                _CircleMembersTab(circle: circle, isOwner: isOwner),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Heatmap of how many members are free each hour.
class _CircleWeekTab extends ConsumerStatefulWidget {
  const _CircleWeekTab({required this.circle});

  final Circle circle;

  @override
  ConsumerState<_CircleWeekTab> createState() => _CircleWeekTabState();
}

class _CircleWeekTabState extends ConsumerState<_CircleWeekTab> {
  DateTime _weekStart = weekStartOf(DateTime.now());

  Future<void> _showSlot(Slot slot, Set<String> freeIds, Map<String, Profile> members) async {
    final l10n = AppLocalizations.of(context);
    final start = slotStart(_weekStart, slot);
    final end = start.add(const Duration(hours: 1));
    final free = [for (final id in freeIds) ?members[id]]..sort((a, b) => a.label.compareTo(b.label));
    final propose = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(formatTimeRange(context, start, end), style: Theme.of(context).textTheme.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: Text(l10n.freeCount(free.length, members.length)),
            ),
            if (free.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.nobodyFree, textAlign: TextAlign.center),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final p in free)
                      ListTile(
                        leading: ProfileAvatar(p),
                        title: Text(p.label),
                        subtitle: p.username == null ? null : Text('@${p.username}'),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                icon: const Icon(Icons.celebration_outlined),
                label: Text(l10n.proposePlan),
                onPressed: () => Navigator.pop(context, true),
              ),
            ),
          ],
        ),
      ),
    );
    if (propose == true && mounted) {
      // Extend the default end time over the following hours with the same people free.
      final week = ref.read(circleWeekProvider((circleId: widget.circle.id, weekStart: _weekStart))).value ?? {};
      var hours = 1;
      while (slot.hour + hours < hoursPerDay &&
          hours < 4 &&
          (week[(day: slot.day, hour: slot.hour + hours)]?.containsAll(freeIds) ?? false) &&
          freeIds.isNotEmpty) {
        hours++;
      }
      final created = await showProposePlanSheet(
        context,
        circleId: widget.circle.id,
        start: start,
        end: slotStart(_weekStart, (day: slot.day, hour: slot.hour + hours - 1)).add(const Duration(hours: 1)),
      );
      if (created == true && mounted) {
        DefaultTabController.of(context).animateTo(1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final key = (circleId: widget.circle.id, weekStart: _weekStart);
    final weekAsync = ref.watch(circleWeekProvider(key));
    final membersAsync = ref.watch(circleMembersProvider(widget.circle.id));
    final plans = ref.watch(circlePlansProvider(widget.circle.id)).value ?? const <Plan>[];

    final members = {for (final m in membersAsync.value ?? const <CircleMember>[]) m.profile.id: m.profile};
    final total = members.isEmpty ? 1 : members.length;
    final week = weekAsync.value ?? const <Slot, Set<String>>{};

    // Hours covered by a plan get a marker.
    final planSlots = <Slot>{};
    for (final plan in plans) {
      for (var t = plan.startsAt; t.isBefore(plan.endsAt); t = t.add(const Duration(hours: 1))) {
        final s = slotOf(_weekStart, t);
        if (s != null) planSlots.add(s);
      }
    }

    return Column(
      children: [
        WeekSwitcher(weekStart: _weekStart, onChanged: (w) => setState(() => _weekStart = w)),
        if (weekAsync.isLoading) const LinearProgressIndicator(minHeight: 2) else const SizedBox(height: 2),
        if (weekAsync.hasError)
          Expanded(
            child: ErrorView(error: weekAsync.error!, onRetry: () => ref.invalidate(circleWeekProvider(key))),
          )
        else
          Expanded(
            child: WeekGrid(
              weekStart: _weekStart,
              onTap: (slot) => _showSlot(slot, week[slot] ?? const {}, members),
              cellBuilder: (context, slot) {
                final count = week[slot]?.length ?? 0;
                final everyone = count > 0 && count >= members.length;
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(1.5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: count == 0 ? null : scheme.primary.withValues(alpha: 0.15 + 0.75 * count / total),
                        borderRadius: BorderRadius.circular(6),
                        border: everyone ? Border.all(color: scheme.primary, width: 2) : null,
                      ),
                      child: count == 0
                          ? null
                          : Text(
                              '$count',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: count / total > 0.5 ? scheme.onPrimary : scheme.onSurface,
                              ),
                            ),
                    ),
                    if (planSlots.contains(slot))
                      Positioned(top: 3, right: 3, child: Icon(Icons.star, size: 10, color: scheme.tertiary)),
                  ],
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: Text(l10n.heatmapHint, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

class _CirclePlansTab extends ConsumerWidget {
  const _CirclePlansTab({required this.circle, required this.isOwner});

  final Circle circle;
  final bool isOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(currentUserIdProvider).value ?? '';
    final plansAsync = ref.watch(circlePlansProvider(circle.id));
    final members = {
      for (final m in ref.watch(circleMembersProvider(circle.id)).value ?? const <CircleMember>[])
        m.profile.id: m.profile,
    };

    return plansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(circlePlansProvider(circle.id))),
      data: (plans) => plans.isEmpty
          ? EmptyState(icon: Icons.celebration_outlined, title: l10n.plansEmptyTitle, body: l10n.plansEmptyBody)
          : RefreshIndicator(
              onRefresh: () => ref.refresh(circlePlansProvider(circle.id).future),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final plan in plans)
                    PlanCard(plan: plan, members: members, myId: me, canDelete: isOwner || plan.createdBy == me),
                ],
              ),
            ),
    );
  }
}

class _CircleMembersTab extends ConsumerWidget {
  const _CircleMembersTab({required this.circle, required this.isOwner});

  final Circle circle;
  final bool isOwner;

  Future<void> _addFriends(BuildContext context, WidgetRef ref, List<CircleMember> members) async {
    final l10n = AppLocalizations.of(context);
    final friends = await ref.read(friendsProvider.future);
    final memberIds = members.map((m) => m.profile.id).toSet();
    final candidates = friends.where((f) => !memberIds.contains(f.id)).toList();
    if (!context.mounted) return;
    if (candidates.isEmpty) {
      showMessage(context, l10n.noFriendsToAdd);
      return;
    }
    final picked = await showModalBottomSheet<Profile>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(l10n.addFriendToCircle, style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final f in candidates)
              ListTile(
                leading: ProfileAvatar(f),
                title: Text(f.label),
                subtitle: Text('@${f.username}'),
                trailing: const Icon(Icons.add),
                onTap: () => Navigator.pop(context, f),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    try {
      await ref.read(circlesRepositoryProvider).addMember(circle.id, picked.id);
      invalidateCircles(ref);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, Profile member) async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirm(context, title: l10n.removeMemberTitle(member.label), action: l10n.remove);
    if (!ok) return;
    try {
      await ref.read(circlesRepositoryProvider).removeMember(circle.id, member.id);
      invalidateCircles(ref);
      ref.invalidate(circleWeekProvider);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(currentUserIdProvider).value;
    final membersAsync = ref.watch(circleMembersProvider(circle.id));

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(circleMembersProvider(circle.id))),
      data: (members) => ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.link)),
            title: Text(l10n.inviteWithLink),
            subtitle: Text(l10n.inviteWithLinkBody),
            onTap: () => showInviteSheet(context, circle),
          ),
          if (isOwner)
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_add)),
              title: Text(l10n.addFriendToCircle),
              onTap: () => _addFriends(context, ref, members),
            ),
          const Divider(),
          for (final m in members)
            ListTile(
              leading: ProfileAvatar(m.profile),
              title: Text(m.profile.id == me ? l10n.youSuffix(m.profile.label) : m.profile.label),
              subtitle: Text(
                [
                  if (m.profile.username != null) '@${m.profile.username}',
                  if (m.role == CircleRole.owner) l10n.owner,
                ].join(' · '),
              ),
              trailing: isOwner && m.role != CircleRole.owner
                  ? IconButton(
                      tooltip: l10n.remove,
                      icon: const Icon(Icons.person_remove_outlined),
                      onPressed: () => _remove(context, ref, m.profile),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}
