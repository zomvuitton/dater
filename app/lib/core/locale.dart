import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const supportedLocales = [Locale('tr'), Locale('en')];

/// The language picked in the profile screen; null follows the device.
class LocaleController extends Notifier<Locale?> {
  static const _key = 'locale';

  @override
  Locale? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    try {
      final code = (await SharedPreferences.getInstance()).getString(_key);
      if (code != null) state = Locale(code);
    } catch (_) {
      // Preferences unavailable: keep following the device language.
    }
  }

  Future<void> set(Locale? locale) async {
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(_key);
      } else {
        await prefs.setString(_key, locale.languageCode);
      }
    } catch (_) {}
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(LocaleController.new);
