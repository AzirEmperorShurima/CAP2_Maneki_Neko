import 'package:finance_management_app/core/common/bases/base_repository.dart';
import 'package:finance_management_app/core/infrastructure/secure_storage_service.dart';
import 'package:finance_management_app/core/network/api_result.dart';
import 'package:finance_management_app/features/data/remote/api_client.dart';
import 'package:finance_management_app/features/data/response/auth_response.dart';
import 'package:finance_management_app/features/data/response/user_response.dart';
import 'package:finance_management_app/features/domain/entities/auth_model.dart';
import 'package:finance_management_app/features/domain/entities/user_model.dart';
import 'package:finance_management_app/features/domain/repository/auth_repository.dart';
import 'package:finance_management_app/features/domain/translator/auth_translator.dart';
import 'package:finance_management_app/features/domain/translator/user_translator.dart';
import 'package:finance_management_app/utils/device/device_utility.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

import '../requests/google_login_request.dart';
import '../requests/login_request.dart';
import '../requests/register_request.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  final ApiClient apiClient;
  final SecureStorageService storageService;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: TDeviceUtils.isIOS()
        ? '929712008956-94ccbr2qbnp5sqjsoni2ubvmnssj43t0.apps.googleusercontent.com'
        : null,

    serverClientId:
        '929712008956-69cppp7mnptvj1p3p6u7k12kae62c6ca.apps.googleusercontent.com',

    scopes: ['email'],
  );

  AuthRepositoryImpl(this.apiClient, this.storageService);

  @override
  Future<ApiResult<AuthModel>> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequest(email: email, password: password);

    return handleApiResponse<AuthModel>(
      () async {
        final response = await apiClient.login(request);

        final authResponse =
            response.getBody(AuthResponse.fromJson)?.toAuthModel();
        if (authResponse == null) {
          throw Exception('Login failed: No data in response');
        }

        if (authResponse.accessToken != null) {
          await storageService.saveAccessToken(authResponse.accessToken!);
        }

        return authResponse;
      },
    );
  }

  @override
  Future<ApiResult<AuthModel>> loginWithGoogle() async {
    return handleApiResponse<AuthModel>(
      () async {
        await _googleSignIn.signOut();

        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          throw Exception('Google sign in was cancelled');
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        if (googleAuth.idToken == null) {
          throw Exception('Failed to get id token from Google');
        }

        final request = GoogleLoginRequest(idToken: googleAuth.idToken);
        final response = await apiClient.loginWithGoogle(request);

        final authResponse =
            response.getBody(AuthResponse.fromJson)?.toAuthModel();

        if (authResponse == null) {
          throw Exception('Login with Google failed: No data in response');
        }

        if (authResponse.accessToken != null) {
          await storageService.saveAccessToken(authResponse.accessToken!);
        }

        return authResponse;
      },
    );
  }

  @override
  Future<ApiResult<AuthModel>> register({
    required String email,
    required String password,
  }) async {
    final request = RegisterRequest(
      email: email,
      password: password,
    );

    return handleApiResponse<AuthModel>(
      () async {
        final response = await apiClient.register(request);

        final authResponse =
            response.getBody(AuthResponse.fromJson)?.toAuthModel();
        if (authResponse == null) {
          throw Exception('Register failed: No data in response');
        }

        if (authResponse.accessToken != null) {
          await storageService.saveAccessToken(authResponse.accessToken!);
        }

        return authResponse;
      },
    );
  }

  @override
  Future<ApiResult<UserModel>> getMyProfile() async {
    return handleApiResponse<UserModel>(
      () async {
        final response = await apiClient.getMyProfile();

        final userResponse =
            response.getBody(UserResponse.fromJson)?.toUserModel();
        if (userResponse == null) {
          throw Exception('Get my profile failed: No data in response');
        }

        await storageService.saveUserData(userResponse);

        return userResponse;
      },
    );
  }

  @override
  Future<ApiResult<bool>> logout() async {
    return handleApiResponse<bool>(
      () async {
        final response = await apiClient.logout();

        await storageService.clear();

        return response;
      },
    );
  }
}
