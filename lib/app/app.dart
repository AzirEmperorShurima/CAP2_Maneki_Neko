import 'package:finance_management_app/app/theme/theme.dart';
import 'package:finance_management_app/features/presentation/blocs/onboarding/onboarding_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finance_management_app/core/di/injector.dart';
import 'package:finance_management_app/features/presentation/blocs/auth/auth_bloc.dart';
import 'package:finance_management_app/features/presentation/blocs/auth/auth_event.dart';
import 'package:finance_management_app/app/l10n/app_localizations.dart';
import 'package:finance_management_app/routes/router.dart';

import '../features/presentation/blocs/login/login_bloc.dart';
import '../features/presentation/blocs/sign_up/signup_bloc.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthBloc>()..add(AuthCheckRequested())),
        BlocProvider(create: (_) => getIt<OnboardingBloc>()),
        BlocProvider(create: (_) => getIt<LoginBloc>()),
        BlocProvider(create: (_) => getIt<SignupBloc>()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: TAppTheme.lightTheme,
        darkTheme: TAppTheme.darkTheme,
        supportedLocales: AppLocalization.supportedLocales,
        localizationsDelegates: AppLocalization.localizationsDelegates,
        routerConfig: createAppRouter(getIt<AuthBloc>()),
      ),
    );
  }
}


