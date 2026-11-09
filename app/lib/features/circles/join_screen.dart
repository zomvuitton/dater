import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui.dart';
import '../../l10n/app_localizations.dart';
import 'circles_repository.dart';

/// Opened from an invite link (`dater://app/join/<code>`) or the code dialog.
class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key, required this.code});

  final String code;

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    _join();
  }

  Future<void> _join() async {
    setState(() => _error = null);
    try {
      final circleId = await ref.read(circlesRepositoryProvider).joinByCode(widget.code);
      invalidateCircles(ref);
      if (mounted) context.go('/circles/$circleId');
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.joinWithCode)),
      body: error == null
          ? const Center(child: CircularProgressIndicator())
          : EmptyState(
              icon: Icons.link_off,
              title: error is InvalidInviteCodeException ? l10n.inviteInvalid : errorMessage(context, error),
              action: FilledButton(onPressed: () => context.go('/circles'), child: Text(l10n.backToCircles)),
            ),
    );
  }
}
