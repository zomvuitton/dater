import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import 'models.dart';

/// A readable message for errors coming back from Supabase.
String errorMessage(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);
  if (error is AuthException) return error.message;
  if (error is PostgrestException) return error.message;
  if (error is StateError) return error.message;
  return l10n.errorGeneric;
}

void showError(BuildContext context, Object error) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(errorMessage(context, error))));
}

void showMessage(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirm(BuildContext context, {required String title, String? body, required String action}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
      ],
    ),
  );
  return result ?? false;
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar(this.profile, {super.key, this.radius = 20});

  final Profile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      child: Text(profile.initials, style: TextStyle(fontSize: radius * 0.8)),
    );
  }
}

/// Error placeholder with a retry button, for failed provider loads.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Text(errorMessage(context, error), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}

/// Centered icon + text for empty lists.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.body, this.action});

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(body!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

String localeName(BuildContext context) => Localizations.localeOf(context).toLanguageTag();

/// "9 – 15 Kas" / "Nov 9 – 15" style label for a week.
String formatWeekRange(BuildContext context, DateTime weekStart) =>
    formatDayRange(localeName(context), weekStart, DateTime(weekStart.year, weekStart.month, weekStart.day + 6));

/// A compact day range that follows the locale's day/month order and only
/// repeats the month when it changes.
String formatDayRange(String locale, DateTime start, DateTime end) {
  final monthDay = DateFormat.MMMd(locale);
  if (start.month != end.month || start.year != end.year) {
    return '${monthDay.format(start)} – ${monthDay.format(end)}';
  }
  final day = DateFormat.d(locale);
  final dayFirst = (monthDay.pattern ?? '').trimLeft().startsWith('d');
  return dayFirst ? '${day.format(start)} – ${monthDay.format(end)}' : '${monthDay.format(start)} – ${day.format(end)}';
}

String formatHour(BuildContext context, int hour) =>
    DateFormat.Hm(localeName(context)).format(DateTime(2000, 1, 1, hour));

/// "Tue 11 Nov, 19:00–21:00"
String formatTimeRange(BuildContext context, DateTime start, DateTime end) {
  final locale = localeName(context);
  final day = DateFormat.MMMEd(locale).format(start);
  final sameDay = start.year == end.year && start.month == end.month && start.day == end.day;
  final endText = sameDay ? DateFormat.Hm(locale).format(end) : DateFormat('E HH:mm', locale).format(end);
  return '$day, ${DateFormat.Hm(locale).format(start)}–$endText';
}
