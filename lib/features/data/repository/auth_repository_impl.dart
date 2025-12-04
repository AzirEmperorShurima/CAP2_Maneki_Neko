import 'package:finance_management_app/features/domain/repository/auth_repository.dart';
import 'package:finance_management_app/features/data/remote/api_client.dart';
import 'package:finance_management_app/core/exceptions/api_exceptions.dart';
import 'package:dio/dio.dart';

import '../requests/login_request.dart';
import '../requests/register_request.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient authApi;
  AuthRepositoryImpl(this.authApi);

  @override
  Future<String> login({required String email, required String password}) async {
    try {
      final request = LoginRequest(email: email, password: password);
      final response = await authApi.login(request);
      return response.accessToken;
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message'] as String?)
          : null;
      throw ApiException(message ?? 'Login failed');
    }
  }

  @override
  Future<String> register({required String name, required String email, required String password}) async {
    try {
      final request = RegisterRequest(name: name, email: email, password: password);
      final response = await authApi.register(request);
      return response.accessToken;
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message'] as String?)
          : null;
      throw ApiException(message ?? 'Register failed');
    }
  }
}


