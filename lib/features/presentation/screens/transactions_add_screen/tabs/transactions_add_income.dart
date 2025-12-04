import 'package:flutter/material.dart';

import '../../../../../common/widgets/text/overflow_marquee_text.dart';
import '../../../../../constants/app_border_radius.dart';
import '../../../../../constants/app_padding.dart';
import '../../../../../constants/colors.dart';
import '../../../../../utils/device/device_utility.dart';

class TransactionsAddIncome extends StatefulWidget {
  const TransactionsAddIncome({super.key});

  @override
  State<TransactionsAddIncome> createState() => _TransactionsAddIncomeState();
}

class _TransactionsAddIncomeState extends State<TransactionsAddIncome> {
  int? selectedIndex;

  final items = [
    ItemData('assets/images/icons/money.png', 'Bonus'),
    ItemData('assets/images/icons/salary.png', 'Salary'),
    ItemData('assets/images/icons/investment.png', 'Investment'),
    ItemData('assets/images/icons/part-time.png', 'Part time'),
    ItemData('assets/images/icons/freelancer.png', 'Freelance'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 15,
        mainAxisSpacing: 5,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedIndex == index;

        return GestureDetector(
          onTap: () {
            TDeviceUtils.lightImpact();
            setState(() {
              selectedIndex = index;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: AppBorderRadius.md,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
                width: 2,
              ),
            ),
            padding: AppPadding.a4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: AppPadding.a16,
                    child: Image.asset(
                      item.imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                OverflowMarqueeText(
                  text: item.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? TColors.primary : null,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  height: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ItemData {
  final String imagePath;
  final String title;
  ItemData(this.imagePath, this.title);
}
