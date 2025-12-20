import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:iconsax/iconsax.dart';

import '../../../constants/app_border_radius.dart';
import '../../../constants/app_padding.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/colors.dart';
import '../../../features/domain/entities/wallet_model.dart';
import '../../../features/presentation/blocs/wallet/wallet_bloc.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../../../utils/popups/loaders.dart';
import '../text/price_text.dart';

class WalletCard extends StatelessWidget {
  final WalletModel wallet;
  final VoidCallback? onTap;

  const WalletCard({
    super.key,
    required this.wallet,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final walletName = wallet.name ?? 'Không có tên';
    final walletType = wallet.type ?? 'Không có loại';
    final walletDescription = wallet.description ?? 'Không có mô tả';
    final balance = wallet.balance?.toString() ?? '0';
    final iconPath = 'assets/images/icons/wallet.png';
    final isNegative = (wallet.balance ?? 0) < 0;

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8, left: 12, right: 12),
      width: THelperFunctions.screenWidth(context),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.sm,
        color: isDark ? TColors.darkContainer : TColors.white,
        boxShadow: [
          BoxShadow(
            color: TColors.primary.withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 2,
            offset: Offset.zero,
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: TColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              padding: AppPadding.a8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    walletType,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: TColors.white),
                  ),
                  Row(
                    children: [
                      Text(
                        'Tài sản: ',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: TColors.white),
                      ),
                      PriceText(
                        amount: balance,
                        color: isNegative ? Colors.red : TColors.white,
                        title: isNegative ? '-' : null,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: TColors.white),
                        currencyStyle:
                            Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: TColors.white,
                              decoration: TextDecoration.underline,
                              decorationColor: TColors.white,
                            ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Slidable(
              key: ValueKey(wallet.id),
              endActionPane: ActionPane(
                motion: const StretchMotion(),
                extentRatio: 0.2,
                children: [
                  SlidableAction(
                    onPressed: (context) {
                      _deleteWallet(context, wallet);
                    },
                    backgroundColor: Colors.red,
                    icon: Iconsax.trash,
                    flex: 1,
                  ),
                ],
              ),
              child: Padding(
                padding: AppPadding.a16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          iconPath,
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/icons/wallet.png',
                              width: 40,
                              height: 40,
                            );
                          },
                        ),
                        AppSpacing.w16,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              walletName,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            if (walletDescription.isNotEmpty) ...[
                              AppSpacing.h4,
                              Text(
                                walletDescription,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    PriceText(
                      amount: balance,
                      color: isNegative ? Colors.red : null,
                      title: isNegative ? '-' : null,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isNegative ? Colors.red : null,
                          ),
                      currencyStyle:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
                            decoration: TextDecoration.underline,
                            decorationColor: isNegative ? Colors.red : null,
                            color: isNegative ? Colors.red : null,
                          ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _deleteWallet(BuildContext context, WalletModel wallet) {
    final walletBloc = context.read<WalletBloc>();
    final navigator = Navigator.of(context);

    TLoaders.showConfirmActionSheet(
      context: context,
      title: 'Xác nhận xóa',
      message: 'Bạn có chắc chắn muốn xóa ví này?',
      confirmText: 'Xóa',
      cancelText: 'Hủy',
      onCancel: () async {
          navigator.pop();
      },
      onConfirm: () async {
        if (wallet.id != null) {
          walletBloc.add(DeleteWalletSubmitted(walletId: wallet.id!));
        } else {
          TLoaders.showNotification(
            context,
            type: NotificationType.error,
            title: 'Lỗi',
            message: 'Không thể xóa ví này',
          );
        }

        navigator.pop();
      },
    );
  }
}
