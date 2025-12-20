part of 'onboarding_bloc.dart';

@immutable
sealed class OnboardingEvent {}

// Event khi user swipe/click để đổi page
class OnboardingPageUpdated extends OnboardingEvent {
  final int index;
  OnboardingPageUpdated(this.index);
}

// Event khi user click Next button
class OnboardingNextPressed extends OnboardingEvent {}

// Event khi user click Skip button
class OnboardingSkipPressed extends OnboardingEvent {} 