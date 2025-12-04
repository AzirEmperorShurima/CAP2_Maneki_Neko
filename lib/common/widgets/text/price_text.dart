import 'package:finance_management_app/utils/formatters/formatter.dart';
import 'package:flutter/material.dart';

class PriceText extends StatelessWidget {
  final String amount;

  final Color? color;

  final String? title;

  final TextStyle? style;

  final TextStyle? currencyStyle;

  const PriceText({
    super.key,
    this.title,
    required this.amount,
    this.color,
    this.style,
    this.currencyStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          if (title != null)
            TextSpan(
              text: title,
              style: style ?? Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: color,
                    decorationColor: color,
                  ),
            ),
          TextSpan(
            text: 'đ',
            style: currencyStyle ?? Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: color,
                ),
          ),
          TextSpan(
            text: TFormatter.formatVietnameseNumber(amount),
            style: style ?? Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
