import 'package:finance_management_app/constants/app_spacing.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:flutter/material.dart';


class TabSwitcher extends StatelessWidget {
  final List<String> tabs;

  final int selectedIndex;

  final ValueChanged<int> onTabSelected;

  final TextStyle? textStyle;

  final EdgeInsetsGeometry? padding;

  final List<String>? iconPaths;

  final Color? backgroundColor;

  final Color? isSelectedColors;

  final Color? isUnSelectedColors;

  final Color? isSelectedTextColors;

  final Color? isUnSelectedTextColors;

  final BorderRadius? borderRadius;

  const TabSwitcher({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.textStyle,
    this.padding,
    this.iconPaths,
    this.backgroundColor,
    this.isSelectedColors,
    this.isUnSelectedColors,
    this.isSelectedTextColors,
    this.isUnSelectedTextColors,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor ?? TColors.primary,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
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
                    color: isSelected
                        ? isSelectedColors ?? Colors.white
                        : isUnSelectedColors ?? TColors.primary,
                    borderRadius: borderRadius ?? BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Tooltip(
                    message: tabs[index],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // only show icon if iconPaths provided and index valid
                        if (iconPaths != null &&
                            index < iconPaths!.length &&
                            iconPaths![index].isNotEmpty) ...[
                          Image.asset(
                            iconPaths![index],
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                          ),
                          AppSpacing.w8,
                        ],
                        Flexible(
                          child: Text(
                            tabs[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            textAlign: TextAlign.center,
                            style: textStyle ??
                                Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      color: isSelected
                                          ? isSelectedTextColors ?? Colors.black
                                          : isUnSelectedTextColors ??
                                              Colors.white,
                                    ),
                          ),
                        ),
                      ],
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
