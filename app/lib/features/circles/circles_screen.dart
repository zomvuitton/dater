import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models.dart';
import '../../core/supabase.dart';
import '../../core/ui.dart';
import '../../l10n/app_localizations.dart';
import 'circle_form_sheet.dart';
import 'circles_repository.dart';

class CirclesScreen extends ConsumerWidget {
  const CirclesScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await showCircleForm(context);
    if (result == null) return;
    try {
      final circle = await ref
          .read(circlesRepositoryProvider)
          .create(name: result.name, emoji: result.emoji, colorHex: result.colorHex);
      ref.invalidate(myCirclesProvider);
      if (context.mounted) context.go('/circles/${circle.id}');
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final circlesAsync = ref.watch(myCirclesProvider);
    final me = ref.watch(currentUserIdProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navCircles),
        actions: [
          IconButton(
            tooltip: l10n.joinWithCode,
            icon: const Icon(Icons.vpn_key_outlined),
            onPressed: () => showJoinWithCodeDialog(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.newCircle),
      ),
      body: circlesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myCirclesProvider)),
        data: (circles) => circles.isEmpty
            ? EmptyState(icon: Icons.groups_outlined, title: l10n.circlesEmptyTitle, body: l10n.circlesEmptyBody)
            : RefreshIndicator(
                onRefresh: () => ref.refresh(myCirclesProvider.future),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: circles.length,
                  itemBuilder: (context, i) => _CircleTile(circle: circles[i], isOwner: circles[i].ownerId == me),
                ),
              ),
      ),
    );
  }
}

class _CircleTile extends StatelessWidget {
  const _CircleTile({required this.circle, required this.isOwner});

  final Circle circle;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: circle.color.withValues(alpha: 0.2),
        child: Text(circle.emoji, style: const TextStyle(fontSize: 20)),
      ),
      title: Text(circle.name),
      subtitle: Text([l10n.memberCount(circle.memberCount ?? 0), if (isOwner) l10n.youOwn].join(' · ')),
      trailing: Icon(Icons.circle, size: 12, color: circle.color),
      onTap: () => context.go('/circles/${circle.id}'),
    );
  }
}

Future<void> showJoinWithCodeDialog(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();
  final code = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.joinWithCode),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(labelText: l10n.inviteCode, hintText: 'ABCD2345'),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l10n.join)),
      ],
    ),
  );
  controller.dispose();
  if (code == null || code.trim().isEmpty || !context.mounted) return;
  // Accept a pasted link as well as a bare code.
  final bare = code.trim().split('/').last;
  context.go('/join/${Uri.encodeComponent(bare)}');
}
