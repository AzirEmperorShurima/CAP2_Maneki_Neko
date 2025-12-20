import 'package:finance_management_app/constants/app_spacing.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:finance_management_app/utils/responsive/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../common/widgets/text/price_text.dart';

class FinancialItemsLoading extends StatelessWidget {
  const FinancialItemsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFinancialItemSkeleton(context,
            label: 'Tổng', icon: Iconsax.empty_wallet),
        _buildDivider(context),
        _buildFinancialItemSkeleton(context,
            label: 'Thu nhập', icon: Iconsax.arrow_up_1),
        _buildDivider(context),
        _buildFinancialItemSkeleton(context,
            label: 'Chi tiêu', icon: Iconsax.arrow_down_2),
      ],
    );
  }

  Widget _buildFinancialItemSkeleton(BuildContext context,
      {required String label, required IconData icon}) {
    final iconSize = ResponsiveHelper.getResponsiveIconSize(context, 0.015);

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Skeleton cho amount
          const Skeletonizer(
            enabled: true,
            child: PriceText(amount: '10000000', color: TColors.darkGrey),
          ),
          AppSpacing.h8,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize),
              AppSpacing.w4,
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: ResponsiveHelper.getResponsiveHeight(context, 0.037),
      color: TColors.softGrey,
    );
  }
}

class FinancialCardHeaderLoading extends StatelessWidget {
  const FinancialCardHeaderLoading({super.key});

  @override
  Widget build(BuildContext context) {
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
        Skeletonizer(
          enabled: true,
          child: PriceText(
            amount: '10000000',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: TColors.white, fontWeight: FontWeight.bold),
            currencyStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: TColors.white,
                decoration: TextDecoration.underline,
                decorationColor: TColors.white,
                fontWeight: FontWeight.bold),
          ),
        ),
        AppSpacing.h16,
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tài sản',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: TColors.white)),
                  const Skeletonizer(
                    enabled: true,
                    child: PriceText(amount: '10000000', color: TColors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dư nợ',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: TColors.white),
                  ),
                  const Skeletonizer(
                    enabled: true,
                    child: PriceText(amount: '20000000', color: TColors.white),
                  )
                ],
              ),
            )
          ],
        ),
      ],
    );
  }
}
