import 'package:auto_route/auto_route.dart';
import 'package:finance_management_app/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:iconsax/iconsax.dart';

import '../../../routes/router.gr.dart';

import '../../../constants/app_border_radius.dart';
import '../../../constants/app_padding.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/colors.dart';
import '../../../features/domain/entities/transaction_model.dart';
import '../../../features/presentation/blocs/transaction/transaction_bloc.dart';
import '../../../utils/formatters/formatter.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../profile/t_circular_image.dart';
import '../text/overflow_marquee_text.dart';
import '../text/price_text.dart';

class TransactionCard extends StatefulWidget {
  final DateTime date;

  final List<TransactionModel> transactions;

  final double totalExpense;

  final String Function(DateTime)? dateHeaderFormatter;

  final EdgeInsetsGeometry? margin;

  const TransactionCard({
    super.key,
    required this.date,
    required this.transactions,
    required this.totalExpense,
    this.dateHeaderFormatter,
    this.margin,
  });

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final formattedDateHeader = widget.dateHeaderFormatter != null
        ? widget.dateHeaderFormatter!(widget.date)
        : TFormatter.formatDateHeader(widget.date);

    return Container(
      margin: widget.margin ?? AppPadding.h16,
      padding: AppPadding.v8,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Container(
            width: THelperFunctions.screenWidth(context),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: isDark ? TColors.darkContainer : TColors.white,
              borderRadius: AppBorderRadius.md,
              boxShadow: [
                BoxShadow(
                  color: TColors.primary.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: Offset.zero,
                ),
              ],
            ),
            padding: EdgeInsets.only(
              left: 16,
              top: _isExpanded ? 40 : 0,
              bottom: _isExpanded ? 16 : 0,
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isExpanded
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...widget.transactions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final transaction = entry.value;
                          final isExpense = transaction.type == 'expense';
                          final amount = transaction.amount?.toString() ?? '0';

                          return Column(
                            children: [
                              Slidable(
                                key: ValueKey(transaction.id),
                                endActionPane: ActionPane(
                                  motion:
                                      const DrawerMotion(),
                                  extentRatio: 0.42,
                                  children: [
                                    SlidableAction(
                                      onPressed: (_) => _editTransaction(
                                          context, transaction),
                                      backgroundColor: Colors.blue.shade50,
                                      foregroundColor: Colors.blue.shade700,
                                      icon: Iconsax.edit,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        bottomLeft: Radius.circular(4),
                                      ),
                                    ),
                                    SlidableAction(
                                      onPressed: (_) => _deleteTransaction(
                                          context, transaction),
                                      backgroundColor: Colors.red.shade50,
                                      foregroundColor: Colors.red.shade700,
                                      icon: Iconsax.trash,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: GestureDetector(
                                    onTap: () =>
                                        showDetailTransactionBottomSheet(
                                            context, transaction),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: TColors.softGrey),
                                              borderRadius: AppBorderRadius.sm,
                                            ),
                                            padding: AppPadding.a4,
                                            child: TCircularImage(
                                              image:
                                                  transaction.category?.image ??
                                                      '',
                                              isNetworkImage: transaction
                                                      .category
                                                      ?.image
                                                      ?.isNotEmpty ==
                                                  true,
                                              width: 45,
                                              height: 45,
                                              fit: BoxFit.contain,
                                              borderRadius:
                                                  BorderRadius.circular(0),
                                            ),
                                          ),
                                          AppSpacing.w16,
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  transaction.category?.name ??
                                                      'Không có mô tả',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (transaction.description
                                                            ?.isNotEmpty ==
                                                        true ||
                                                    transaction.expenseFor
                                                            ?.isNotEmpty ==
                                                        true) ...[
                                                  Text(
                                                    transaction.description
                                                                ?.isNotEmpty ==
                                                            true
                                                        ? '${transaction.expenseFor ?? 'Tôi'} / ${transaction.description}'
                                                        : (transaction
                                                                .expenseFor ??
                                                            'Tôi'),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelLarge
                                                        ?.copyWith(
                                                            color: TColors
                                                                .darkGrey),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          AppSpacing.w16,
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              PriceText(
                                                title: isExpense ? '-' : '+',
                                                amount: amount,
                                                color: isExpense
                                                    ? Colors.red
                                                    : Colors.green,
                                              ),
                                              AppSpacing.h4,
                                              Text(
                                                transaction.wallet?.name ??
                                                    'Không xác định',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                        color:
                                                            TColors.darkGrey),
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (index < widget.transactions.length - 1)
                                const Column(
                                  children: [
                                    AppSpacing.h4,
                                    Divider(color: TColors.softGrey),
                                    AppSpacing.h4,
                                  ],
                                ),
                            ],
                          );
                        }),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              width: THelperFunctions.screenWidth(context),
              decoration: const BoxDecoration(
                color: TColors.primary,
                borderRadius: AppBorderRadius.md,
              ),
              padding: AppPadding.h16.add(AppPadding.v4),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _isExpanded ? 0 : 0.5,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: const Icon(
                      Icons.expand_circle_down,
                      size: 18,
                      color: TColors.white,
                    ),
                  ),
                  AppSpacing.w16,
                  Expanded(
                    child: Text(
                      formattedDateHeader,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: TColors.white),
                    ),
                  ),
                  PriceText(
                    title: 'Chi tiêu: ',
                    amount: widget.totalExpense.toInt().toString(),
                    color: TColors.white,
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
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showDetailTransactionBottomSheet(
      BuildContext context, TransactionModel transaction) {
    final isExpense = transaction.type == 'expense';

    final amount = transaction.amount?.toString() ?? '0';

    TLoaders.bottomSheet(
      context: context,
      borderRadius: AppBorderRadius.md,
      heightPercentage: 0.4,
      child: Column(
        children: [
          Text('Chi tiết giao dịch',
              style: Theme.of(context).textTheme.titleLarge),
          const Divider(color: TColors.softGrey),
          AppSpacing.h8,
          Expanded(
            child: Padding(
              padding: AppPadding.h16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TCircularImage(
                        image: transaction.category?.image ?? '',
                        isNetworkImage:
                            transaction.category?.image?.isNotEmpty == true,
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                        borderRadius: BorderRadius.circular(0),
                      ),
                      AppSpacing.w16,
                      Text(transaction.category?.name ?? 'Không có mô tả',
                          style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                  AppSpacing.h16,
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Số tiền: ',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        WidgetSpan(
                          child: PriceText(
                            title: isExpense ? '-' : '+',
                            amount: amount,
                            color: isExpense ? Colors.red : Colors.green,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                    color: isExpense
                                        ? Colors.red
                                        : Colors.green),
                            currencyStyle: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color:
                                      isExpense ? Colors.red : Colors.green,
                                  decoration: TextDecoration.underline,
                                  decorationColor:
                                      isExpense ? Colors.red : Colors.green,
                                ),
                          ),
                        )
                      ],
                    ),
                  ),
                  AppSpacing.h16,
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                            text: 'Ngày: ',
                            style: Theme.of(context).textTheme.titleLarge),
                        TextSpan(
                            text:
                                TFormatter.formatDateTimeFull(transaction.date),
                            style: Theme.of(context).textTheme.titleSmall),
                      ],
                    ),
                  ),
                  AppSpacing.h16,
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                            text: 'Thành viên: ',
                            style: Theme.of(context).textTheme.titleLarge),
                        TextSpan(
                            text: transaction.expenseFor ?? 'Tôi',
                            style: Theme.of(context).textTheme.titleSmall),
                      ],
                    ),
                  ),
                  AppSpacing.h16,
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                            text: 'Ví tiền: ',
                            style: Theme.of(context).textTheme.titleLarge),
                        TextSpan(
                            text: transaction.wallet?.name ??
                                'Không xác định',
                            style: Theme.of(context).textTheme.titleSmall),
                      ],
                    ),
                  ),
                  if (transaction.description?.isNotEmpty == true) ...[
                    AppSpacing.h16,
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'Ghi chú: ',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Expanded(
                            child: OverflowMarqueeText(
                              text: transaction.description ??
                                  'Không có ghi chú',
                              style: Theme.of(context).textTheme.titleSmall,
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void _editTransaction(
    BuildContext context,
    TransactionModel transaction,
  ) {
    AutoRouter.of(context).push(
      TransactionsAddScreenRoute(transaction: transaction),
    );
  }

  void _deleteTransaction(
    BuildContext context,
    TransactionModel transaction,
  ) {
    final transactionBloc = context.read<TransactionBloc>();
    final navigator = Navigator.of(context);

    TLoaders.showConfirmActionSheet(
      context: context,
      title: 'Xác nhận xóa',
      message: 'Bạn có chắc chắn muốn xóa giao dịch này?',
      onConfirm: () async {
        transactionBloc.add(
          DeleteTransactionSubmitted(transactionId: transaction.id!),
        );
        if (mounted) {
          navigator.pop();
        }
      },
      onCancel: () async {
        if (mounted) {
          navigator.pop();
        }
      },
    );
  }
}
