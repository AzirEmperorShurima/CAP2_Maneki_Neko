import 'package:flutter/material.dart';

import '../../../../../common/api_builder/category_builder.dart';
import '../../../../../common/widgets/error/error_widget.dart';
import '../../../../../common/widgets/profile/t_circular_image.dart';
import '../../../../../common/widgets/text/overflow_marquee_text.dart';
import '../../../../../constants/app_border_radius.dart';
import '../../../../../constants/app_padding.dart';
import '../../../../../constants/colors.dart';
import '../../../../../utils/device/device_utility.dart';
import '../../../../../utils/loaders/category_loading.dart';

class TransactionsAddExpense extends StatefulWidget {
  final Function(String?)? onCategorySelected;
  final String? initialCategoryId;

  const TransactionsAddExpense({
    super.key,
    this.onCategorySelected,
    this.initialCategoryId,
  });

  @override
  State<TransactionsAddExpense> createState() => _TransactionsAddExpenseState();
}

class _TransactionsAddExpenseState extends State<TransactionsAddExpense> {
  String? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    selectedCategoryId = widget.initialCategoryId;
    if (widget.initialCategoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onCategorySelected?.call(widget.initialCategoryId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CategoryBuilder(
      type: 'expense',
      loadingBuilder: (context) => const CategoryGridLoading(),
      errorBuilder: (context, message, onRetry) => TErrorWidget(
        height: 200,
        message: message,
        onRetry: onRetry,
      ),
      builder: (context, categories) {
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 5,
            childAspectRatio: 0.8,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = selectedCategoryId == category.id;

            return GestureDetector(
              onTap: () {
                TDeviceUtils.lightImpact();
                setState(() {
                  selectedCategoryId = category.id;
                });
                widget.onCategorySelected?.call(category.id);
              },
              child: Container(
                decoration: BoxDecoration(
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
                        child: TCircularImage(
                          image: category.image ?? '',
                          isNetworkImage: category.image?.isNotEmpty == true,
                          width: 60,
                          height: 60,
                          borderRadius: BorderRadius.circular(0),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    OverflowMarqueeText(
                      text: category.name ?? 'Không có tên',
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
      },
    );
  }
}
