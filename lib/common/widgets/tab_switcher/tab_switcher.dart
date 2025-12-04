import 'package:finance_management_app/constants/colors.dart';
import 'package:flutter/material.dart';

class TabSwitcher extends StatelessWidget {
  final List<String> tabs;

  final int selectedIndex;

  final ValueChanged<int> onTabSelected;

  final TextStyle? textStyle;

  final EdgeInsetsGeometry? padding;

  const TabSwitcher({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.textStyle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedIndex == index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < tabs.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: () => onTabSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: padding ??
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : TColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Tooltip(
                    message: tabs[index],
                    child: Text(
                      tabs[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: textStyle ?? Theme.of(context).textTheme.titleMedium!.copyWith(color: isSelected ? Colors.black : Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
