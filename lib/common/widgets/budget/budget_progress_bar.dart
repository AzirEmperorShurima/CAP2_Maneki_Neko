import 'package:flutter/material.dart';

import '../../../constants/app_border_radius.dart';
import '../../../constants/app_padding.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/colors.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../text/price_text.dart';

/// Component hiển thị progress bar cho budget
enum BudgetProgressBarVariant {
  compact, // Text trong bar (dùng cho home screen)
  full, // Text bên ngoài bar (dùng cho budget screen)
}

class BudgetProgressBar extends StatelessWidget {
  final double amount;
  final double spentAmount;
  final BudgetProgressBarVariant variant;

  const BudgetProgressBar({
    super.key,
    required this.amount,
    required this.spentAmount,
    this.variant = BudgetProgressBarVariant.compact,
  });

  @override
  Widget build(BuildContext context) {
    final progress = amount > 0 ? (spentAmount / amount).clamp(0.0, 1.0) : 0.0;
    final rawPercent = amount > 0 ? (spentAmount / amount) * 100 : 0;
    final percentage = rawPercent.toStringAsFixed(0);

    // Màu tiến trình theo mức độ dùng
    final progressColor = progress >= 1.0
        ? Colors.red
        : progress >= 0.7
            ? Colors.orange
            : TColors.primary;

    /// 🔥 Hàm chọn màu chữ dựa theo nền thực tế
    Color getAdaptiveTextColor(double progress) {
      // Nếu progress vượt 25% thì text nằm trên progressColor
      final Color bg = progress > 0.25 ? progressColor : TColors.softGrey;

      final luminance = bg.computeLuminance();
      return luminance < 0.5 ? Colors.white : Colors.black;
    }

    if (variant == BudgetProgressBarVariant.compact) {
      // Compact: text trong bar
      return Stack(
        children: [
          ClipRRect(
            borderRadius: AppBorderRadius.md,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 15,
              backgroundColor: THelperFunctions.isDarkMode(context) ? TColors.darkerGrey : TColors.softGrey,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: AppPadding.h8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// Spent
                  Flexible(
                    child: PriceText(
                      amount: spentAmount.toString(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: getAdaptiveTextColor(progress),
                            fontSize: 10,
                          ),
                      currencyStyle:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: getAdaptiveTextColor(progress),
                                decoration: TextDecoration.underline,
                                decorationColor: getAdaptiveTextColor(progress),
                                fontSize: 10,
                              ),
                    ),
                  ),

                  AppSpacing.w4,

                  /// Percentage
                  Text(
                    '$percentage%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: getAdaptiveTextColor(progress),
                          fontSize: 10,
                        ),
                  ),

                  AppSpacing.w4,

                  /// Total amount (luôn nằm phần nền xám)
                  Flexible(
                    child: PriceText(
                      amount: amount.toString(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: progress >= 1 ? TColors.white : TColors.black,
                            fontSize: 10,
                          ),
                      currencyStyle:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: progress >= 1 ? TColors.white : TColors.black,
                                decoration: TextDecoration.underline,
                                decorationColor: progress >= 1 ? TColors.white : TColors.black,
                                fontSize: 10,
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Full: text outside bar
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Đã chi tiêu',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              '$percentage%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: progressColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        AppSpacing.h8,
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 18,
            backgroundColor: THelperFunctions.isDarkMode(context) ? TColors.darkerGrey : TColors.softGrey,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
        AppSpacing.h8,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PriceText(amount: spentAmount.toString()),
            PriceText(amount: amount.toString()),
          ],
        ),
      ],
    );
  }
}
