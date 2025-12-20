import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../common/widgets/text/price_text.dart';
import '../../constants/app_border_radius.dart';
import '../../constants/app_padding.dart';
import '../../constants/app_spacing.dart';
import '../../constants/colors.dart';
import '../../utils/helpers/helper_functions.dart';

/// Skeleton loading widget for transaction card
/// Displays a skeleton version of the transaction card while data is loading
class TransactionCardLoading extends StatelessWidget {
  const TransactionCardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        itemCount: 3,
        
        itemBuilder: (context, index) => Container(
          margin: AppPadding.h16,
          padding: AppPadding.v8,
          child: Stack(
            children: [
              Container(
                width: THelperFunctions.screenWidth(context),
                decoration: BoxDecoration(
                  color: TColors.white,
                  borderRadius: AppBorderRadius.md,
                  boxShadow: [
                    BoxShadow(
                      color: TColors.primary.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: Offset.zero,
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 40,
                  bottom: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            borderRadius: AppBorderRadius.sm,
                            color: TColors.primary.withOpacity(0.1),
                          ),
                          padding: AppPadding.a4,
                          child: const Center(
                            child: SizedBox(
                              height: 40,
                              width: 40,
                            ),
                          ),
                        ),
                        AppSpacing.w16,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Loading...',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                'Loading...',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: TColors.darkGrey),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const PriceText(
                              title: '-',
                              amount: '0000000',
                              color: Colors.red,
                            ),
                            Text(
                              'Loading...',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: TColors.darkGrey),
                            )
                          ],
                        ),
                      ],
                    ),
                    AppSpacing.h4,
                    const Divider(color: TColors.softGrey),
                    AppSpacing.h4,
                    Row(
                      children: [
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            borderRadius: AppBorderRadius.sm,
                            color: TColors.primary.withOpacity(0.1),
                          ),
                          padding: AppPadding.a4,
                          child: const Center(
                            child: SizedBox(
                              height: 40,
                              width: 40,
                            ),
                          ),
                        ),
                        AppSpacing.w16,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Loading...',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                'Loading...',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: TColors.darkGrey),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const PriceText(
                              title: '+',
                              amount: '0000000',
                              color: Colors.green,
                            ),
                            Text(
                              'Loading...',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: TColors.darkGrey),
                            )
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: THelperFunctions.screenWidth(context),
                decoration: const BoxDecoration(
                  color: TColors.primary,
                  borderRadius: AppBorderRadius.md,
                ),
                padding: AppPadding.h16.add(AppPadding.v4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.expand_circle_down,
                      size: 18,
                      color: TColors.white,
                    ),
                    AppSpacing.w16,
                    Expanded(
                      child: Text(
                        'Loading...',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: TColors.white),
                      ),
                    ),
                    PriceText(
                      title: 'Chi tiêu: ',
                      amount: '0000000',
                      color: TColors.white,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: TColors.white),
                      currencyStyle: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(
                            color: TColors.white,
                            decoration: TextDecoration.underline,
                            decorationColor: TColors.white,
                          ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

