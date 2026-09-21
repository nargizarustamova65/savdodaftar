import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/utils/phone.dart';
import 'auth_models.dart';
import 'package:flutter/foundation.dart';

/// `/api/v1/auth` endpointlari bilan ishlaydi (savdodaftar-backend).
class AuthRepository {
  const AuthRepository({
    required ApiClient client,
    required TokenStorage tokenStorage,
  })  : _client = client,
        _tokenStorage = tokenStorage;

  final ApiClient _client;
  final TokenStorage _tokenStorage;

  /// Saqlangan tokenni klientga tiklaydi. Token bo'lmasa `false`.
  Future<bool> restoreToken() async {
    final String? token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      return false;
    }
    _client.setToken(token);
    return true;
  }

  Future<OtpSendResult> sendOtp({
    required String phone,
    OtpPurpose purpose = OtpPurpose.login,
  }) async {
    try {
      final String formattedPhone = Phone.toE164(phone);

      debugPrint('========== OTP SEND ==========');
      debugPrint('PHONE: $formattedPhone');
      debugPrint('PURPOSE: ${purpose.value}');
      debugPrint('URL: /auth/otp/send');

      final ApiResponse response = await _client.post(
        '/auth/otp/send',
        body: <String, dynamic>{
          'phone': formattedPhone,
          'purpose': purpose.value,
        },
      );

      debugPrint('OTP RESPONSE: ${response.dataMap}');

      return OtpSendResult.fromJson(
        response.dataMap,
        fallbackResend: AppConfig.defaultOtpResendSeconds,
      );
    } catch (e, stack) {
      debugPrint('========== OTP ERROR ==========');
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stack');
      rethrow;
    }
  }
  Future<OtpVerifyResult> verifyOtp({
    required String phone,
    required String code,
    OtpPurpose purpose = OtpPurpose.login,
    String? deviceName,
  }) async {
    final ApiResponse response = await _client.post(
      '/auth/otp/verify',
      body: <String, dynamic>{
        'phone': Phone.toE164(phone),
        'code': code,
        'purpose': purpose.value,
        if (deviceName != null) 'device_name': deviceName,
      },
    );

    final OtpVerifyResult result = OtpVerifyResult.fromJson(response.dataMap);
    if (result.token.isNotEmpty) {
      _client.setToken(result.token);
      await _tokenStorage.writeToken(result.token);
    }
    return result;
  }

  Future<AuthUser> me() async {
    final ApiResponse response = await _client.get('/auth/me');
    return AuthUser.fromJson(_unwrapUser(response));
  }

  Future<AuthUser> updateProfile({
    required String name,
    String? shopName,
    String? businessType,
    String? locale,
  }) async {
    final ApiResponse response = await _client.put(
      '/auth/profile',
      body: <String, dynamic>{
        'name': name,
        if (shopName != null && shopName.isNotEmpty) 'shop_name': shopName,
        if (businessType != null && businessType.isNotEmpty)
          'business_type': businessType,
        if (locale != null) 'locale': locale,
      },
    );

    return AuthUser.fromJson(_unwrapUser(response));
  }

  /// PIN o'rnatish yoki almashtirish.
  /// Mavjud PIN bo'lsa [currentPin] yoki `reset_pin` OTP talab qilinadi.
  Future<void> setPin({required String pin, String? currentPin}) async {
    await _client.put(
      '/auth/pin',
      body: <String, dynamic>{
        'pin': pin,
        if (currentPin != null && currentPin.isNotEmpty) 'current_pin': currentPin,
      },
    );
  }

  Future<void> verifyPin(String pin) async {
    await _client.post('/auth/pin/verify', body: <String, dynamic>{'pin': pin});
  }

  Future<void> logout({bool allDevices = false}) async {
    try {
      await _client.post(allDevices ? '/auth/logout-all' : '/auth/logout');
    } finally {
      _client.setToken(null);
      await _tokenStorage.clearToken();
    }
  }

  /// Lokal sessiyani tozalash — 401 kelganda serverga so'rov yubormasdan.
  Future<void> clearSession() async {
    _client.setToken(null);
    await _tokenStorage.clearToken();
  }

  /// `/auth/me` va `/auth/profile` javoblari `{user: {...}}` yoki
  /// to'g'ridan-to'g'ri user obyekti bo'lishi mumkin — ikkisini ham qo'llaydi.
  Map<String, dynamic> _unwrapUser(ApiResponse response) {
    final Map<String, dynamic> data = response.dataMap;
    final dynamic nested = data['user'];
    if (nested is Map) {
      return nested.cast<String, dynamic>();
    }
    return data;
  }
}
