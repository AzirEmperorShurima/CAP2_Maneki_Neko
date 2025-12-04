import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  // Tổng số trang onboarding
  static const int totalPages = 2;
  
  // Initial state là page 0
  OnboardingBloc() : super(OnboardingPageChanged(0)) {
    on<OnboardingPageUpdated>(_onPageUpdated);
    on<OnboardingNextPressed>(_onNextPressed);
    on<OnboardingSkipPressed>(_onSkipPressed);
  }

  // Handler khi user swipe/click để đổi page
  void _onPageUpdated(OnboardingPageUpdated event, Emitter<OnboardingState> emit) {
    emit(OnboardingPageChanged(event.index));
  }

  // Handler khi user click Next button
  void _onNextPressed(OnboardingNextPressed event, Emitter<OnboardingState> emit) {
    if (state is OnboardingPageChanged) {
      final currentState = state as OnboardingPageChanged;
      final nextIndex = currentState.currentPageIndex + 1;
      
      // Nếu chưa đến trang cuối, chuyển sang trang tiếp theo
      if (nextIndex < totalPages) {
        emit(OnboardingPageChanged(nextIndex));
      } else {
        // Đã đến trang cuối, emit OnboardingCompleted để UI navigate
        emit(OnboardingCompleted());
    }
  }
  }

  // Handler khi user click Skip button
  void _onSkipPressed(OnboardingSkipPressed event, Emitter<OnboardingState> emit) {
    // Skip thẳng đến màn home
    emit(OnboardingCompleted());
  }
}