import 'package:auto_route/auto_route.dart';
import 'package:finance_management_app/app/theme/theme.dart';
import 'package:finance_management_app/core/common/enums/auth_status.dart';
import 'package:finance_management_app/core/di/injector.dart';
import 'package:finance_management_app/core/routes/app_navigator_observer.dart';
import 'package:finance_management_app/features/app/presentation/bloc/app_cubit.dart';
import 'package:finance_management_app/features/presentation/blocs/onboarding/onboarding_bloc.dart';
import 'package:finance_management_app/routes/router.dart';
import 'package:finance_management_app/routes/router.gr.dart';
import 'package:finance_management_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/presentation/blocs/analysis/analysis_bloc.dart';
import '../features/presentation/blocs/budget/budget_bloc.dart';
import '../features/presentation/blocs/category/category_bloc.dart';
import '../features/presentation/blocs/category_analysis/category_analysis_bloc.dart';
import '../features/presentation/blocs/chat/chat_bloc.dart';
import '../features/presentation/blocs/family/family_bloc.dart';
import '../features/presentation/blocs/login/login_bloc.dart';
import '../features/presentation/blocs/settings/settings_bloc.dart';
import '../features/presentation/blocs/sign_up/signup_bloc.dart';
import '../features/presentation/blocs/transaction/transaction_bloc.dart';
import '../features/presentation/blocs/user/user_bloc.dart';
import '../features/presentation/blocs/wallet/wallet_bloc.dart';
import '../features/presentation/blocs/wallet_analysis/wallet_analysis_bloc.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  late AppCubit _appCubit;
  late UserBloc _userBloc;
  final _appRouter = AppRouter();

  @override
  void initState() {
    super.initState();
    _appCubit = getIt<AppCubit>();
    _userBloc = getIt<UserBloc>();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appCubit.openApp();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> _navigate(StackRouter router, AppState state) async {
    if (state.authStatus == AuthStatus.unauthenticated) {
      final isFirstTime = await Utils.getIsFirstTime();
      router.replaceAll([
        if (isFirstTime) const OnboardingScreenRoute() else const LoginScreenRoute()
      ]);
    } else if (state.authStatus == AuthStatus.authenticated) {
      router.replaceAll([const NavigationMenuRoute()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _appCubit),
        BlocProvider.value(value: _userBloc),
        BlocProvider(create: (_) => getIt<OnboardingBloc>()),
        BlocProvider(create: (_) => getIt<LoginBloc>()),
        BlocProvider(create: (_) => getIt<SignupBloc>()),
        BlocProvider(create: (_) => getIt<SettingsBloc>()),
        BlocProvider(create: (_) => getIt<TransactionBloc>()),
        BlocProvider(create: (_) => getIt<CategoryBloc>()),
        BlocProvider(create: (_) => getIt<WalletBloc>()),
        BlocProvider(create: (_) => getIt<ChatBloc>()),
        BlocProvider(create: (_) => getIt<AnalysisBloc>()),
        BlocProvider(create: (_) => getIt<BudgetBloc>()),
        BlocProvider(create: (_) => getIt<WalletAnalysisBloc>()),
        BlocProvider(create: (_) => getIt<CategoryAnalysisBloc>()),
        BlocProvider(create: (_) => getIt<FamilyBloc>()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: TAppTheme.lightTheme,
        darkTheme: TAppTheme.lightTheme,
        routerConfig: _appRouter.config(
          navigatorObservers: () => [getIt<AppNavigatorObserver>()],
        ),
        builder: (context, child) {
          return BlocListener<AppCubit, AppState>(
            listenWhen: (prev, curr) => prev.authStatus != curr.authStatus,
            listener: (context, state) {
              // Load user data khi authenticated
              if (state.authStatus == AuthStatus.authenticated) {
                context.read<UserBloc>().add(LoadUser());
              }
              
              // Reset các Bloc khi logout (chuyển từ authenticated sang unauthenticated)
              if (state.authStatus == AuthStatus.unauthenticated) {
                context.read<WalletBloc>().add(ResetWallets());
                context.read<WalletAnalysisBloc>().add(ResetWalletAnalysis());
                context.read<BudgetBloc>().add(ResetBudgets());
                context.read<AnalysisBloc>().add(ResetAnalysis());
                context.read<TransactionBloc>().add(ResetTransactions());
                context.read<CategoryBloc>().add(ResetCategories());
                context.read<FamilyBloc>().add(ResetFamily());
              }
              
              // Delay navigation để đảm bảo router đã sẵn sàng
              // Dùng _appRouter instance vì nó đã được config trong routerConfig
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                try {
                  await _navigate(_appRouter, state);
                } catch (e) {
                  debugPrint('Navigation error: $e');
                }
              });
            },
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.noScaling,
              ),
              child: child!,
            ),
          );
        },
      ),
    );
  }
}
