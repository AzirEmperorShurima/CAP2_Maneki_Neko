import 'package:finance_management_app/common/widgets/text/overflow_marquee_text.dart';
import 'package:finance_management_app/utils/formatters/formatter.dart';
import 'package:flutter/material.dart';

class PriceText extends StatelessWidget {
  final String amount;

  final Color? color;

  final String? title;

  final TextStyle? style;

  final TextStyle? currencyStyle;

  final double? height;

  const PriceText({
    super.key,
    this.title,
    required this.amount,
    this.color,
    this.style,
    this.currencyStyle,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final formattedAmount = TFormatter.formatVietnameseNumber(amount);
    final fullText = '${title ?? ''}đ$formattedAmount';

    final defaultStyle = style ??
        Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            );

    final defaultCurrencyStyle = currencyStyle ??
        Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: color,
            );

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textPainter = TextPainter(
            text: TextSpan(
              children: [
                if (title != null)
                  TextSpan(
                    text: title,
                    style: style ??
                        Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: color,
                              decorationColor: color,
                            ),
                  ),
                TextSpan(
                  text: 'đ',
                  style: defaultCurrencyStyle,
                ),
                TextSpan(
                  text: formattedAmount,
                  style: defaultStyle,
                ),
              ],
            ),
            maxLines: 1,
            textDirection: TextDirection.ltr,
            ellipsis: '…',
          )..layout(minWidth: 0, maxWidth: constraints.maxWidth);

          final isOverflow = textPainter.didExceedMaxLines;

          if (isOverflow) {
            return OverflowMarqueeText(
              text: fullText,
              style: defaultStyle,
              height: height ?? 18.0,
            );
          }

          return Text.rich(
            TextSpan(
              children: [
                if (title != null)
                  TextSpan(
                    text: title,
                    style: style ??
                        Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: color,
                              decorationColor: color,
                            ),
                  ),
                TextSpan(
                  text: 'đ',
                  style: defaultCurrencyStyle,
                ),
                TextSpan(
                  text: formattedAmount,
                  style: defaultStyle,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
