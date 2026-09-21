import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_models.dart';

enum AuthStatus {
  /// Sessiya hali tekshirilmagan (splash).
  unknown,

  /// Token yo'q — telefon raqami so'raladi.
  unauthenticated,

  /// Token bor, lekin ism/do'kon kiritilmagan.
  needsProfile,

  /// Token bor, PIN hali yaratilmagan.
  needsPin,

  /// Token bor, PIN mavjud — kirish uchun PIN so'raladi.
  locked,

  /// To'liq kirilgan.
  authenticated,
}

@immutable
class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isBusy = false,
    this.error,
  });

  final AuthStatus status;
  final AuthUser? user;
  final bool isBusy;
  final ApiException? error;

  bool get isSignedIn => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    bool? isBusy,
    ApiException? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
