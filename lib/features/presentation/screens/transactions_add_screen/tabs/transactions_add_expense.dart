import 'package:finance_management_app/constants/app_border_radius.dart';
import 'package:finance_management_app/constants/app_padding.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:flutter/material.dart';
// marquee is used inside OverflowMarqueeText, not directly here
import 'package:finance_management_app/common/widgets/text/overflow_marquee_text.dart';

import '../../../../../utils/device/device_utility.dart';

class TransactionsAddExpense extends StatefulWidget {
  const TransactionsAddExpense({super.key});

  @override
  State<TransactionsAddExpense> createState() => _TransactionsAddExpenseState();
}

class _TransactionsAddExpenseState extends State<TransactionsAddExpense> {
  int? selectedIndex;

  final items = [
    ItemData('assets/images/icons/food.png', 'Food'),
    ItemData('assets/images/icons/daily.png', 'Daily'),
    ItemData('assets/images/icons/traffic.png', 'Traffic'),
    ItemData('assets/images/icons/beer.png', 'Social'),
    ItemData('assets/images/icons/house.png', 'Housing'),
    ItemData('assets/images/icons/box.png', 'Gift'),
    ItemData('assets/images/icons/phone.png', 'Phone'),
    ItemData('assets/images/icons/clothes.png', 'Clothes'),
    ItemData('assets/images/icons/entertaiment.png', 'Relax'),
    ItemData('assets/images/icons/cosmetics.png', 'Beauty'),
    ItemData('assets/images/icons/health.png', 'Health'),
    ItemData('assets/images/icons/tax.png', 'Tax'),
    // ItemData('assets/images/icons/education.png', 'Education'),
    // ItemData('assets/images/icons/baby.png', 'Baby'),
    // ItemData('assets/images/icons/pet.png', 'Pet'),
    // ItemData('assets/images/icons/travel.png', 'Travel'),
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
