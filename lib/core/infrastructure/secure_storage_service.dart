import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finance_management_app/features/domain/entities/user_model.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SecureStorageService {
  static const _keyAccessToken = 'access_token';
  static const _keyUserData = 'user_data';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Token methods
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  Future<String?> readAccessToken() async {
    return _storage.read(key: _keyAccessToken);
  }

  // User data methods
  Future<void> saveUserData(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await _storage.write(key: _keyUserData, value: userJson);
  }

  Future<UserModel?> getUserData() async {
    final userJson = await _storage.read(key: _keyUserData);
    if (userJson != null && userJson.isNotEmpty) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return UserModel.fromJson(userMap);
      } catch (e) {
        // Nếu parse lỗi, xóa data cũ
        await _storage.delete(key: _keyUserData);
        return null;
      }
    }
    return null;
  }

  Future<void> clearUserData() async {
    await _storage.delete(key: _keyUserData);
  }

  // Clear all (token + user data)
  Future<void> clear() async {
    await _storage.deleteAll();
  }
}