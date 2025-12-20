import 'package:finance_management_app/common/widgets/text/price_text.dart';
import 'package:finance_management_app/common/widgets/wallet_picker/wallet_picker_bottom_sheet.dart';
import 'package:finance_management_app/constants/app_padding.dart';
import 'package:finance_management_app/constants/app_spacing.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:finance_management_app/features/domain/entities/wallet_model.dart';
import 'package:flutter/material.dart';

import '../../../../../common/widgets/text/overflow_marquee_text.dart';
import '../../../../../utils/device/device_utility.dart';

class TransactionsAddTransfer extends StatefulWidget {
  final String? fromWalletId;
  final String? toWalletId;
  final String? amount;
  final List<WalletModel>? wallets;
  final Function(String?)? onFromWalletSelected;
  final Function(String?)? onToWalletSelected;

  const TransactionsAddTransfer({
    super.key,
    this.fromWalletId,
    this.toWalletId,
    this.amount,
    this.wallets,
    this.onFromWalletSelected,
    this.onToWalletSelected,
  });

  @override
  State<TransactionsAddTransfer> createState() =>
      _TransactionsAddTransferState();
}

class _TransactionsAddTransferState extends State<TransactionsAddTransfer> {
  WalletModel? _getWalletById(String? walletId) {
    if (walletId == null || walletId.isEmpty || widget.wallets == null) {
      return null;
    }
    try {
      return widget.wallets!.firstWhere(
        (wallet) => wallet.id == walletId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromWallet = _getWalletById(widget.fromWalletId);
    final toWallet = _getWalletById(widget.toWalletId);
    final amount = double.tryParse(widget.amount ?? '0') ?? 0.0;

    return Padding(
      padding: AppPadding.v32.add(AppPadding.h16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    TDeviceUtils.lightImpact();
                    WalletPickerBottomSheet.show(
                      context: context,
                      selectedWalletId: widget.fromWalletId,
                      onWalletSelected: (walletId) {
                        widget.onFromWalletSelected?.call(walletId);
                      },
                    );
                  },
                  child: Column(
                    children: [
                      Image.asset('assets/images/icons/money_transfer.png',
                          height: 50),
                      AppSpacing.h16,
                      Text('Từ ví',
                          style: Theme.of(context).textTheme.bodyMedium),
                      AppSpacing.h8,
                      OverflowMarqueeText(
                        text: fromWallet?.name ?? 'Chọn ví',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: fromWallet == null
                                  ? TColors.darkGrey
                                  : TColors.primary,
                              fontWeight: fromWallet != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                      ),
                      if (fromWallet != null && amount > 0) ...[
                        AppSpacing.h8,
                        PriceText(
                          title: '-',
                          amount: amount.toStringAsFixed(0),
                          color: Colors.red,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Expanded(
                child: Icon(Icons.forward, color: TColors.primary, size: 40),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    TDeviceUtils.lightImpact();
                    WalletPickerBottomSheet.show(
                      context: context,
                      selectedWalletId: widget.toWalletId,
                      onWalletSelected: (walletId) {
                        widget.onToWalletSelected?.call(walletId);
                      },
                    );
                  },
                  child: Column(
                    children: [
                      Image.asset('assets/images/icons/atm-card.png', height: 50),
                      AppSpacing.h16,
                      OverflowMarqueeText(
                        text: 'Đến ví',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      AppSpacing.h8,
                      OverflowMarqueeText(
                        text: toWallet?.name ?? 'Chọn ví',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: toWallet == null
                                  ? TColors.darkGrey
                                  : TColors.primary,
                              fontWeight: toWallet != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                      ),
                      if (toWallet != null && amount > 0) ...[
                        AppSpacing.h8,
                        PriceText(
                          title: '+',
                          amount: amount.toStringAsFixed(0),
                          color: Colors.green,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
