import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:finance_management_app/features/data/requests/login_request.dart';
import 'package:finance_management_app/features/data/requests/register_request.dart';
import 'package:finance_management_app/features/data/response/auth_response.dart';

part 'api_client.g.dart';

@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio, {String? baseUrl}) = _ApiClient;

  @POST('/api/auth/login')
  Future<AuthResponse> login(@Body() LoginRequest request);

  @POST('/api/auth/register')
  Future<AuthResponse> register(@Body() RegisterRequest request);
}
