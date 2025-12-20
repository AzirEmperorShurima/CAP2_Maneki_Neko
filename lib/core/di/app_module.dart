import 'package:dio/dio.dart';
import 'package:finance_management_app/core/config/dio_config.dart';
import 'package:finance_management_app/core/infrastructure/secure_storage_service.dart';
import 'package:finance_management_app/features/data/remote/api_client.dart';
import 'package:injectable/injectable.dart';

@module
abstract class AppModule {
  @lazySingleton
  Dio provideDio(SecureStorageService storage) {
    return DioConfig.createDio(storage);
  }

  @lazySingleton
  ApiClient provideApiClient(Dio dio) {
    return ApiClient(dio);
  }
}

