import 'package:auto_route/auto_route.dart';
import 'package:finance_management_app/constants/app_border_radius.dart';
import 'package:finance_management_app/constants/app_padding.dart';
import 'package:finance_management_app/constants/app_spacing.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:finance_management_app/routes/router.gr.dart';
import 'package:finance_management_app/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CreateFirstWalletDialog extends StatelessWidget {
  const CreateFirstWalletDialog({super.key});

  static Future<void> show({
    required BuildContext context,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const CreateFirstWalletDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.lg,
      ),
      child: Container(
        padding: AppPadding.a24,
        decoration: BoxDecoration(
          color: isDark ? TColors.darkContainer : Colors.white,
          borderRadius: AppBorderRadius.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: TColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.wallet_3,
                size: 40,
                color: TColors.primary,
              ),
            ),
            AppSpacing.h24,

            // Title
            Text(
              'Chào mừng bạn!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.h16,

            // Message
            Text(
              'Để bắt đầu quản lý tài chính, bạn cần tạo ví đầu tiên của mình. Ví sẽ giúp bạn theo dõi thu chi một cách hiệu quả.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? TColors.lightGrey : TColors.darkerGrey,
                  ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.h24,

            // Buttons
            Row(
              children: [
                // Tạo ví ngay
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      AutoRouter.of(context).push(WalletAddScreenRoute());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary,
                      padding: AppPadding.v16,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppBorderRadius.md,
                      ),
                    ),
                    child: const Text(
                      'Tạo ví ngay',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
