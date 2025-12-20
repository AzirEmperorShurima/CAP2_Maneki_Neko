import 'package:finance_management_app/constants/app_border_radius.dart';
import 'package:finance_management_app/constants/app_padding.dart';
import 'package:finance_management_app/constants/app_spacing.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:finance_management_app/utils/popups/loaders.dart';
import 'package:flutter/material.dart';

/// Widget tái sử dụng để hiển thị wallet type picker trong bottom sheet
class WalletTypePickerBottomSheet extends StatelessWidget {
  /// Type đã được chọn
  final String? selectedType;

  /// Callback khi type được chọn
  final Function(String type, String typeName)? onTypeSelected;

  const WalletTypePickerBottomSheet({
    super.key,
    this.selectedType,
    this.onTypeSelected,
  });

  /// Hàm helper để hiển thị wallet type picker bottom sheet
  static Future<void> show({
    required BuildContext context,
    String? selectedType,
    Function(String type, String typeName)? onTypeSelected,
  }) {
    return TLoaders.bottomSheet(
      context: context,
      borderRadius: AppBorderRadius.md,
      child: WalletTypePickerBottomSheet(
        selectedType: selectedType,
        onTypeSelected: onTypeSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Chọn loại ví tiền',
            style: Theme.of(context).textTheme.titleLarge),
        const Divider(color: TColors.softGrey),
        AppSpacing.h8,
        Padding(
          padding: AppPadding.h16,
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  onTypeSelected?.call('Tiền mặt', 'Ví tiền mặt');
                  Navigator.of(context).pop();
                },
                child: Row(
                  children: [
                    Image.asset('assets/images/icons/money.png',
                        height: 40, width: 40),
                    AppSpacing.w16,
                    Text('Ví tiền mặt',
                        style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
              const Divider(color: TColors.softGrey),
              GestureDetector(
                onTap: () {
                  onTypeSelected?.call('Tiết kiệm', 'Ví tiết kiệm');
                  Navigator.of(context).pop();
                },
                child: Row(
                  children: [
                    Image.asset('assets/images/icons/savings.png',
                        height: 40, width: 40),
                    AppSpacing.w16,
                    Text('Ví tiết kiệm',
                        style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
              const Divider(color: TColors.softGrey),
              GestureDetector(
                onTap: () {
                  onTypeSelected?.call('Tín dụng', 'Ví tín dụng');
                  Navigator.of(context).pop();
                },
                child: Row(
                  children: [
                    Image.asset('assets/images/icons/atm-card.png',
                        height: 40, width: 40),
                    AppSpacing.w16,
                    Text('Ví tín dụng',
                        style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
              const Divider(color: TColors.softGrey),
              GestureDetector(
                onTap: () {
                  onTypeSelected?.call('Tài khoản ảo', 'Ví tài khoản ảo');
                  Navigator.of(context).pop();
                },
                child: Row(
                  children: [
                    Image.asset('assets/images/icons/bitcoin.png',
                        height: 40, width: 40),
                    AppSpacing.w16,
                    Text('Ví tài khoản ảo',
                        style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
              const Divider(color: TColors.softGrey),
              GestureDetector(
                onTap: () {
                  onTypeSelected?.call('Đầu tư', 'Ví đầu tư');
                  Navigator.of(context).pop();
                },
                child: Row(
                  children: [
                    Image.asset('assets/images/icons/investment.png',
                        height: 40, width: 40),
                    AppSpacing.w16,
                    Text('Ví đầu tư',
                        style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
              const Divider(color: TColors.softGrey),
              GestureDetector(
                onTap: () {
                  onTypeSelected?.call('Ví nợ', 'Ví nợ');
                  Navigator.of(context).pop();
                },
                child: Row(
                  children: [
                    Image.asset('assets/images/icons/debt.png',
                        height: 40, width: 40),
                    AppSpacing.w16,
                    Text('Ví nợ',
                        style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
              const Divider(color: TColors.softGrey),
            ],
          ),
        )
      ],
    );
  }
}
