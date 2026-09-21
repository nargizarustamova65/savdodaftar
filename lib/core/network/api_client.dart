import 'dart:async';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'package:flutter/foundation.dart';
/// savdodaftar-backend (`/api/v1`) bilan ishlash uchun yagona HTTP klient.
///
/// Vazifalari:
/// - `Authorization: Bearer <token>` va `Accept-Language` sarlavhalarini qo'shish;
/// - `{ success, message, data }` konvertini ochish;
/// - barcha xatoliklarni [ApiException] ga aylantirish.
class ApiClient {
  ApiClient({Dio? dio, String languageCode = 'uz'})
      : _languageCode = languageCode,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: AppConfig.connectTimeout,
                receiveTimeout: AppConfig.receiveTimeout,
                contentType: Headers.jsonContentType,
                responseType: ResponseType.json,
                // 4xx/5xx ni ham o'zimiz ishlaymiz — backend konvertida
                // foydalanuvchiga ko'rsatiladigan `message` keladi.
                validateStatus: (int? status) => status != null && status < 600,
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          options.headers['Accept'] = Headers.jsonContentType;
          options.headers['Accept-Language'] = _languageCode;
          final String? token = _authToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  String _languageCode;
  String? _authToken;

  /// 401 (token bekor bo'lgan) javob kelganda chaqiriladi —
  /// auth qatlami sessiyani tozalab, login oqimiga qaytaradi.
  void Function()? onUnauthenticated;

  /// Sozlamalardan til almashtirilganda chaqiriladi.
  void setLanguage(String languageCode) => _languageCode = languageCode;

  void setToken(String? token) => _authToken = token;

  bool get hasToken => _authToken != null && _authToken!.isNotEmpty;

  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? query,
  }) {
    return _send(() => _dio.get<dynamic>(path, queryParameters: query));
  }

  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _send(() => _dio.post<dynamic>(path, data: body));
  }

  Future<ApiResponse> put(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _send(() => _dio.put<dynamic>(path, data: body));
  }

  Future<ApiResponse> delete(String path) {
    return _send(() => _dio.delete<dynamic>(path));
  }

  Future<ApiResponse> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    final Response<dynamic> response;
    try {
      response = await request();
    } on DioException catch (error) {
      throw _mapDioException(error);
    }

    debugPrint('========== API RESPONSE ==========');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('TYPE: ${response.data.runtimeType}');
    debugPrint('DATA: ${response.data}');
    debugPrint('HEADERS: ${response.headers}');
    final dynamic payload = response.data;
    if (payload is! Map) {
      throw ApiException(
        message: 'Server javobi tushunarsiz.',
        code: 'invalid_response',
        statusCode: response.statusCode,
      );
    }

    final ApiResponse parsed =
        ApiResponse.fromJson(payload.cast<String, dynamic>());

    if (!parsed.success) {
      final Map<String, dynamic> json = payload.cast<String, dynamic>();
      final dynamic meta = json['meta'];
      final ApiException exception = ApiException(
        message: parsed.message,
        code: json['code']?.toString(),
        statusCode: response.statusCode,
        meta: meta is Map ? meta.cast<String, dynamic>() : <String, dynamic>{},
      );
      // Token bekor bo'lgan — sessiya tugashini global qayta ishlash.
      if (exception.isUnauthenticated) {
        onUnauthenticated?.call();
      }
      throw exception;
    }

    return parsed;
  }

  ApiException _mapDioException(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        ApiException.network(error.message ?? 'connection_error'),
      DioExceptionType.cancel => const ApiException(
          message: 'So\u2019rov bekor qilindi.',
          code: 'cancelled',
        ),
      _ => ApiException(
          message: error.message ?? 'unknown_error',
          code: 'unknown_error',
          statusCode: error.response?.statusCode,
        ),
    };
  }
}
