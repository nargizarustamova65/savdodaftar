import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_strings.dart';
import '../features/auth/state/auth_providers.dart';

/// Ilova tilini boshqaradi (TZ: O'zbek / Rus tili).
///
/// Tanlangan til qurilmada saqlanadi va API klientga `Accept-Language`
/// sifatida uzatiladi — backend xabarlari ham shu tilda keladi.
class LocaleController extends StateNotifier<Locale> {
  LocaleController(this._ref) : super(const Locale('uz')) {
    _restore();
  }

  final Ref _ref;

  Future<void> _restore() async {
    final String? code = await _ref.read(tokenStorageProvider).readLocale();
    if (code != null && _isSupported(code)) {
      _apply(code);
    }
  }

  Future<void> setLocale(String code) async {
    if (!_isSupported(code)) {
      return;
    }
    _apply(code);
    await _ref.read(tokenStorageProvider).writeLocale(code);
  }

  bool _isSupported(String code) => AppStrings.supportedLocales
      .any((Locale it) => it.languageCode == code);

  void _apply(String code) {
    _ref.read(apiClientProvider).setLanguage(code);
    if (mounted) {
      state = Locale(code);
    }
  }
}

final StateNotifierProvider<LocaleController, Locale> localeControllerProvider =
    StateNotifierProvider<LocaleController, Locale>(LocaleController.new);
