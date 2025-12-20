import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../common/widgets/card/budget_card.dart';
import '../../constants/app_border_radius.dart';
import '../../constants/app_padding.dart';
import '../../constants/app_spacing.dart';
import '../../constants/colors.dart';

/// Skeleton loading widget for budget card
/// Displays a skeleton version of the budget card while data is loading
class BudgetCardLoading extends StatelessWidget {
  final BudgetCardVariant variant;

  const BudgetCardLoading({
    super.key,
    this.variant = BudgetCardVariant.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(40),
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          color: TColors.white,
          boxShadow: [
            BoxShadow(
              color: TColors.primary.withOpacity(0.2),
              blurRadius: 3,
              spreadRadius: 2,
              offset: Offset.zero,
            ),
          ],
        ),
        padding: AppPadding.a16,
        margin: AppPadding.a16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Budget name skeleton
                    Container(
                      height: 16,
                      width: 150,
                      decoration: const BoxDecoration(
                        color: TColors.softGrey,
                        borderRadius: AppBorderRadius.xsm,
                      ),
                    ),
                    AppSpacing.h4,
                    // Budget type skeleton
                    Container(
                      height: 14,
                      width: 100,
                      decoration: const BoxDecoration(
                        color: TColors.softGrey,
                        borderRadius: AppBorderRadius.xsm,
                      ),
                    ),
                  ],
                ),
                // Icon skeleton
                Container(
                  decoration: BoxDecoration(
                    color: TColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  width: 50,
                  height: 50,
                ),
              ],
            ),
            AppSpacing.h4,
            // Calendar row skeleton
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: TColors.softGrey,
                    shape: BoxShape.circle,
                  ),
                ),
                AppSpacing.w4,
                Container(
                  height: 14,
                  width: 120,
                  decoration: const BoxDecoration(
                    color: TColors.softGrey,
                    borderRadius: AppBorderRadius.xsm,
                  ),
                ),
              ],
            ),
            AppSpacing.h4,
            // Progress section skeleton
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 14,
                      width: 80,
                      decoration: const BoxDecoration(
                        color: TColors.softGrey,
                        borderRadius: AppBorderRadius.xsm,
                      ),
                    ),
                    Container(
                      height: 14,
                      width: 40,
                      decoration: const BoxDecoration(
                        color: TColors.softGrey,
                        borderRadius: AppBorderRadius.xsm,
                      ),
                    ),
                  ],
                ),
                AppSpacing.h8,
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: TColors.softGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                AppSpacing.h8,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 14,
                      width: 100,
                      decoration: const BoxDecoration(
                        color: TColors.softGrey,
                        borderRadius: AppBorderRadius.xsm,
                      ),
                    ),
                    Container(
                      height: 14,
                      width: 100,
                      decoration: const BoxDecoration(
                        color: TColors.softGrey,
                        borderRadius: AppBorderRadius.xsm,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
