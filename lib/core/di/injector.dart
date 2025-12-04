import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:finance_management_app/core/config/dio_config.dart';
import 'package:finance_management_app/core/infrastructure/secure_storage_service.dart';
import 'package:finance_management_app/features/data/remote/api_client.dart';
import 'package:finance_management_app/features/domain/repository/auth_repository.dart';
import 'package:finance_management_app/features/data/repository/auth_repository_impl.dart';
import 'package:finance_management_app/features/presentation/blocs/auth/auth_bloc.dart';
import 'package:finance_management_app/features/presentation/blocs/login/login_bloc.dart';
import 'package:finance_management_app/features/presentation/blocs/sign_up/signup_bloc.dart';
import 'package:finance_management_app/features/presentation/blocs/onboarding/onboarding_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../features/domain/services/auth_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDI() async {
  if (kDebugMode) {
    print('🔧 [DI] Setting up dependencies...');
  }
  // Core services
  getIt.registerLazySingleton<SecureStorageService>(() => SecureStorageService());

  // Network
  getIt.registerLazySingleton<Dio>(() => DioConfig.createDio(getIt<SecureStorageService>()));
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(getIt<Dio>()));

  // Auth stack
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt<ApiClient>()));
  getIt.registerLazySingleton<AuthService>(() => AuthService(getIt<AuthRepository>(), getIt<SecureStorageService>()));
  getIt.registerFactory<AuthBloc>(() => AuthBloc(getIt<AuthService>()));
  getIt.registerFactory<LoginBloc>(() => LoginBloc(getIt<AuthService>()));
  getIt.registerFactory<SignupBloc>(() => SignupBloc(getIt<AuthService>()));
  
  // Onboarding
  getIt.registerFactory<OnboardingBloc>(() => OnboardingBloc());

  if (kDebugMode) {
    print('✅ [DI] Dependencies registered');
  }
}


