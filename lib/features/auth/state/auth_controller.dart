import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

/// Ro'yxatdan o'tish / kirish oqimini boshqaradi (TZ 4 va 37-bo'limlar).
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  /// Splash'da chaqiriladi: token bo'lsa `/auth/me` orqali holat aniqlanadi.
  Future<void> restore() async {
    final bool hasToken = await _repository.restoreToken();
    if (!hasToken) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final AuthUser user = await _repository.me();
      state = AuthState(status: _statusFor(user), user: user);
    } on ApiException catch (error) {
      if (error.isUnauthenticated) {
        await _repository.clearSession();
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      // Tarmoq xatosi: tokenni o'chirmaymiz, foydalanuvchi qayta urinadi.
      state = AuthState(status: AuthStatus.unauthenticated, error: error);
    }
  }

  Future<OtpSendResult?> sendOtp({
    required String phone,
    OtpPurpose purpose = OtpPurpose.login,
  }) {
    return _guard<OtpSendResult>(
      () => _repository.sendOtp(phone: phone, purpose: purpose),
    );
  }

  Future<bool> verifyOtp({
    required String phone,
    required String code,
    OtpPurpose purpose = OtpPurpose.login,
  }) async {
    final OtpVerifyResult? result = await _guard<OtpVerifyResult>(
      () => _repository.verifyOtp(
        phone: phone,
        code: code,
        purpose: purpose,
        deviceName: 'mobile',
      ),
    );
    if (result == null) {
      return false;
    }

    state = state.copyWith(
      user: result.user,
      status: _statusFor(result.user),
      clearError: true,
    );
    return true;
  }

  Future<bool> saveProfile({
    required String name,
    String? shopName,
    String? businessType,
    String? locale,
  }) async {
    final AuthUser? user = await _guard<AuthUser>(
      () => _repository.updateProfile(
        name: name,
        shopName: shopName,
        businessType: businessType,
        locale: locale,
      ),
    );
    if (user == null) {
      return false;
    }

    state = state.copyWith(
      user: user,
      status: user.hasPin ? AuthStatus.authenticated : AuthStatus.needsPin,
      clearError: true,
    );
    return true;
  }

  Future<bool> setPin(String pin, {String? currentPin}) async {
    final bool? done = await _guard<bool>(() async {
      await _repository.setPin(pin: pin, currentPin: currentPin);
      return true;
    });
    if (done != true) {
      return false;
    }

    state = state.copyWith(
      user: state.user?.copyWith(hasPin: true),
      status: AuthStatus.authenticated,
      clearError: true,
    );
    return true;
  }

  Future<bool> verifyPin(String pin) async {
    final bool? done = await _guard<bool>(() async {
      await _repository.verifyPin(pin);
      return true;
    });
    if (done != true) {
      return false;
    }

    state = state.copyWith(status: AuthStatus.authenticated, clearError: true);
    return true;
  }

  /// Sessiyani bloklash — ilova fonga o'tganda PIN qayta so'raladi (TZ 23).
  void lock() {
    if (state.user != null && state.user!.hasPin) {
      state = state.copyWith(status: AuthStatus.locked, clearError: true);
    }
  }

  /// Istalgan so'rovda 401 kelganda chaqiriladi — sessiya lokal tozalanadi
  /// va foydalanuvchi login oqimiga qaytariladi.
  Future<void> sessionExpired() async {
    if (state.status == AuthStatus.unauthenticated) {
      return;
    }
    await _repository.clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> logout({bool allDevices = false}) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repository.logout(allDevices: allDevices);
    } on ApiException catch (_) {
      // Token lokal tozalangan — chiqishni baribir yakunlaymiz.
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }

  AuthStatus _statusFor(AuthUser user) {
    if (!user.isProfileComplete) {
      return AuthStatus.needsProfile;
    }
    if (!user.hasPin) {
      return AuthStatus.needsPin;
    }
    return AuthStatus.locked;
  }

  /// So'rovni `isBusy` va xatolik holati bilan o'raydi.
  Future<T?> _guard<T>(Future<T> Function() action) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final T result = await action();
      state = state.copyWith(isBusy: false);
      return result;
    } on ApiException catch (error) {
      state = state.copyWith(isBusy: false, error: error);
      return null;
    }
  }
}
