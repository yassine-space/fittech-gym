import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/models/signup_model.dart';

enum DioMethode { get, post, put, delete }

class AuthHolder {
  static String? token;
  static String? id;
}

class Apiservice {
  Apiservice._singleton();
  static final Apiservice _instance = Apiservice._singleton();
  static Apiservice get instance => _instance;

  // apiservice.dart
String get baseUrl {
  if (kIsWeb) return 'http://localhost:8000';
  
  // Your correct IP address from hostname -I
  return 'http://192.168.171.14:8000';
}

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

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
    }
  }

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