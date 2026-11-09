import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models.dart';
import '../../core/supabase.dart';
import '../../core/ui.dart';
import '../../l10n/app_localizations.dart';

/// Shows the circle's invite code and lets the user share the link.
Future<void> showInviteSheet(BuildContext context, Circle circle) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final theme = Theme.of(context);
      final link = inviteLink(circle.inviteCode);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.inviteTitle(circle.name), style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(l10n.inviteBody),
              const SizedBox(height: 24),
              SelectableText(
                circle.inviteCode,
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(letterSpacing: 6, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: Text(l10n.copyCode),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: circle.inviteCode));
                        if (context.mounted) showMessage(context, l10n.copied);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.share),
                      label: Text(l10n.shareLink),
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(text: l10n.inviteShareText(circle.name, link, circle.inviteCode)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
