import 'package:finance_management_app/core/di/injector.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> setupDI() async {
  if (kDebugMode) {
    print('🔧 [DI] Setting up dependencies...');
  }

  // Initialize Injectable (auto-generate DI code)
  getIt.init();

  if (kDebugMode) {
    print('✅ [DI] Dependencies registered');
  }
}