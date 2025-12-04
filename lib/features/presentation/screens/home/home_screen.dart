import 'package:finance_management_app/common/widgets/appbar/home_appbar.dart';
import 'package:finance_management_app/constants/app_border_radius.dart';
import 'package:finance_management_app/constants/app_padding.dart';
import 'package:finance_management_app/constants/app_spacing.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:finance_management_app/constants/image_strings.dart';
import 'package:finance_management_app/utils/helpers/helper_functions.dart';
import 'package:finance_management_app/utils/responsive/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/text/price_text.dart';
import '../../../../common/widgets/profile/t_circular_image.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = THelperFunctions.screenHeight(context);
    final screenWidth = THelperFunctions.screenWidth(context);
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final appBarHeight = kToolbarHeight;
    
    final curvedContainerHeight = ResponsiveHelper.getResponsiveHeight(context, 0.11);
    final spacingAfterCurve = ResponsiveHelper.getResponsiveHeight(context, 0.10);
    final cardTopPosition = safeAreaTop + appBarHeight + curvedContainerHeight - ResponsiveHelper.getResponsiveHeight(context, 0.1);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  color: TColors.primary,
                  child: THomeAppBar(
                    backgroundColor: TColors.primary,
                  ),
                ),
                Container(
                  height: curvedContainerHeight,
                  width: screenWidth,
                  decoration: BoxDecoration(
                    color: TColors.primary,
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 0.18)),
                    ),
                  ),
                ),
                SizedBox(height: spacingAfterCurve),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.only(bottom: 100),
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
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.only(
                                left: 16, right: 16, top: 40, bottom: 16),
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
                                      child: Center(child: Image.asset('assets/images/icons/food.png', height: 40, width: 40)),
                                    ),
                                    AppSpacing.w16,
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Food',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge),
                                          Text('Me',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                      color: TColors.darkGrey)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        PriceText(
                                          title: '-',
                                          amount: '5000000',
                                          color: Colors.red,
                                        ),
                                        Text(
                                          'Salary',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  color: TColors.darkGrey),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                                AppSpacing.h4,
                                Divider(
                                  color: TColors.softGrey,
                                ),
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
                                      child: Center(child: Image.asset('assets/images/icons/money.png', height: 40, width: 40)),
                                    ),
                                    AppSpacing.w16,
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Reward',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge),
                                          Text('Me',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                      color: TColors.darkGrey)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        PriceText(
                                          title: '+',
                                          amount: '5000000',
                                          color: Colors.green,
                                        ),
                                        Text(
                                          'Salary',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  color: TColors.darkGrey),
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
                            decoration: BoxDecoration(
                              color: TColors.primary,
                              borderRadius: AppBorderRadius.md,
                            ),
                            padding: AppPadding.h16.add(AppPadding.v4),
                            child: Row(
                              children: [
                                Icon(Icons.expand_circle_down,
                                    size: 18, color: TColors.white),
                                AppSpacing.w16,
                                Expanded(
                                  child: Text(
                                    'Sat, 25/10',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(color: TColors.white),
                                  ),
                                ),
                                PriceText(
                                  title: 'Expense: ',
                                  amount: '5000000',
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
                                          decorationColor: TColors.white),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: cardTopPosition,
              left: 0,
              right: 0,
              child: Container(
                margin: AppPadding.h16,
                height: ResponsiveHelper.getResponsiveHeight(context, 0.19),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppBorderRadius.md,
                  boxShadow: [
                    BoxShadow(
                      color: TColors.primary.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                padding: AppPadding.a8,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TCircularImage(
                          image: TImages.user,
                          height: ResponsiveHelper.getResponsiveHeight(context, 0.07),
                          width: ResponsiveHelper.getResponsiveHeight(context, 0.07),
                        ),
                        AppSpacing.w16,
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.arrow_back_ios,
                                  size: 15, color: TColors.primary),
                              AppSpacing.w16,
                              Row(
                                children: [
                                  Text('10/2025',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                  AppSpacing.w4,
                                  Icon(Icons.arrow_drop_down,
                                      size: 20, color: TColors.primary),
                                ],
                              ),
                              AppSpacing.w8,
                              Icon(Icons.arrow_forward_ios, size: 15),
                              Spacer(),
                              Icon(
                                Iconsax.sms_notification,
                                size: 25,
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.w8,
                        Container(
                          width: 1,
                          height: 20,
                          color: TColors.softGrey,
                        ),
                        AppSpacing.w8,
                        Icon(Iconsax.eye, size: 25),
                      ],
                    ),
                    Divider(color: TColors.softGrey),
                    AppSpacing.h8,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFinancialCard(
                          context,
                          amount: '50000000',
                          label: 'Total',
                          icon: Iconsax.empty_wallet,
                          color: Colors.green,
                        ),
                        _buildDivider(context),
                        _buildFinancialCard(
                          context,
                          amount: '4500000',
                          label: 'Income',
                          icon: Iconsax.arrow_up_1,
                          color: Colors.green,
                        ),
                        _buildDivider(context),
                        _buildFinancialCard(
                          context,
                          amount: '15000000',
                          label: 'Expense',
                          icon: Iconsax.arrow_down_2,
                          color: Colors.red,
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(
    BuildContext context, {
    required String amount,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final iconSize = ResponsiveHelper.getResponsiveIconSize(context, 0.015);
    
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PriceText(amount: amount, color: color),
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
