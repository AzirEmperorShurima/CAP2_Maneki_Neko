import 'package:auto_route/auto_route.dart';
import 'package:finance_management_app/common/widgets/text/price_text.dart';
import 'package:finance_management_app/constants/app_padding.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:finance_management_app/utils/helpers/helper_functions.dart';
import 'package:finance_management_app/utils/loaders/financial_card_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/api_builder/analysis_builder.dart';
import '../../../../../common/api_builder/wallet_builder.dart';
import '../../../../../common/widgets/card/wallet_card.dart';
import '../../../../../constants/app_spacing.dart';
import '../../../../../routes/router.gr.dart';

class TransactionsWallet extends StatefulWidget {
  const TransactionsWallet({super.key});

  @override
  State<TransactionsWallet> createState() => _TransactionsWalletState();
}

class _TransactionsWalletState extends State<TransactionsWallet> {
  final GlobalKey<AnalysisBuilderState> _analysisKey =
      GlobalKey<AnalysisBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 170,
          width: THelperFunctions.screenWidth(context),
          decoration: BoxDecoration(
            color: TColors.primary,
            boxShadow: [
              BoxShadow(
                color: TColors.primary.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 5,
                offset: Offset.zero,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: AppPadding.h16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => AutoRouter.of(context)
                              .push(WalletAddScreenRoute()),
                          child: const Icon(Iconsax.empty_wallet5,
                              color: TColors.white, size: 25),
                        ),
                      ],
                    ),
                    AnalysisBuilder(
                      key: _analysisKey,
                      loadingBuilder: (context) =>
                          const FinancialCardHeaderLoading(),
                      builder: (context, analysis) {
                        final netNegative =
                            (analysis?.overall?.netBalance ?? 0) < 0;
                        final totalWalletBalanceNegative =
                            (analysis?.overall?.totalWalletBalance ?? 0) < 0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tài sản ròng',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: TColors.white),
                            ),
                            AppSpacing.h2,
                            PriceText(
                              title: netNegative ? '-' : null,
                              amount:
                                  analysis?.overall?.netBalance?.toString() ??
                                      '0',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                      color: TColors.white,
                                      fontWeight: FontWeight.bold),
                              currencyStyle: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                      color: TColors.white,
                                      decoration: TextDecoration.underline,
                                      decorationColor: TColors.white,
                                      fontWeight: FontWeight.bold),
                            ),
                            AppSpacing.h16,
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Tài sản',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(color: TColors.white)),
                                      PriceText(
                                          title: totalWalletBalanceNegative
                                              ? '-'
                                              : null,
                                          amount: analysis
                                                  ?.overall?.totalWalletBalance
                                                  ?.toString() ??
                                              '0',
                                          color: TColors.white),
                                    ],
                                  ),
                                ),
                                // Expanded(
                                //   child: Column(
                                //     crossAxisAlignment:
                                //         CrossAxisAlignment.start,
                                //     children: [
                                //       Text(
                                //         'Dư nợ',
                                //         style: Theme.of(context)
                                //             .textTheme
                                //             .labelLarge
                                //             ?.copyWith(color: TColors.white),
                                //       ),
                                //       const PriceText(
                                //           amount: '20000000',
                                //           color: TColors.white)
                                //     ],
                                //   ),
                                // )
                              ],
                            ),
                          ],
                        );
                      },
                    )
                  ],
                ),
              )
            ],
          ),
        ),
        Expanded(
          child: AnimationLimiter(
            child: WalletBuilder(
              autoLoad: true,
              onRefresh: () {
                // Refresh AnalysisBuilder với đúng params ban đầu
                _analysisKey.currentState?.refresh();
              },
              itemBuilder: (context, wallet, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 500),
                  child: SlideAnimation(
                    verticalOffset: 50,
                    child: FadeInAnimation(
                      child: WalletCard(
                        wallet: wallet,
                        onTap: () => AutoRouter.of(context).push(
                            WalletDetailScreenRoute(walletId: wallet.id ?? '')),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
