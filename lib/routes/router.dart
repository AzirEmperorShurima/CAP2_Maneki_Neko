import 'dart:async';
import 'package:finance_management_app/features/presentation/screens/transactions_add_screen/transactions_add_screen.dart';
import 'package:finance_management_app/utils/utils.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../app/navigation_menu/navigation_menu.dart';
import '../features/presentation/blocs/auth/auth_bloc.dart';
import '../features/presentation/blocs/auth/auth_state.dart';
import '../features/presentation/screens/login/login.dart';
import '../features/presentation/screens/onboarding/onboarding.dart';
import '../features/presentation/screens/signup/signup.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class BlocStreamRefreshListenable extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;
  BlocStreamRefreshListenable(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createAppRouter(AuthBloc authBloc) {
  final refresh = BlocStreamRefreshListenable(authBloc.stream);
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) async {
      final isFirstTime = await Utils.getIsFirstTime();
      if (isFirstTime) return '/';
      // final status = authBloc.state.status;
      // final atAuth = state.matchedLocation == '/login' ||
      //     state.matchedLocation == '/signup';
      // if (status != AuthStatus.authenticated && !atAuth) return '/login';
      // // Không redirect khi đã authenticated để giữ nguyên route hiện tại
      // return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
      GoRoute(path: '/menu', builder: (_, __) => const NavigationMenu()),
      GoRoute(path: '/transactions_add', builder: (_, __) => const TransactionsAddScreen()),
    ],
  );
}
