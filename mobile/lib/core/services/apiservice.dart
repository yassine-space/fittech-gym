import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/models/signup_model.dart';

enum DioMethode { get, post, put, delete }

class AuthHolder {
  static String? token;
  static int? id;
}

class Apiservice {
  Apiservice._singleton();
  static final Apiservice _instance = Apiservice._singleton();
  static Apiservice get instance => _instance;

  // Replace baseUrl in your Apiservice class temporarily
    String get baseUrl {
      return 'https://webhook.site/0205c189-5530-4df7-9c8f-deedf13e9c03';
    }

  final Dio _dio = Dio();

  Future<Response> request(
    DioMethode methode,
    String url, {
    dynamic data,
    Options? options,
  }) async {
    final fullUrl = '$baseUrl$url';

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

  // ── Register (multipart/form-data) ─────────────────────────────────────────
  // Sends all signup fields + optional cropped avatar as a single
  // multipart request. Only the cropped circle image is uploaded —
  // the original picked file is never sent.

  Future<Response> register(SignupData data) async {

    final formData = FormData.fromMap({
      'first_name':   data.first_name,
      'last_name':      data.last_name,
      'email':    data.email,
      'phone':    data.phone,
      'password': data.password,
      'role':     data.role!.name, // 'member' or 'coach'

      if (data.role == UserRole.member)
        ...Map.fromEntries(
          data.goals.asMap().entries.map(
            (e) => MapEntry('goals', e.value),
          ),
        ),
      if (data.role == UserRole.coach)
        ...Map.fromEntries(
          data.specialties.asMap().entries.map(
            (e) => MapEntry('specialties', e.value),
          ),
        ),

      // Cropped circle avatar — only included when the user picked a photo.
      if (data.croppedImagePath != null)
        'avatar': await MultipartFile.fromFile(
          data.croppedImagePath!,
          filename: 'avatar.png',
        ),
    });

    return await request(
      DioMethode.post,
      '/auth/register/',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<Response> login(String email, String password) async {
    return await request(
      DioMethode.post,
      '/auth/login/',
      data: {
        'email':    email,
        'password': password,
      },
    );
  }
}