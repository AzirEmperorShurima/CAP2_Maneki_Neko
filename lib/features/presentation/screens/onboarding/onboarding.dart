import 'package:auto_route/auto_route.dart';
import 'package:finance_management_app/routes/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../constants/assets.dart';
import '../../../../constants/text_strings.dart';
import '../../../../utils/utils.dart';
import '../../blocs/onboarding/onboarding_bloc.dart';
import 'widgets/onboarding_dot_navigation.dart';
import 'widgets/onboarding_next_button.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/onboarding_skip_button.dart';

@RoutePage()
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // UI layer quản lý PageController
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    // Dispose PageController ở UI layer
    _pageController.dispose();
    super.dispose();
  }
  

  @override
  Widget build(BuildContext context) {
    // OnboardingBloc đã được provide ở app.dart (global)
    return BlocListener<OnboardingBloc, OnboardingState>(
      // Listener để xử lý side effects (navigation, animations)
      listener: (context, state) {
        if (state is OnboardingCompleted) {
          // Navigation logic ở UI layer, không ở BLoC
          Utils.setIsFirstTime(false);
          AutoRouter.of(context).replace(const LoginScreenRoute());
        } else if (state is OnboardingPageChanged) {
          // Animate PageController khi state thay đổi
          _pageController.animateToPage(
            state.currentPageIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                // Khi user swipe, dispatch event lên BLoC
                context.read<OnboardingBloc>().add(OnboardingPageUpdated(index));
              },
              children: const [
                OnboardingPage(
                  image: Assets.animationOnboarding1,
                  title: TTexts.onBoardingTitle1,
                  subTitle: TTexts.onBoardingSubTitle1,
                  isLottie: true,
                ),
                OnboardingPage(
                  image: Assets.animationOnboarding2,
                  title: TTexts.onBoardingTitle2,
                  subTitle: TTexts.onBoardingSubTitle2,
                  isLottie: true,
                ),
              ],
            ),

            const OnboardingSkipButton(),

            OnboardingDotNavigation(pageController: _pageController),

            const OnboardingNextButton(),
          ],
        ),
      ),
    );
  }
}
