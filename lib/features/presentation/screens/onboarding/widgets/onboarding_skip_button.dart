import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../constants/sizes.dart';
import '../../../../../utils/device/device_utility.dart';
import '../../../blocs/onboarding/onboarding_bloc.dart';

class OnboardingSkipButton extends StatelessWidget {
  // Không cần pass bloc qua props
  const OnboardingSkipButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: TDeviceUtils.getAppBarHeight(),
      right: TSizes.defaultSpace,
      child: TextButton(
        onPressed: () {
          // Dùng context.read() để access bloc từ BlocProvider
          context.read<OnboardingBloc>().add(OnboardingSkipPressed());
        },
        child: Text(
          'Skip',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).primaryColor,
              ),
        ),
      ),
    );
  }
}
