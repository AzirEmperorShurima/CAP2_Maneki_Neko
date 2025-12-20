import 'package:auto_route/auto_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../routes/router.gr.dart';

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

  static Future<void> setIsLoggedIn(bool isLoggedIn) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', isLoggedIn);
  }

  static Future<bool> getIsLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    return isLoggedIn;
  }

  static Future<void> screenRedirect(context) async {
    var isFirstTime = await getIsFirstTime();
    var isLoggedIn = await getIsLoggedIn();

    if (isFirstTime) {
      AutoRouter.of(context).replace(OnboardingScreenRoute());
    } else if (isLoggedIn) {
      AutoRouter.of(context).replace(NavigationMenuRoute());
    } else {
      AutoRouter.of(context).replace(LoginScreenRoute());
    }
  }

  /// Lưu trạng thái ẩn số tiền
  static Future<void> setAmountHidden(bool isHidden) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('amountHidden', isHidden);
  }

  /// Lấy trạng thái ẩn số tiền
  static Future<bool> getAmountHidden() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('amountHidden') ?? false;
  }

  /// Lưu trạng thái đã hiển thị dialog hướng dẫn tạo ví
  static Future<void> setHasShownWalletDialog(bool hasShown) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasShownWalletDialog', hasShown);
  }

  /// Lấy trạng thái đã hiển thị dialog hướng dẫn tạo ví
  static Future<bool> getHasShownWalletDialog() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasShownWalletDialog') ?? false;
  }
}
