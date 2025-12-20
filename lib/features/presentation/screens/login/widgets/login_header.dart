import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../../constants/app_spacing.dart';
import '../../../../../constants/assets.dart';
import '../../../../../constants/sizes.dart';
import '../../../../../constants/text_strings.dart';

class TLoginHeader extends StatelessWidget {
  const TLoginHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image
        SizedBox(
          height: 150,
          child: Lottie.asset(
            Assets.animationCatLoginScreen,
            fit: BoxFit.contain,
          ),
        ),

        AppSpacing.h16,

        // Title
        Text(
          TTexts.loginTitle,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(
          height: TSizes.sm,
        ),

        // SubTitle
        Text(
          TTexts.loginSubTitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
