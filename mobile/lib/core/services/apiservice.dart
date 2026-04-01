import 'package:flutter/foundation.dart';

enum DioMethode { get, post, put, delete }

class AuthHolder {
  static String? token;
  static int? id;
}
class Apiservice {
  Apiservice._singleton();
  static final Apiservice _instance = Apiservice._singleton();
  String get baseur{
    if(kDebugMode){
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }
}
Future <Response> request(DioMethode methode, String url, {Map<String, dynamic>? data}) async {
  final dio = Dio();
  dio.options.headers['Authorization'] = 'Bearer ${AuthHolder.token}';
  switch (methode) {
    case DioMethode.get:
      return await dio.get(url);
    case DioMethode.post:
      return await dio.post(url, data: data);
    case DioMethode.put:
      return await dio.put(url, data: data);
    case DioMethode.delete:
      return await dio.delete(url);
  }
}