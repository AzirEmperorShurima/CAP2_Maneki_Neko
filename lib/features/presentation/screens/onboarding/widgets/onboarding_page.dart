import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../../constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.subTitle,
    this.isLottie = false,
  });

  final String image, title, subTitle;
  final bool isLottie;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Column(
        children: [
          // Image or Lottie Animation
          isLottie
              ? Lottie.asset(
                  image,
                  width: THelperFunctions.screenWidth(context),
                  height: THelperFunctions.screenHeight(context) * 0.65,
                )
              : Image(
                  width: THelperFunctions.screenWidth(context),
                  height: THelperFunctions.screenHeight(context) * 0.65,
                  image: AssetImage(image),
                ),

          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: TSizes.spaceBtwItems),

          // SubTitle
          Text(
            subTitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
