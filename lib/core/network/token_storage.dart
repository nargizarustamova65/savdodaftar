import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Sanctum tokenini qurilmada xavfsiz saqlaydi (Keystore / Keychain).
class TokenStorage {
  const TokenStorage([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_token';
  static const String _onboardingKey = 'onboarding_seen';
  static const String _localeKey = 'locale';

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<bool> isOnboardingSeen() async {
    return await _storage.read(key: _onboardingKey) == 'true';
  }

  Future<void> markOnboardingSeen() =>
      _storage.write(key: _onboardingKey, value: 'true');

  Future<String?> readLocale() => _storage.read(key: _localeKey);

  Future<void> writeLocale(String code) =>
      _storage.write(key: _localeKey, value: code);
}
