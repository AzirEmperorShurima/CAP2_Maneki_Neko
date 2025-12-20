import 'package:finance_management_app/constants/app_border_radius.dart';
import 'package:finance_management_app/constants/app_padding.dart';
import 'package:finance_management_app/constants/app_spacing.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:finance_management_app/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Widget tái sử dụng để hiển thị member picker trong bottom sheet
class MemberPickerBottomSheet extends StatelessWidget {
  /// Type đã được chọn
  final String? selectedType;

  /// Callback khi member được chọn
  final Function(String type, String typeName)? onMemberSelected;

  const MemberPickerBottomSheet({
    super.key,
    this.selectedType,
    this.onMemberSelected,
  });

  /// Hàm helper để hiển thị member picker bottom sheet
  static Future<void> show({
    required BuildContext context,
    String? selectedType,
    Function(String type, String typeName)? onMemberSelected,
  }) {
    return TLoaders.bottomSheet(
      context: context,
      heightPercentage: 0.55,
      borderRadius: AppBorderRadius.md,
      child: MemberPickerBottomSheet(
        selectedType: selectedType,
        onMemberSelected: onMemberSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Chọn thành viên',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Divider(color: TColors.softGrey),
        AppSpacing.h8,
        Expanded(
          child: Padding(
            padding: AppPadding.h8,
            child: Column(
              children: [
                _buildMemberItem(
                  context,
                  icon: 'assets/images/icons/me.png',
                  label: 'Tôi',
                  type: 'Tôi',
                  typeName: 'Tôi',
                ),
                const Divider(color: TColors.softGrey),
                _buildMemberItem(
                  context,
                  icon: 'assets/images/icons/wife.png',
                  label: 'Vợ',
                  type: 'Vợ',
                  typeName: 'Vợ',
                ),
                const Divider(color: TColors.softGrey),
                _buildMemberItem(
                  context,
                  icon: 'assets/images/icons/husband.png',
                  label: 'Chồng',
                  type: 'Chồng',
                  typeName: 'Chồng',
                ),
                const Divider(color: TColors.softGrey),
                _buildMemberItem(
                  context,
                  icon: 'assets/images/icons/baby.png',
                  label: 'Con cái',
                  type: 'Con cái',
                  typeName: 'Con cái',
                ),
                const Divider(color: TColors.softGrey),
                _buildMemberItem(
                  context,
                  icon: 'assets/images/icons/father.png',
                  label: 'Cha mẹ',
                  type: 'Cha mẹ',
                  typeName: 'Cha mẹ',
                ),
                const Divider(color: TColors.softGrey),
                _buildMemberItem(
                  context,
                  icon: 'assets/images/icons/family.png',
                  label: 'Gia đình',
                  type: 'Gia đình',
                  typeName: 'Gia đình',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberItem(
    BuildContext context, {
    required String icon,
    required String label,
    required String type,
    required String typeName,
  }) {
    final isSelected = selectedType == type;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        onMemberSelected?.call(type, typeName);
        Navigator.of(context).pop();
      },
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                icon,
                height: 45,
                width: 45,
              ),
              AppSpacing.w8,
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          if (isSelected)
            const Positioned(
              top: 5,
              right: 10,
              child: Icon(
                  Iconsax.tick_circle,
                  color: TColors.primary,
                  size: 25,
                ),
            ),
        ],
      ),
    );
  }
}
