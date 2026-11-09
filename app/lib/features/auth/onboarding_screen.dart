import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/supabase.dart';
import '../../core/ui.dart';
import '../../l10n/app_localizations.dart';
import '../profile/profile_repository.dart';

/// First run: pick a unique @username so friends can find you.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _username;
  late final TextEditingController _name;
  String? _takenError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(appSessionProvider).profile;
    _name = TextEditingController(text: profile?.displayName ?? '');
    _username = TextEditingController();
  }

  @override
  void dispose() {
    _username.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _takenError = null);
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).updateMine(username: _username.text, displayName: _name.text);
      await ref.read(appSessionProvider).refreshProfile();
    } on UsernameTakenException {
      setState(() => _takenError = l10n.usernameTaken);
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
    return Scaffold(
      appBar: AppBar(
        actions: [TextButton(onPressed: () => ref.read(supabaseProvider).auth.signOut(), child: Text(l10n.signOut))],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.onboardingTitle, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(l10n.onboardingBody),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(labelText: l10n.displayName),
                      validator: (v) => (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _username,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: l10n.username,
                        prefixText: '@',
                        helperText: l10n.usernameHelp,
                        errorText: _takenError,
                      ),
                      validator: (v) =>
                          usernamePattern.hasMatch((v ?? '').trim().toLowerCase()) ? null : l10n.usernameInvalid,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(onPressed: _busy ? null : _submit, child: Text(l10n.continueAction)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
