import 'package:finance_management_app/common/api_builder/wallet_builder.dart';
import 'package:finance_management_app/common/widgets/card/wallet_card.dart';
import 'package:finance_management_app/constants/app_border_radius.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:finance_management_app/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Widget tái sử dụng để hiển thị wallet picker trong bottom sheet
class WalletPickerBottomSheet extends StatelessWidget {
  /// ID của wallet đã được chọn
  final String? selectedWalletId;

  /// Callback khi wallet được chọn
  final Function(String)? onWalletSelected;

  const WalletPickerBottomSheet({
    super.key,
    this.selectedWalletId,
    this.onWalletSelected,
  });

  /// Hàm helper để hiển thị wallet picker bottom sheet
  static Future<void> show({
    required BuildContext context,
    String? selectedWalletId,
    Function(String)? onWalletSelected,
  }) {
    return TLoaders.bottomSheet(
      context: context,
      heightPercentage: 0.7,
      borderRadius: AppBorderRadius.md,
      child: WalletPickerBottomSheet(
        selectedWalletId: selectedWalletId,
        onWalletSelected: onWalletSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Chọn ví tiền',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Divider(color: TColors.softGrey),
        Expanded(
          child: WalletBuilder(
            autoLoad: true,
            itemBuilder: (context, wallet, index) {
              final isSelected = selectedWalletId == wallet.id;
              return GestureDetector(
                onTap: () {
                  onWalletSelected?.call(wallet.id ?? '');
                  Navigator.of(context).pop();
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    WalletCard(wallet: wallet),
                    if (isSelected)
                      Positioned(
                        top: 5,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: TColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Iconsax.tick_circle,
                            color: TColors.white,
                            size: 25,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
