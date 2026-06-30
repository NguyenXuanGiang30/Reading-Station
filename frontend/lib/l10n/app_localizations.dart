/// App Localization System
/// Simple Map-based localization with Vietnamese and English support.
///
/// Usage: S.of(context).t('key')
library;

import 'package:flutter/material.dart';

import 'vi.dart';
import 'en.dart';

class S {
  final Locale locale;

  S(this.locale);

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S) ?? S(const Locale('vi'));
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  static const List<Locale> supportedLocales = [
    Locale('vi'),
    Locale('en'),
  ];

  /// Translate a key to the current locale's string.
  /// Falls back to Vietnamese if key not found.
  String t(String key) {
    final strings = locale.languageCode == 'en' ? enStrings : viStrings;
    return strings[key] ?? viStrings[key] ?? key;
  }
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['vi', 'en'].contains(locale.languageCode);
  }

  @override
  Future<S> load(Locale locale) async {
    return S(locale);
  }

  @override
  bool shouldReload(_SDelegate old) => false;
}
