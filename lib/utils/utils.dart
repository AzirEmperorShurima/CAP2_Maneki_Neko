import 'package:shared_preferences/shared_preferences.dart';

class Utils {
  static Future<void> setIsFirstTime(bool isFirstTime) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isFirstTime', isFirstTime);
  }

  static Future<bool> getIsFirstTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;
    return isFirstTime;
  }

  static Future<void> clearAllSavedData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    await prefs.clear();

    await prefs.setBool('isFirstTime', isFirstTime);
  }

  static Future<void> setFCMTokenRegistered(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  static Future<String?> getRegisteredFCMToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  static Future<void> clearFCMToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_token');
  }
}
