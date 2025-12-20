import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../constants/app_border_radius.dart';
import '../../constants/app_padding.dart';
import '../../constants/colors.dart';

/// A widget for displaying an animated loading indicator with optional text and action button.
class TAnimationLoaderWidget extends StatelessWidget {
  /// Default constructor for the TAnimationLoaderWidget.
  ///
  /// Parameters:
  ///   - text: The text to be displayed below the animation.
  ///   - animation: The path to the Lottie animation file.
  ///   - showAction: Whether to show an action button below the text.
  ///   - actionText: The text to be displayed on the action button.
  ///   - onActionPressed: Callback function to be executed when the action button is pressed.
  final String text;

  final TextStyle? textStyle;

  final String animation;

  final bool showAction;

  final String? actionText;

  final VoidCallback? onActionPressed;

  final double? width;

  final double? height;

  final String? message;

  const TAnimationLoaderWidget({
    super.key,
    required this.text,
    this.textStyle,
    required this.animation,
    this.showAction = false,
    this.actionText,
    this.onActionPressed,
    this.width,
    this.height,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Lottie.asset(
              animation,
              width: width ?? MediaQuery.of(context).size.width * 0.5,
              height: height ?? MediaQuery.of(context).size.height * 0.5,
            ),
            Text(
              text,
              style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (showAction)
              TextButton(
                  onPressed: onActionPressed,
                  child: Text(
                    actionText!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .apply(color: TColors.primary),
                  ))
            else
              const SizedBox(),
          ],
        ),
        if (message != null)
          Positioned(
            top: 0,
            right: 0,
            left: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: TColors.white,
                boxShadow: [
                  BoxShadow(
                    color: TColors.grey,
                    blurRadius: 2,
                    spreadRadius: 1,
                    offset: Offset.zero,
                  ),
                ],
                borderRadius: AppBorderRadius.md,
              ),
              padding: AppPadding.a8,
              margin: AppPadding.h16,
              child: Text(
                message!,
                style: Theme.of(context).textTheme.labelLarge,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          )
      ],
    );
  }
}
