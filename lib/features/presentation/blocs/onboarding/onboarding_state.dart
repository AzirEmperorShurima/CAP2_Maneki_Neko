part of 'onboarding_bloc.dart';

@immutable
sealed class OnboardingState extends Equatable {
  @override
  List<Object?> get props => [];
}

// State chỉ chứa page index, không chứa PageController
class OnboardingPageChanged extends OnboardingState {
  final int currentPageIndex;
  
  OnboardingPageChanged(this.currentPageIndex);
  
  @override
  List<Object?> get props => [currentPageIndex];
}

// State khi hoàn thành onboarding để trigger navigation
class OnboardingCompleted extends OnboardingState {} 