import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _keyAccessToken = 'access_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  Future<String?> readAccessToken() async {
    return _storage.read(key: _keyAccessToken);
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}