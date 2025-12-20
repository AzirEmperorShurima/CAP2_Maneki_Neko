import 'package:finance_management_app/constants/colors.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_spacing.dart';
import 'bordered_container.dart';

class BorderedTextField extends StatelessWidget {
  final String title;

  final TextEditingController? controller;

  final String hintText;

  final bool obscureText;

  final VoidCallback? onTogglePassword;

  final bool showPassword;

  final Widget? button;

  final TextStyle? titleStyle;

  final TextStyle? hintStyle;

  final bool isRequired;

  final double? borderRadius;

  final String? assetIcon;

  const BorderedTextField({
    super.key,
    required this.title,
    this.controller,
    required this.hintText,
    this.obscureText = false,
    this.onTogglePassword,
    this.showPassword = false,
    this.button,
    this.titleStyle,
    this.hintStyle,
    this.isRequired = false,
    this.borderRadius,
    this.assetIcon,
  });

  @override
  Widget build(BuildContext context) {
    return BorderedContainer(
      borderRadius: borderRadius ?? 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (assetIcon != null) ...[
            Image.asset(assetIcon!, height: 40, width: 40),
            AppSpacing.w16,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RichText(
                      text: TextSpan(
                        text: title,
                        style: titleStyle ??
                            Theme.of(context).textTheme.titleLarge,
                        children: [
                          if (isRequired)
                            TextSpan(
                              text: ' *',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Colors.red),
                            )
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.h4,
                TextField(
                  controller: controller,
                  obscureText: obscureText,
                  style: Theme.of(context).textTheme.bodySmall,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: hintText,
                    hintStyle: hintStyle ??
                        Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: TColors.grey),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    labelStyle: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          if (button != null) button!,
        ],
      ),
    );
  }
}
