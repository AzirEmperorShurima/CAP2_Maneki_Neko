
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../../constants/colors.dart';
import '../../../../../constants/sizes.dart';
import '../../../../../utils/device/device_utility.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../blocs/onboarding/onboarding_bloc.dart';

class OnboardingDotNavigation extends StatelessWidget {
  // PageController từ parent (UI layer), không từ BLoC
  const OnboardingDotNavigation({super.key, required this.pageController});
  final PageController pageController;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
          return Positioned(
            bottom: TDeviceUtils.getBottomNavigationBarHeight(),
            left: TSizes.defaultSpace,
            child: SmoothPageIndicator(
        // PageController từ UI layer
        controller: pageController,
              onDotClicked: (index) {
          // Khi user click dot, dispatch event lên BLoC
          context.read<OnboardingBloc>().add(OnboardingPageUpdated(index));
              },
              count: 2,
              effect: ExpandingDotsEffect(
                activeDotColor: dark ? TColors.primary : TColors.primary,
                dotHeight: 9,
              ),
            ),
    );
  }
}
