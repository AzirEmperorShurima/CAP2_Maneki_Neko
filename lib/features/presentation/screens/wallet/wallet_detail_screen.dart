import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../../common/api_builder/wallet_analysis_builder.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/tab_switcher/tab_switcher.dart';
import '../../../../common/widgets/text/price_text.dart';
import '../../../../constants/app_border_radius.dart';
import '../../../../constants/app_padding.dart';
import '../../../../constants/app_spacing.dart';
import '../../../../constants/colors.dart';
import '../../../../features/presentation/blocs/wallet/wallet_bloc.dart';
import '../../../../features/presentation/blocs/wallet_analysis/wallet_analysis_bloc.dart';
import '../../../../routes/router.gr.dart';
import '../../../../utils/device/device_utility.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../domain/entities/wallet_model.dart';
import 'wallet_analysis_tab/wallet_analysis_tab.dart';
import 'wallet_detail_tab/wallet_detail_tab.dart';

@RoutePage()
class WalletDetailScreen extends StatefulWidget {
  final String walletId;

  const WalletDetailScreen({super.key, required this.walletId});

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  int _selectedIndex = 0;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    context.read<WalletAnalysisBloc>().add(
          RefreshWalletAnalysis(walletId: widget.walletId),
        );
  }

  void _editWallet(BuildContext context, String walletId) {
    // Lấy WalletModel từ WalletBloc dựa trên walletId
    final walletState = context.read<WalletBloc>().state;
    WalletModel? wallet;
    
    if (walletState is WalletLoaded) {
      try {
        wallet = walletState.wallets.firstWhere(
          (w) => w.id == walletId,
        );
      } catch (e) {
        // Không tìm thấy wallet trong danh sách
        wallet = null;
      }
    } else if (walletState is WalletRefreshing) {
      try {
        wallet = walletState.wallets.firstWhere(
          (w) => w.id == walletId,
        );
      } catch (e) {
        wallet = null;
      }
    }
    
    if (wallet != null) {
      AutoRouter.of(context).push(
        WalletAddScreenRoute(wallet: wallet),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WalletAnalysisBuilder(
      walletId: widget.walletId,
      builder: (context, analysis) {
        final wallet = analysis?.wallet;
        
    return Scaffold(
      appBar: TAppBar(
        title: Text(
          'Chi tiết ví tiền',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: TColors.white),
        ),
        centerTitle: true,
        showBackArrow: true,
        leadingIconColor: TColors.white,
            actions: [
          Padding(
            padding: AppPadding.h16,
                child: GestureDetector(
                  onTap: () => _editWallet(context, widget.walletId),
                  child: const Icon(Iconsax.card_edit, size: 25, color: TColors.white),
                ),
          )
        ],
        backgroundColor: TColors.primary,
      ),
      body: BlocListener<WalletAnalysisBloc, WalletAnalysisState>(
        listener: (context, state) {
          if (state is WalletAnalysisLoaded) {
            _refreshController.refreshCompleted();
          } else if (state is WalletAnalysisFailure) {
            _refreshController.refreshFailed();
          }
        },
            child: Builder(
                builder: (context) {
            final summary = analysis?.summary;

            final walletName = wallet?.name ?? 'Ví';
            final walletType = wallet?.type ?? 'Ví';
            final walletIcon = wallet?.icon ?? '💳';
            final currentBalance = wallet?.balance?.toDouble() ?? 0.0;
            final totalIncome = summary?.totalIncome?.toDouble() ?? 0.0;
            final totalExpense = summary?.totalExpense?.toDouble() ?? 0.0;

            // Lấy tháng hiện tại
            final now = DateTime.now();
            final currentMonth = '${now.month}/${now.year}';

            return Column(
              children: [
                Expanded(
                  child: SmartRefresher(
                    controller: _refreshController,
                    onRefresh: _onRefresh,
                    enablePullDown: true,
                    enablePullUp: false,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: AppPadding.h16,
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 16, bottom: 8),
                              width: THelperFunctions.screenWidth(context),
                              decoration: BoxDecoration(
                                borderRadius: AppBorderRadius.sm,
                                color: TColors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: TColors.primary.withOpacity(0.2),
                                    blurRadius: 5,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: TColors.primary,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                    ),
                                    padding: AppPadding.a8,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          walletType,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(color: TColors.white),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              'Tài sản: ',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge
                                                  ?.copyWith(
                                                      color: TColors.white),
                                            ),
                                            PriceText(
                                              amount: currentBalance
                                                  .toStringAsFixed(0),
                                              color: TColors.white,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge
                                                  ?.copyWith(
                                                      color: TColors.white),
                                              currencyStyle: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge
                                                  ?.copyWith(
                                                      color: TColors.white,
                                                      decoration: TextDecoration
                                                          .underline,
                                                      decorationColor:
                                                          TColors.white),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 16,
                                        right: 16,
                                        top: 16,
                                        bottom: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              walletIcon,
                                              style:
                                                  const TextStyle(fontSize: 40),
                                            ),
                                            AppSpacing.w16,
                                            Text(
                                              walletName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge,
                                            ),
                                          ],
                                        ),
                                        PriceText(
                                          amount:
                                              currentBalance.toStringAsFixed(0),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                          currencyStyle: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                        )
                                      ],
                                    ),
                                  ),
                                  const Divider(color: TColors.softGrey),
                                  AppSpacing.h8,
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.arrow_back_ios,
                                          size: 15, color: TColors.primary),
                                      AppSpacing.w16,
                                      Row(
                                        children: [
                                          Text(
                                            currentMonth,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                          AppSpacing.w4,
                                          const Icon(Icons.arrow_drop_down,
                                              size: 20, color: TColors.primary),
                                        ],
                                      ),
                                      AppSpacing.w8,
                                      const Icon(Icons.arrow_forward_ios,
                                          size: 15),
                                    ],
                                  ),
                                  AppSpacing.h16,
                                  Padding(
                                    padding: AppPadding.h16,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            'Thu nhập',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                        AppSpacing.w16,
                                        Expanded(
                                          child: Container(
                                            height: 40,
                                            decoration: const BoxDecoration(
                                              color: TColors.primary,
                                              borderRadius: AppBorderRadius.xl,
                                            ),
                                            padding: AppPadding.a8,
                                            child: Center(
                                              child: PriceText(
                                                amount: totalIncome
                                                    .toStringAsFixed(0),
                                                color: TColors.white,
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  AppSpacing.h8,
                                  Padding(
                                    padding: AppPadding.h16,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            'Chi tiêu',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                        AppSpacing.w16,
                                        Expanded(
                                          child: Container(
                                            height: 40,
                                            decoration: const BoxDecoration(
                                              color: TColors.primary,
                                              borderRadius: AppBorderRadius.xl,
                                            ),
                                            padding: AppPadding.a8,
                                            child: Center(
                                              child: PriceText(
                                                amount: totalExpense
                                                    .toStringAsFixed(0),
                                                color: TColors.white,
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  AppSpacing.h16,
                                ],
                              ),
                            ),
                            AppSpacing.h8,
                            TabSwitcher(
                              tabs: const [
                                'Phân tích',
                                'Chi tiết',
                              ],
                              borderRadius: AppBorderRadius.xl,
                              backgroundColor: TColors.primary.withOpacity(0.2),
                              isSelectedColors: TColors.primary,
                              isUnSelectedColors: Colors.transparent,
                              isSelectedTextColors: Colors.white,
                              isUnSelectedTextColors: Colors.black,
                              padding: AppPadding.a4.add(AppPadding.a2),
                              selectedIndex: _selectedIndex,
                              onTabSelected: (index) {
                                TDeviceUtils.lightImpact();
                                setState(() => _selectedIndex = index);
                              },
                            ),
                            AppSpacing.h16,
                                  IndexedStack(
                                index: _selectedIndex,
                                children: [
                                  WalletAnalysisTab(walletId: widget.walletId),
                                  WalletDetailTab(walletId: widget.walletId),
                                ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
            ),
          ),
        );
      },
      loadingBuilder: (context) => Scaffold(
        appBar: TAppBar(
          title: Text(
            'Chi tiết ví tiền',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: TColors.white),
          ),
          centerTitle: true,
          showBackArrow: true,
          leadingIconColor: TColors.white,
          backgroundColor: TColors.primary,
        ),
        body: const Center(
            child: CircularProgressIndicator(),
        ),
          ),
      errorBuilder: (context, message) => Scaffold(
        appBar: TAppBar(
          title: Text(
            'Chi tiết ví tiền',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: TColors.white),
          ),
          centerTitle: true,
          showBackArrow: true,
          leadingIconColor: TColors.white,
          backgroundColor: TColors.primary,
        ),
        body: Center(
            child: Text('Lỗi: $message'),
        ),
      ),
    );
  }
}
