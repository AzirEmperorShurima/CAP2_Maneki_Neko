import 'package:finance_management_app/app/app.dart';
import 'package:finance_management_app/core/di/injector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup Dependency Injection
  await setupDI();
  
  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);
  
  // Setup BlocObserver for debugging
  // Bloc.observer = AppBlocObserver();
  
  runApp(const App());
}
