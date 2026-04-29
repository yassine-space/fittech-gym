import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/models/signup_model.dart';

enum DioMethode { get, post, put, delete, patch }

class AuthHolder {
  static String? token;
  static String? refreshToken;
  static String? id;
  static String? role;
  static String? coachProfileId;
}

class Apiservice {
   Apiservice._singleton();
  static final Apiservice _instance = Apiservice._singleton();
  static Apiservice get instance => _instance;

  String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';  // Changed from 127.0.0.1
    return 'http://192.168.171.14:8000';
  }

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // ─── Token Management ───────────────────────────────────────────────────

  /// Restore auth state from SharedPreferences on app startup.
  Future<void> initToken() async {
    final prefs = await SharedPreferences.getInstance();
    AuthHolder.token = prefs.getString('access_token');
    AuthHolder.refreshToken = prefs.getString('refresh_token');
    AuthHolder.id = prefs.getString('user_id');
    AuthHolder.role = prefs.getString('user_role');
    AuthHolder.coachProfileId = prefs.getString('coach_profile_id');
    debugPrint('>>> [Auth] Token restored: ${AuthHolder.token != null}');
  }

  /// Persist auth data after login/register.
  Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String userRole,
    String? coachProfileId,
  }) async {
    AuthHolder.token = accessToken;
    AuthHolder.refreshToken = refreshToken;
    AuthHolder.id = userId;
    AuthHolder.role = userRole;
    AuthHolder.coachProfileId = coachProfileId;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setString('user_id', userId);
    await prefs.setString('user_role', userRole);
    if (coachProfileId != null) {
      await prefs.setString('coach_profile_id', coachProfileId);
    }
  }

  /// Clear all auth data (logout).
  Future<void> clearAuthData() async {
    AuthHolder.token = null;
    AuthHolder.refreshToken = null;
    AuthHolder.id = null;
    AuthHolder.role = null;
    AuthHolder.coachProfileId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('coach_profile_id');
  }

  // ─── Core Request ───────────────────────────────────────────────────────

  Future<Response> request(
    DioMethode methode,
    String url, {
    dynamic data,
    Options? options,
  }) async {
    final fullUrl = '$baseUrl$url';
    debugPrint('>>> [API] ${methode.name.toUpperCase()} $fullUrl');

    if (AuthHolder.token != null) {
      _dio.options.headers['Authorization'] = 'Bearer ${AuthHolder.token}';
    }

    switch (methode) {
      case DioMethode.get:
        return await _dio.get(fullUrl);
      case DioMethode.post:
        return await _dio.post(fullUrl, data: data, options: options);
      case DioMethode.put:
        return await _dio.put(fullUrl, data: data, options: options);
      case DioMethode.delete:
        return await _dio.delete(fullUrl);
      case DioMethode.patch:
        return await _dio.patch(fullUrl, data: data, options: options);
    }
  }

  // ─── Auth Endpoints ─────────────────────────────────────────────────────

  Future<Response> register(SignupData data) async {
    final String roleStr = data.role == UserRole.member ? 'membre' : 'coach';

    final Map<String, dynamic> fields = {
      'first_name': data.first_name,
      'last_name':  data.last_name,
      'email':      data.email,
      'phone':      data.phone,
      'password':   data.password,
      'password2':  data.password,
      'role':       roleStr,
    };

    if (data.role == UserRole.member && data.goals.isNotEmpty) {
      fields['health_goal'] = data.goals.join(', ');
    }

    if (data.role == UserRole.coach && data.specialties.isNotEmpty) {
      fields['specialties'] = data.specialties.join(', ');
    }

    if (data.croppedImagePath != null) {
      fields['profile_photo'] = await MultipartFile.fromFile(
        data.croppedImagePath!,
        filename: 'profile_photo.png',
      );
    }

    final formData = FormData.fromMap(fields);
    return await request(
      DioMethode.post,
      '/auth/register/',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<Response> login(String email, String password) async {
    return await request(
      DioMethode.post,
      '/auth/login/',
      data: {'email': email, 'password': password},
    );
  }
}