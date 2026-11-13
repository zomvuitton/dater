import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/locale.dart';
import '../../core/session.dart';
import '../../core/supabase.dart';
import '../../core/ui.dart';
import '../../l10n/app_localizations.dart';
import '../notifications/notification_bell.dart';
import 'profile_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.displayName),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l10n.save)),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    try {
      await ref.read(profileRepositoryProvider).updateMine(displayName: name);
      await ref.read(appSessionProvider).refreshProfile();
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(appSessionProvider);
    final locale = ref.watch(localeProvider);
    final email = ref.read(supabaseProvider).auth.currentUser?.email;

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final profile = session.profile;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.navProfile), actions: const [NotificationBell()]),
          body: ListView(
            children: [
              if (profile != null) ...[
                const SizedBox(height: 24),
                Center(child: ProfileAvatar(profile, radius: 40)),
                const SizedBox(height: 12),
                Center(child: Text(profile.label, style: Theme.of(context).textTheme.titleLarge)),
                Center(child: Text('@${profile.username}')),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(l10n.displayName),
                  subtitle: Text(profile.displayName),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editName(context, ref, profile.displayName),
                ),
              ],
              if (email != null)
                ListTile(leading: const Icon(Icons.email_outlined), title: Text(l10n.email), subtitle: Text(email)),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.language),
                trailing: DropdownButton<String>(
                  value: locale?.languageCode ?? 'system',
                  underline: const SizedBox.shrink(),
                  onChanged: (v) => ref.read(localeProvider.notifier).set(v == 'system' ? null : Locale(v!)),
                  items: [
                    DropdownMenuItem(value: 'system', child: Text(l10n.languageSystem)),
                    const DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                    const DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                ),
              ),
              const Divider(),
              ListTile(leading: const Icon(Icons.logout), title: Text(l10n.signOut), onTap: () => signOut(ref)),
            ],
          ),
        );
      },
    );
  }
}
