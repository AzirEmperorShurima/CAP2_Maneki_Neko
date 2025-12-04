import 'package:dio/dio.dart';

import '../infrastructure/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService storageService;
  AuthInterceptor(this.storageService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storageService.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}


