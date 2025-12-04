import 'package:flutter/material.dart';
import 'package:finance_management_app/app/app.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finance_management_app/app/bloc_observer.dart';
import 'package:finance_management_app/core/di/injector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();
  await setupDI();
  runApp(const App());
}
