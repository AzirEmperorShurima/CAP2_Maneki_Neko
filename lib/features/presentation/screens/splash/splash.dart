

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../constants/app_spacing.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/image_strings.dart';
import '../../../../constants/text_strings.dart';
import '../../../../utils/utils.dart';

@RoutePage()
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    moveToOnboarding();
    super.initState();
  }

  moveToOnboarding() async {
    await Future.delayed(Duration(seconds: 2), () {
      if (!mounted) return;
      Utils.screenRedirect(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadedScaleAnimation(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(TImages.logo, height: 48, width: 48),
              AppSpacing.w4,
              Text(
                TTexts.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: TColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
