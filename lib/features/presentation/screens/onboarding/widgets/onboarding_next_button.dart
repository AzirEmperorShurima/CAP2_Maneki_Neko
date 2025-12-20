import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../constants/colors.dart';
import '../../../../../constants/sizes.dart';
import '../../../../../utils/device/device_utility.dart';
import '../../../blocs/onboarding/onboarding_bloc.dart';

class OnboardingNextButton extends StatelessWidget {
  // Không cần pass bloc qua props
  const OnboardingNextButton({super.key});

  @override
  Widget build(BuildContext context) {
    // BlocBuilder để rebuild khi state thay đổi
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        // Lấy currentIndex từ state, default 0 nếu không phải OnboardingPageChanged
        final currentIndex = state is OnboardingPageChanged ? state.currentPageIndex : 0;
        
          return Positioned(
            right: TSizes.defaultSpace + 2,
            bottom: TDeviceUtils.getBottomNavigationBarHeight(),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: TColors.primary,
                elevation: 5,
                shadowColor: TColors.primary.withOpacity(0.5) 
              ),
              onPressed: () {
              // Dispatch event qua context.read()
              context.read<OnboardingBloc>().add(OnboardingNextPressed());
              },
            child: currentIndex == 1
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: TSizes.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Get Started'),
                          SizedBox(width: TSizes.sm),
                          Icon(
                            Iconsax.arrow_right_3,
                            color: TColors.white,
                          ),
                        ],
                      ),
                    )
                  : const Padding(
                      padding: EdgeInsets.symmetric(horizontal: TSizes.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Continue'),
                          SizedBox(width: TSizes.sm),
                          Icon(
                            Iconsax.arrow_right_3,
                            color: TColors.white,
                          ),
                        ],
                      ),
                    ),
            ),
          );
      },
    );
  }
}
