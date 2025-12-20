import 'package:finance_management_app/constants/colors.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_padding.dart';

class BorderedContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;
  final double? width;

  const BorderedContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 10,
    this.borderColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor ?? TColors.grey,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: padding ?? AppPadding.a16,
      child: child,
    );
  }
} 