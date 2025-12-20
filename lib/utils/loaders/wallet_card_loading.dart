import 'package:flutter/material.dart';

import '../../constants/app_border_radius.dart';
import '../../constants/app_padding.dart';
import '../../constants/app_spacing.dart';
import '../../constants/colors.dart';
import '../../utils/helpers/helper_functions.dart';

/// Skeleton loading widget for wallet card
/// Displays a skeleton version of the wallet card while data is loading
class WalletCardLoading extends StatelessWidget {
  const WalletCardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8, left: 12, right: 12),
      width: THelperFunctions.screenWidth(context),
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.sm,
        color: TColors.white,
        boxShadow: [
          BoxShadow(
            color: TColors.primary.withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 2,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Column(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: TColors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 16,
                      decoration: BoxDecoration(
                        color: TColors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AppSpacing.w8,
                    Container(
                      width: 80,
                      height: 16,
                      decoration: BoxDecoration(
                        color: TColors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          Padding(
            padding: AppPadding.a16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: TColors.grey.withOpacity(0.3),
                        borderRadius: AppBorderRadius.sm,
                      ),
                    ),
                    AppSpacing.w16,
                    Container(
                      width: 80,
                      height: 16,
                      decoration: BoxDecoration(
                        color: TColors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 100,
                  height: 16,
                  decoration: BoxDecoration(
                    color: TColors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

