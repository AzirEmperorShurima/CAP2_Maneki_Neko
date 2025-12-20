import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../constants/app_border_radius.dart';
import '../../../constants/app_padding.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/colors.dart';
import '../../../routes/router.gr.dart';
import '../../../utils/popups/loaders.dart';
import 'join_family_bottom_sheet.dart';

class FamilyOptionBottomSheet extends StatelessWidget {
  const FamilyOptionBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return TLoaders.bottomSheet(
      context: context,
      heightPercentage: 0.45,
      borderRadius: AppBorderRadius.md,
      child: const FamilyOptionBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: AppPadding.a16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Tạo hoặc tham gia gia đình',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Iconsax.close_circle),
                ),
              ],
            ),
            AppSpacing.h24,
            // Option 1: Tạo gia đình
            _buildOptionItem(
              context,
              icon: Iconsax.add_square,
              title: 'Tạo gia đình mới',
              description: 'Tạo một gia đình mới và trở thành quản lý',
              onTap: () {
                Navigator.of(context).pop();
                AutoRouter.of(context).push(const FamilyAddScreenRoute());
              },
            ),
            AppSpacing.h16,
            const Divider(color: TColors.softGrey),
            AppSpacing.h16,
            // Option 2: Tham gia gia đình
            _buildOptionItem(
              context,
              icon: Iconsax.login,
              title: 'Tham gia gia đình',
              description: 'Tham gia gia đình bằng mã mời',
              onTap: () {
                Navigator.of(context).pop();
                JoinFamilyBottomSheet.show(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: AppPadding.a16,
        decoration: BoxDecoration(
          color: TColors.softGrey,
          borderRadius: AppBorderRadius.md,
        ),
        child: Row(
          children: [
            Container(
              padding: AppPadding.a8,
              decoration: BoxDecoration(
                color: TColors.primary.withOpacity(0.1),
                borderRadius: AppBorderRadius.sm,
              ),
              child: Icon(
                icon,
                color: TColors.primary,
                size: 24,
              ),
            ),
            AppSpacing.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  AppSpacing.h4,
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: TColors.darkerGrey,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Iconsax.arrow_right_3,
              color: TColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
