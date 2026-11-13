import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/supabase.dart';
import '../../core/ui.dart';
import '../../l10n/app_localizations.dart';
import '../notifications/notification_bell.dart';
import '../profile/profile_repository.dart';
import 'friends_repository.dart';

/// Find people by @username, answer requests, manage friends.
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<Profile>? _results;
  bool _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _results = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _searching = true);
      try {
        final results = await ref.read(profileRepositoryProvider).searchByUsername(query);
        if (mounted && _search.text == query) setState(() => _results = results);
      } catch (e) {
        if (mounted) showError(context, e);
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  Future<void> _run(Future<void> Function() action, [String? doneMessage]) async {
    try {
      await action();
      ref.invalidate(friendshipsProvider);
      if (doneMessage != null && mounted) showMessage(context, doneMessage);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(currentUserIdProvider).value ?? '';
    final repo = ref.read(friendsRepositoryProvider);
    final friendshipsAsync = ref.watch(friendshipsProvider);
    final friendships = friendshipsAsync.value ?? const <Friendship>[];
    final byOther = {for (final f in friendships) f.other(me).id: f};

    final incoming = friendships.where((f) => f.isIncoming(me)).toList();
    final outgoing = friendships.where((f) => f.isOutgoing(me)).toList();
    final accepted = friendships.where((f) => f.status == FriendshipStatus.accepted).toList()
      ..sort((a, b) => a.other(me).label.toLowerCase().compareTo(b.other(me).label.toLowerCase()));

    Widget relationAction(Profile p) {
      final f = byOther[p.id];
      if (f == null) {
        return FilledButton.tonal(
          onPressed: () => _run(() => repo.sendRequest(p.username!), l10n.requestSent),
          child: Text(l10n.addFriend),
        );
      }
      if (f.isIncoming(me)) {
        return FilledButton(onPressed: () => _run(() => repo.accept(f.id)), child: Text(l10n.accept));
      }
      return Text(f.status == FriendshipStatus.accepted ? l10n.friendsLabel : l10n.requestPending);
    }

    final results = _results;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navFriends), actions: const [NotificationBell()]),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(friendshipsProvider.future),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _search,
                autocorrect: false,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.searchUsername,
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _search.clear();
                            _onQueryChanged('');
                          },
                        ),
                ),
                onChanged: _onQueryChanged,
              ),
            ),
            if (_searching) const LinearProgressIndicator(minHeight: 2),
            if (results != null) ...[
              if (results.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.noUsersFound, textAlign: TextAlign.center),
                ),
              for (final p in results)
                ListTile(
                  leading: ProfileAvatar(p),
                  title: Text(p.label),
                  subtitle: Text('@${p.username}'),
                  trailing: relationAction(p),
                ),
              const Divider(),
            ],
            if (friendshipsAsync.hasError)
              ErrorView(error: friendshipsAsync.error!, onRetry: () => ref.invalidate(friendshipsProvider))
            else if (friendshipsAsync.isLoading && friendships.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (incoming.isNotEmpty) ...[
                _SectionHeader(l10n.incomingRequests),
                for (final f in incoming)
                  ListTile(
                    leading: ProfileAvatar(f.requester),
                    title: Text(f.requester.label),
                    subtitle: Text('@${f.requester.username}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.decline,
                          icon: const Icon(Icons.close),
                          onPressed: () => _run(() => repo.remove(f.id)),
                        ),
                        FilledButton(onPressed: () => _run(() => repo.accept(f.id)), child: Text(l10n.accept)),
                      ],
                    ),
                  ),
              ],
              _SectionHeader(l10n.friendsCount(accepted.length)),
              if (accepted.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(l10n.friendsEmpty),
                ),
              for (final f in accepted)
                ListTile(
                  leading: ProfileAvatar(f.other(me)),
                  title: Text(f.other(me).label),
                  subtitle: Text('@${f.other(me).username}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (_) async {
                      final ok = await confirm(
                        context,
                        title: l10n.unfriendTitle(f.other(me).label),
                        body: l10n.unfriendBody,
                        action: l10n.unfriend,
                      );
                      if (ok) _run(() => repo.remove(f.id));
                    },
                    itemBuilder: (context) => [PopupMenuItem(value: 'remove', child: Text(l10n.unfriend))],
                  ),
                ),
              if (outgoing.isNotEmpty) ...[
                _SectionHeader(l10n.sentRequests),
                for (final f in outgoing)
                  ListTile(
                    leading: ProfileAvatar(f.addressee),
                    title: Text(f.addressee.label),
                    subtitle: Text('@${f.addressee.username}'),
                    trailing: TextButton(
                      onPressed: () => _run(() => repo.remove(f.id)),
                      child: Text(l10n.cancelRequest),
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}
