import 'package:finance_management_app/core/network/api_result.dart';
import 'package:finance_management_app/features/domain/entities/auth_model.dart';
import 'package:finance_management_app/features/domain/entities/user_model.dart';

abstract class AuthRepository {
  Future<ApiResult<AuthModel>> login({
    required String email,
    required String password,
  });

  Future<ApiResult<AuthModel>> loginWithGoogle();

  Future<ApiResult<AuthModel>> register({
    required String email,
    required String password,
  });

  Future<ApiResult<UserModel>> getMyProfile();

  Future<ApiResult<bool>> logout();
}
