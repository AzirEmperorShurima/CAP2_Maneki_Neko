import 'package:auto_route/auto_route.dart';
import 'package:finance_management_app/routes/router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Route')
class AppRouter extends $AppRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: SplashScreenRoute.page, path: '/', initial: true),
        AutoRoute(page: OnboardingScreenRoute.page, path: '/onboarding'),
        AutoRoute(page: LoginScreenRoute.page, path: '/login'),
        AutoRoute(page: SignUpScreenRoute.page, path: '/signup'),
        AutoRoute(page: NavigationMenuRoute.page, path: '/menu'),
        AutoRoute(page: TransactionsScreenRoute.page, path: '/transactions'),
        AutoRoute(
            page: TransactionsAddScreenRoute.page, path: '/transactions_add'),
        AutoRoute(page: HomeScreenRoute.page, path: '/home'),
        AutoRoute(page: ChatScreenRoute.page, path: '/chat'),
        AutoRoute(page: BudgetAddScreenRoute.page, path: '/budget_add'),
        AutoRoute(page: SettingsScreenRoute.page, path: '/settings'),
        AutoRoute(page: ProfileScreenRoute.page, path: '/profile'),
        AutoRoute(page: WalletAddScreenRoute.page, path: '/wallet_add'),
        AutoRoute(
            page: WalletDetailScreenRoute.page,
            path: '/wallet_detail/:walletId'),
        AutoRoute(page: StarScreenRoute.page, path: '/star'),
        AutoRoute(page: FamilyAddScreenRoute.page, path: '/family_add'),
      ];
}
