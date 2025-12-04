import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../constants/colors.dart';
import '../../../constants/sizes.dart';
import '../../../utils/device/device_utility.dart';
import '../../../utils/helpers/helper_functions.dart';

class TAppbar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;

  final bool showBackArrow;

  final IconData? leadingIcon;

  final List<Widget>? actions;

  final VoidCallback? leadingOnPressed;

  final bool centerTitle;

  final double paddingTitle;

  final Color colorBackArrow;

  final Color? backgroundColor;

  final double? leadingIconSize;

  final Color? leadingIconColor;

  const TAppbar({
    super.key,
    this.title,
    this.showBackArrow = false,
    this.leadingIcon,
    this.actions,
    this.leadingOnPressed,
    this.centerTitle = false,
    this.paddingTitle = TSizes.md,
    this.colorBackArrow = TColors.black,
    this.backgroundColor,
    this.leadingIconSize,
    this.leadingIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    return AppBar(
      automaticallyImplyLeading: false,
      leading: showBackArrow
          ? IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Iconsax.arrow_left,
                  color: isDarkMode ? TColors.white : TColors.black))
          : leadingIcon != null
              ? IconButton(
                  onPressed: leadingOnPressed,
                  icon: Icon(
                    leadingIcon,
                    size: leadingIconSize,
                    color: leadingIconColor,
                  ),
                )
              : null,
      title: title,
      actions: actions,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(TDeviceUtils.getAppBarHeight());
}
