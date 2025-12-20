import 'package:flutter/material.dart';

import '../../constants/app_border_radius.dart';
import '../../constants/app_padding.dart';
import '../../constants/colors.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({
    super.key,
    this.dotColor,
    this.backgroundColor,
    this.dotSize = 9,
  });

  final Color? dotColor;
  final Color? backgroundColor;
  final double dotSize;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _dotAnimations = List.generate(3, (index) {
      final start = index * 0.15;
      final end = start + 0.6;

      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0, end: -6)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: -6, end: 0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.linear),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.dotColor ?? TColors.grey;
    final backgroundColor = widget.backgroundColor ?? TColors.softGrey;

    return Container(
      margin: AppPadding.v4,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppBorderRadius.md.copyWith(
          topLeft: Radius.zero,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (index) => AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return Transform.translate(
                offset: Offset(0, _dotAnimations[index].value),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
