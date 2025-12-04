import 'package:finance_management_app/common/widgets/svg_view/svg_view.dart';
import 'package:finance_management_app/constants/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../constants/colors.dart';
import '../../../constants/image_strings.dart';
import 'appbar.dart';
import 'notification_menu_icon.dart';

class THomeAppBar extends StatelessWidget {
  final bool iconSecurityActionAppbar;

  final bool showActionButtonAppbar;

  final bool centerAppbar;

  final bool showBackArrow;

  final bool centerTitle;

  final VoidCallback? actionButtonOnPressed;

  final Color? backgroundColor;

  const THomeAppBar({
    super.key,
    this.iconSecurityActionAppbar = false,
    this.showActionButtonAppbar = true,
    this.centerAppbar = false,
    this.showBackArrow = false,
    this.centerTitle = false,
    this.actionButtonOnPressed,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {

    return TAppbar(
      showBackArrow: showBackArrow,
      backgroundColor: backgroundColor ?? TColors.primary,
      title: Row(
        mainAxisAlignment:
            centerAppbar ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          SvgView(
            TImages.logoSVG,
            width: 60,
            height: 50,
            color: TColors.white,
          ),
          AppSpacing.w8,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Have a nice evening!',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium!
                    .apply(color: TColors.white),
              ),
              Text(
                'Gia Bao',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall!
                    .apply(color: TColors.white),
              ),
            ],
          ),
        ],
      ),
      actions: showActionButtonAppbar
          ? [
              TActionAppbarIcon(
                icon: Iconsax.calendar5,
                iconColor: TColors.white,
                onPressed: actionButtonOnPressed ?? () {},
              ),
            ]
          : [],
    );
  }
}
