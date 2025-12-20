// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i17;
import 'package:finance_management_app/app/navigation_menu/navigation_menu.dart'
    as _i6;
import 'package:finance_management_app/features/domain/entities/budget_model.dart'
    as _i19;
import 'package:finance_management_app/features/domain/entities/transaction_model.dart'
    as _i20;
import 'package:finance_management_app/features/domain/entities/wallet_model.dart'
    as _i21;
import 'package:finance_management_app/features/presentation/screens/budget/budget_add_screen/budget_add_screen.dart'
    as _i1;
import 'package:finance_management_app/features/presentation/screens/chat/chat_screen.dart'
    as _i2;
import 'package:finance_management_app/features/presentation/screens/family/family_add_screen/family_add_screen.dart'
    as _i3;
import 'package:finance_management_app/features/presentation/screens/home/home_screen.dart'
    as _i4;
import 'package:finance_management_app/features/presentation/screens/login/login.dart'
    as _i5;
import 'package:finance_management_app/features/presentation/screens/onboarding/onboarding.dart'
    as _i7;
import 'package:finance_management_app/features/presentation/screens/profile/profile.dart'
    as _i8;
import 'package:finance_management_app/features/presentation/screens/settings/settings_screen.dart'
    as _i9;
import 'package:finance_management_app/features/presentation/screens/signup/signup.dart'
    as _i10;
import 'package:finance_management_app/features/presentation/screens/splash/splash.dart'
    as _i11;
import 'package:finance_management_app/features/presentation/screens/star/star_screen.dart'
    as _i12;
import 'package:finance_management_app/features/presentation/screens/transactions/transactions_screen.dart'
    as _i14;
import 'package:finance_management_app/features/presentation/screens/transactions_add_screen/transactions_add_screen.dart'
    as _i13;
import 'package:finance_management_app/features/presentation/screens/wallet/wallet_add/wallet_add_screen.dart'
    as _i15;
import 'package:finance_management_app/features/presentation/screens/wallet/wallet_detail_screen.dart'
    as _i16;
import 'package:flutter/material.dart' as _i18;

abstract class $AppRouter extends _i17.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i17.PageFactory> pagesMap = {
    BudgetAddScreenRoute.name: (routeData) {
      final args = routeData.argsAs<BudgetAddScreenRouteArgs>(
          orElse: () => const BudgetAddScreenRouteArgs());
      return _i17.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.BudgetAddScreen(
          key: args.key,
          budget: args.budget,
        ),
      );
    },
    ChatScreenRoute.name: (routeData) {
      return _i17.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i2.ChatScreen(),
      );
    },
    FamilyAddScreenRoute.name: (routeData) {
      return _i17.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i3.FamilyAddScreen(),
      );
    },
    HomeScreenRoute.name: (routeData) {
      return _i17.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i4.HomeScreen(),
      );
    },
    LoginScreenRoute.name: (routeData) {
      return _i17.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i5.LoginScreen(),
      );
    },
    NavigationMenuRoute.name: (routeData) {
      return _i17.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i6.NavigationMenu(),
      );
    },
    OnboardingScreenRoute.name: (routeData) {
      return _i17.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i7.OnboardingScreen(),
      );
    },
    ProfileScreenRoute.name: (routeData) {
      return _i17.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i8.ProfileScreen(),
      );
    },
    SettingsScreenRoute.name: (routeData) {
      return _i17.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i9.SettingsScreen(),
      );
    },
    SignUpScreenRoute.name: (routeData) {
      return _i17.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i10.SignUpScreen(),
      );
    },
    SplashScreenRoute.name: (routeData) {
      return _i17.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i11.SplashScreen(),
      );
    },
    StarScreenRoute.name: (routeData) {
      return _i17.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i12.StarScreen(),
      );
    },
    TransactionsAddScreenRoute.name: (routeData) {
      final args = routeData.argsAs<TransactionsAddScreenRouteArgs>(
          orElse: () => const TransactionsAddScreenRouteArgs());
      return _i17.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i13.TransactionsAddScreen(
          key: args.key,
          transaction: args.transaction,
        ),
      );
    },
    TransactionsScreenRoute.name: (routeData) {
      return _i17.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i14.TransactionsScreen(),
      );
    },
    WalletAddScreenRoute.name: (routeData) {
      final args = routeData.argsAs<WalletAddScreenRouteArgs>(
          orElse: () => const WalletAddScreenRouteArgs());
      return _i17.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i15.WalletAddScreen(
          key: args.key,
          wallet: args.wallet,
        ),
      );
    },
    WalletDetailScreenRoute.name: (routeData) {
      final args = routeData.argsAs<WalletDetailScreenRouteArgs>();
      return _i17.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i16.WalletDetailScreen(
          key: args.key,
          walletId: args.walletId,
        ),
      );
    },
  };
}

/// generated route for
/// [_i1.BudgetAddScreen]
class BudgetAddScreenRoute
    extends _i17.PageRouteInfo<BudgetAddScreenRouteArgs> {
  BudgetAddScreenRoute({
    _i18.Key? key,
    _i19.BudgetModel? budget,
    List<_i17.PageRouteInfo>? children,
  }) : super(
          BudgetAddScreenRoute.name,
          args: BudgetAddScreenRouteArgs(
            key: key,
            budget: budget,
          ),
          initialChildren: children,
        );

  static const String name = 'BudgetAddScreenRoute';

  static const _i17.PageInfo<BudgetAddScreenRouteArgs> page =
      _i17.PageInfo<BudgetAddScreenRouteArgs>(name);
}

class BudgetAddScreenRouteArgs {
  const BudgetAddScreenRouteArgs({
    this.key,
    this.budget,
  });

  final _i18.Key? key;

  final _i19.BudgetModel? budget;

  @override
  String toString() {
    return 'BudgetAddScreenRouteArgs{key: $key, budget: $budget}';
  }
}

/// generated route for
/// [_i2.ChatScreen]
class ChatScreenRoute extends _i17.PageRouteInfo<void> {
  const ChatScreenRoute({List<_i17.PageRouteInfo>? children})
      : super(
          ChatScreenRoute.name,
          initialChildren: children,
        );

  static const String name = 'ChatScreenRoute';

  static const _i17.PageInfo<void> page = _i17.PageInfo<void>(name);
}

/// generated route for
/// [_i3.FamilyAddScreen]
class FamilyAddScreenRoute extends _i17.PageRouteInfo<void> {
  const FamilyAddScreenRoute({List<_i17.PageRouteInfo>? children})
      : super(
          FamilyAddScreenRoute.name,
          initialChildren: children,
        );

  static const String name = 'FamilyAddScreenRoute';

  static const _i17.PageInfo<void> page = _i17.PageInfo<void>(name);
}

/// generated route for
/// [_i4.HomeScreen]
class HomeScreenRoute extends _i17.PageRouteInfo<void> {
  const HomeScreenRoute({List<_i17.PageRouteInfo>? children})
      : super(
          HomeScreenRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeScreenRoute';

  static const _i17.PageInfo<void> page = _i17.PageInfo<void>(name);
}

/// generated route for
/// [_i5.LoginScreen]
class LoginScreenRoute extends _i17.PageRouteInfo<void> {
  const LoginScreenRoute({List<_i17.PageRouteInfo>? children})
      : super(
          LoginScreenRoute.name,
          initialChildren: children,
        );

  static const String name = 'LoginScreenRoute';

  static const _i17.PageInfo<void> page = _i17.PageInfo<void>(name);
}

/// generated route for
/// [_i6.NavigationMenu]
class NavigationMenuRoute extends _i17.PageRouteInfo<void> {
  const NavigationMenuRoute({List<_i17.PageRouteInfo>? children})
      : super(
          NavigationMenuRoute.name,
          initialChildren: children,
        );

  static const String name = 'NavigationMenuRoute';

  static const _i17.PageInfo<void> page = _i17.PageInfo<void>(name);
}

/// generated route for
/// [_i7.OnboardingScreen]
class OnboardingScreenRoute extends _i17.PageRouteInfo<void> {
  const OnboardingScreenRoute({List<_i17.PageRouteInfo>? children})
      : super(
          OnboardingScreenRoute.name,
          initialChildren: children,
        );

  static const String name = 'OnboardingScreenRoute';

  static const _i17.PageInfo<void> page = _i17.PageInfo<void>(name);
}

/// generated route for
/// [_i8.ProfileScreen]
class ProfileScreenRoute extends _i17.PageRouteInfo<void> {
  const ProfileScreenRoute({List<_i17.PageRouteInfo>? children})
      : super(
          ProfileScreenRoute.name,
          initialChildren: children,
        );

  static const String name = 'ProfileScreenRoute';

  static const _i17.PageInfo<void> page = _i17.PageInfo<void>(name);
}

/// generated route for
/// [_i9.SettingsScreen]
class SettingsScreenRoute extends _i17.PageRouteInfo<void> {
  const SettingsScreenRoute({List<_i17.PageRouteInfo>? children})
      : super(
          SettingsScreenRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsScreenRoute';

  static const _i17.PageInfo<void> page = _i17.PageInfo<void>(name);
}

/// generated route for
/// [_i10.SignUpScreen]
class SignUpScreenRoute extends _i17.PageRouteInfo<void> {
  const SignUpScreenRoute({List<_i17.PageRouteInfo>? children})
      : super(
          SignUpScreenRoute.name,
          initialChildren: children,
        );

  static const String name = 'SignUpScreenRoute';

  static const _i17.PageInfo<void> page = _i17.PageInfo<void>(name);
}

/// generated route for
/// [_i11.SplashScreen]
class SplashScreenRoute extends _i17.PageRouteInfo<void> {
  const SplashScreenRoute({List<_i17.PageRouteInfo>? children})
      : super(
          SplashScreenRoute.name,
          initialChildren: children,
        );

  static const String name = 'SplashScreenRoute';

  static const _i17.PageInfo<void> page = _i17.PageInfo<void>(name);
}

/// generated route for
/// [_i12.StarScreen]
class StarScreenRoute extends _i17.PageRouteInfo<void> {
  const StarScreenRoute({List<_i17.PageRouteInfo>? children})
      : super(
          StarScreenRoute.name,
          initialChildren: children,
        );

  static const String name = 'StarScreenRoute';

  static const _i17.PageInfo<void> page = _i17.PageInfo<void>(name);
}

/// generated route for
/// [_i13.TransactionsAddScreen]
class TransactionsAddScreenRoute
    extends _i17.PageRouteInfo<TransactionsAddScreenRouteArgs> {
  TransactionsAddScreenRoute({
    _i18.Key? key,
    _i20.TransactionModel? transaction,
    List<_i17.PageRouteInfo>? children,
  }) : super(
          TransactionsAddScreenRoute.name,
          args: TransactionsAddScreenRouteArgs(
            key: key,
            transaction: transaction,
          ),
          initialChildren: children,
        );

  static const String name = 'TransactionsAddScreenRoute';

  static const _i17.PageInfo<TransactionsAddScreenRouteArgs> page =
      _i17.PageInfo<TransactionsAddScreenRouteArgs>(name);
}

class TransactionsAddScreenRouteArgs {
  const TransactionsAddScreenRouteArgs({
    this.key,
    this.transaction,
  });

  final _i18.Key? key;

  final _i20.TransactionModel? transaction;

  @override
  String toString() {
    return 'TransactionsAddScreenRouteArgs{key: $key, transaction: $transaction}';
  }
}

/// generated route for
/// [_i14.TransactionsScreen]
class TransactionsScreenRoute extends _i17.PageRouteInfo<void> {
  const TransactionsScreenRoute({List<_i17.PageRouteInfo>? children})
      : super(
          TransactionsScreenRoute.name,
          initialChildren: children,
        );

  static const String name = 'TransactionsScreenRoute';

  static const _i17.PageInfo<void> page = _i17.PageInfo<void>(name);
}

/// generated route for
/// [_i15.WalletAddScreen]
class WalletAddScreenRoute
    extends _i17.PageRouteInfo<WalletAddScreenRouteArgs> {
  WalletAddScreenRoute({
    _i18.Key? key,
    _i21.WalletModel? wallet,
    List<_i17.PageRouteInfo>? children,
  }) : super(
          WalletAddScreenRoute.name,
          args: WalletAddScreenRouteArgs(
            key: key,
            wallet: wallet,
          ),
          initialChildren: children,
        );

  static const String name = 'WalletAddScreenRoute';

  static const _i17.PageInfo<WalletAddScreenRouteArgs> page =
      _i17.PageInfo<WalletAddScreenRouteArgs>(name);
}

class WalletAddScreenRouteArgs {
  const WalletAddScreenRouteArgs({
    this.key,
    this.wallet,
  });

  final _i18.Key? key;

  final _i21.WalletModel? wallet;

  @override
  String toString() {
    return 'WalletAddScreenRouteArgs{key: $key, wallet: $wallet}';
  }
}

/// generated route for
/// [_i16.WalletDetailScreen]
class WalletDetailScreenRoute
    extends _i17.PageRouteInfo<WalletDetailScreenRouteArgs> {
  WalletDetailScreenRoute({
    _i18.Key? key,
    required String walletId,
    List<_i17.PageRouteInfo>? children,
  }) : super(
          WalletDetailScreenRoute.name,
          args: WalletDetailScreenRouteArgs(
            key: key,
            walletId: walletId,
          ),
          initialChildren: children,
        );

  static const String name = 'WalletDetailScreenRoute';

  static const _i17.PageInfo<WalletDetailScreenRouteArgs> page =
      _i17.PageInfo<WalletDetailScreenRouteArgs>(name);
}

class WalletDetailScreenRouteArgs {
  const WalletDetailScreenRouteArgs({
    this.key,
    required this.walletId,
  });

  final _i18.Key? key;

  final String walletId;

  @override
  String toString() {
    return 'WalletDetailScreenRouteArgs{key: $key, walletId: $walletId}';
  }
}
