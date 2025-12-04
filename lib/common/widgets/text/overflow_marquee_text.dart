import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class OverflowMarqueeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double height;
  final double blankSpace;
  final double velocity;
  final Duration pauseAfterRound;
  final Alignment alignment;

  const OverflowMarqueeText({
    super.key,
    required this.text,
    this.style,
    this.height = 18.0,
    this.blankSpace = 24.0,
    this.velocity = 25.0,
    this.pauseAfterRound = const Duration(milliseconds: 800),
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final effectiveStyle = style ?? const TextStyle(fontSize: 14);

          final textPainter = TextPainter(
            text: TextSpan(text: text, style: effectiveStyle),
            maxLines: 1,
            textDirection: TextDirection.ltr,
            ellipsis: '…',
          )..layout(minWidth: 0, maxWidth: constraints.maxWidth);

          final isOverflow = textPainter.didExceedMaxLines;

          if (isOverflow) {
            return Marquee(
              text: text,
              scrollAxis: Axis.horizontal,
              blankSpace: blankSpace,
              velocity: velocity,
              startPadding: 0.0,
              pauseAfterRound: pauseAfterRound,
              style: effectiveStyle,
            );
          }

          return Align(
            alignment: alignment,
            child: Text(
              text,
              style: effectiveStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    );
  }
}


