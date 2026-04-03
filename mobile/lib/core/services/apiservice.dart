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
  static Apiservice get instance => _instance; // ✅ expose instance

  String get baseUrl {
    if (kDebugMode) {
      return 'http://127.0.0.1:8000'; // ✅ Django default port is 8000 not 8080
    }
    return 'https://yourproductiondomain.com';
  }

  final Dio _dio = Dio();

  Future<Response> request(
    DioMethode methode,
    String url, {
    Map<String, dynamic>? data,
  }) async {
    final fullUrl = '$baseUrl$url'; // ✅ always use baseUrl

    // Only add token if it exists
    if (AuthHolder.token != null) {
      _dio.options.headers['Authorization'] = 'Bearer ${AuthHolder.token}';
    }

    switch (methode) {
      case DioMethode.get:
        return await _dio.get(fullUrl);
      case DioMethode.post:
        return await _dio.post(fullUrl, data: data);
      case DioMethode.put:
        return await _dio.put(fullUrl, data: data);
      case DioMethode.delete:
        return await _dio.delete(fullUrl);
    }
  }

  // ✅ Auth methods
  Future<Response> register(SignupData data) async {
    return await request(
      DioMethode.post,
      '/auth/register/',
      data: {
        'prenom':    data.prenom,
        'nom':       data.nom,
        'email':     data.email,
        'phone':     data.phone,
        'password':  data.password,
        'role':      data.role,
        'goals':     data.goals,
      },
    );
  }

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