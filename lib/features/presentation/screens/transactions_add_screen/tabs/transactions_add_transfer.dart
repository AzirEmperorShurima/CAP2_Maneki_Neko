import 'package:finance_management_app/common/widgets/text/price_text.dart';
import 'package:finance_management_app/constants/app_padding.dart';
import 'package:finance_management_app/constants/app_spacing.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:flutter/material.dart';

import '../../../../../common/widgets/text/overflow_marquee_text.dart';

class TransactionsAddTransfer extends StatefulWidget {
  const TransactionsAddTransfer({super.key});

  @override
  State<TransactionsAddTransfer> createState() =>
      _TransactionsAddTransferState();
}

class _TransactionsAddTransferState extends State<TransactionsAddTransfer> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.v32.add(AppPadding.h16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Image.asset('assets/images/icons/money_transfer.png',
                        height: 50),
                    AppSpacing.h16,
                    Text('Bao Wallet',
                        style: Theme.of(context).textTheme.bodyMedium),
                    AppSpacing.h8,
                    PriceText(
                      title: '-',
                      amount: '0',
                      color: Colors.red,
                    )
                  ],
                ),
              ),
              Expanded(
                child: Icon(Icons.forward, color: TColors.primary, size: 40),
              ),
              Expanded(
                child: Column(
                  children: [
                    Image.asset('assets/images/icons/atm-card.png', height: 50),
                    AppSpacing.h16,
                    OverflowMarqueeText(
                      text: 'Please select a wallet',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    AppSpacing.h8,
                    PriceText(
                      title: '+',
                      amount: '0',
                      color: Colors.green,
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
