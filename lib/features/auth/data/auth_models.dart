import 'package:flutter/foundation.dart';

/// OTP so'rovining maqsadi — backend `purpose` parametri.
enum OtpPurpose { login, resetPin }

extension OtpPurposeApi on OtpPurpose {
  String get value => switch (this) {
        OtpPurpose.login => 'login',
        OtpPurpose.resetPin => 'reset_pin',
      };
}

@immutable
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.phone,
    this.shopName,
    this.businessType,
    this.locale,
    this.hasPin = false,
    bool? isProfileComplete,
  }) : _isProfileComplete = isProfileComplete;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final Object? profileComplete = json['is_profile_complete'];
    return AuthUser(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      shopName: json['shop_name']?.toString(),
      businessType: json['business_type']?.toString(),
      locale: json['locale']?.toString(),
      hasPin: json['has_pin'] == true,
      isProfileComplete: profileComplete is bool ? profileComplete : null,
    );
  }

  final int id;
  final String name;
  final String phone;
  final String? shopName;
  final String? businessType;
  final String? locale;
  final bool hasPin;
  final bool? _isProfileComplete;

  /// Backend `is_profile_complete` bergan bo'lsa — o'sha qiymat,
  /// aks holda ism kiritilganligi bo'yicha aniqlanadi.
  bool get isProfileComplete =>
      _isProfileComplete ?? name.trim().isNotEmpty;

  AuthUser copyWith({
    String? name,
    String? shopName,
    String? businessType,
    String? locale,
    bool? hasPin,
  }) {
    return AuthUser(
      id: id,
      name: name ?? this.name,
      phone: phone,
      shopName: shopName ?? this.shopName,
      businessType: businessType ?? this.businessType,
      locale: locale ?? this.locale,
      hasPin: hasPin ?? this.hasPin,
      isProfileComplete: _isProfileComplete,
    );
  }
}

/// `POST /auth/otp/send` javobi.
@immutable
class OtpSendResult {
  const OtpSendResult({
    required this.expiresIn,
    required this.resendAfter,
    this.debugCode,
  });

  factory OtpSendResult.fromJson(Map<String, dynamic> json, {int fallbackResend = 45}) {
    return OtpSendResult(
      expiresIn: int.tryParse(json['expires_in']?.toString() ?? '') ?? 120,
      resendAfter:
          int.tryParse(json['resend_after']?.toString() ?? '') ?? fallbackResend,
      debugCode: json['debug_code']?.toString(),
    );
  }

  /// Kod amal qilish muddati (soniya) — TZ 37.2: 60–120 s.
  final int expiresIn;

  /// Qayta yuborish tugmasi faollashadigan vaqt (soniya).
  final int resendAfter;

  /// Faqat dev muhitda (`OTP_DEBUG_CODE`) keladi.
  final String? debugCode;
}

/// `POST /auth/otp/verify` javobi.
@immutable
class OtpVerifyResult {
  const OtpVerifyResult({
    required this.token,
    required this.isNew,
    required this.user,
  });

  factory OtpVerifyResult.fromJson(Map<String, dynamic> json) {
    final dynamic user = json['user'];
    return OtpVerifyResult(
      token: json['token']?.toString() ?? '',
      isNew: json['is_new'] == true,
      user: AuthUser.fromJson(
        user is Map ? user.cast<String, dynamic>() : <String, dynamic>{},
      ),
    );
  }

  final String token;

  /// true — foydalanuvchi shu OTP bilan birinchi marta ro'yxatdan o'tdi.
  final bool isNew;

  final AuthUser user;
}

@immutable
class OtpArgs {
  const OtpArgs({
    required this.phone,
    required this.resendAfter,
    required this.expiresIn,
    required this.purpose,
  });

  final String phone;
  final int resendAfter;
  final int expiresIn;
  final OtpPurpose purpose;
}