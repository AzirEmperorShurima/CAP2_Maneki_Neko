import 'package:flutter/material.dart';

import '../../constants/app_border_radius.dart';
import '../../constants/app_padding.dart';
import '../../constants/colors.dart';

/// Skeleton loading widget for category grid
/// Displays skeleton version of category items while data is loading
class CategoryGridLoading extends StatelessWidget {
  const CategoryGridLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 15,
        mainAxisSpacing: 5,
        childAspectRatio: 0.8,
      ),
      itemCount: 12, // Hiển thị 12 skeleton items
      itemBuilder: (context, index) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
            borderRadius: AppBorderRadius.md,
          ),
          padding: AppPadding.a4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: AppPadding.a16,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: AppBorderRadius.sm,
                      color: TColors.primary.withOpacity(0.1),
                    ),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: TColors.grey.withOpacity(0.3),
                          borderRadius: AppBorderRadius.sm,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 18,
                width: 60,
                decoration: BoxDecoration(
                  color: TColors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

