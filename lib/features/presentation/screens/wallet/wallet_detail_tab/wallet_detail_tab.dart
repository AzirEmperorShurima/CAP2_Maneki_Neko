import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../../common/api_builder/transaction_builder.dart';
import '../../../../../common/widgets/card/transaction_card.dart';
import '../../../../../features/domain/entities/transaction_model.dart';
class WalletDetailTab extends StatefulWidget {
  final String? walletId;

  const WalletDetailTab({
    super.key,
    this.walletId,
  });

  @override
  State<WalletDetailTab> createState() => _WalletDetailTabState();
}

class _WalletDetailTabState extends State<WalletDetailTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.walletId == null || widget.walletId!.isEmpty) {
      return const Center(
        child: Text('Vui lòng chọn ví để xem chi tiết'),
      );
    }

    return TransactionBuilder(
      walletId: widget.walletId,
            type: null,
            page: 1,
            limit: 20,
            autoLoad: true,
            disableScroll: true,
            onRefresh: () {
              // Refresh có thể được thêm sau nếu cần
            },
            builder: (context, transactions) {
              // Group transactions by date
              final grouped = <DateTime, List<TransactionModel>>{};
              for (final t in transactions) {
                if (t.date == null) continue;
                final day =
                    DateTime(t.date!.year, t.date!.month, t.date!.day);
                grouped.putIfAbsent(day, () => []).add(t);
              }
              final dates = grouped.keys.toList()
                ..sort((a, b) => b.compareTo(a));

              if (dates.isEmpty) {
                return const Center(
                  child: Text('Không có giao dịch nào'),
                );
              }

              return Column(
                children: dates.map((date) {
                  final index = dates.indexOf(date);
                  final dayTransactions = grouped[date]!;
                  final totalExpense = dayTransactions
                      .where((t) =>
                          t.type != null && t.type == 'expense')
                      .fold(
                          0.0,
                          (sum, t) =>
                              sum +
                              (t.amount?.toDouble() ?? 0));

                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 500),
                    child: SlideAnimation(
                      verticalOffset: 50,
                      child: FadeInAnimation(
                        child: TransactionCard(
                          margin: EdgeInsets.zero,
                          date: date,
                          transactions: dayTransactions,
                          totalExpense: totalExpense,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
      emptyBuilder: (context) => const Center(
        child: Text('Không có giao dịch nào'),
      ),
    );
  }
}
