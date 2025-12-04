import 'package:finance_management_app/core/infrastructure/secure_storage_service.dart';
import 'package:finance_management_app/features/domain/repository/auth_repository.dart';

class AuthService {
  final AuthRepository repository;
  final SecureStorageService storage;
  AuthService(this.repository, this.storage);

  Future<void> login(String email, String password) async {
    final token = await repository.login(email: email, password: password);
    await storage.saveAccessToken(token);
  }

  Future<void> register(String name, String email, String password) async {
    final token =
        await repository.register(name: name, email: email, password: password);
    await storage.saveAccessToken(token);
  }

  Future<bool> isLoggedIn() async => (await storage.readAccessToken()) != null;
  Future<void> logout() async => storage.clear();
}
