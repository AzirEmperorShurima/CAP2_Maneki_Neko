import 'package:auto_route/auto_route.dart';
import 'package:finance_management_app/common/widgets/text/overflow_marquee_text.dart';
import 'package:finance_management_app/routes/router.gr.dart';
import 'package:finance_management_app/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:iconsax/iconsax.dart';

import '../../../constants/app_border_radius.dart';
import '../../../constants/app_padding.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/colors.dart';
import '../../../features/domain/entities/budget_model.dart';
import '../../../features/presentation/blocs/budget/budget_bloc.dart';
import '../../../utils/formatters/formatter.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../budget/budget_progress_bar.dart';
import '../budget/budget_utils.dart';

/// Component hiển thị budget card
/// Có 2 variant: compact (cho home screen) và full (cho budget screen)
enum BudgetCardVariant {
  compact, // Compact style cho home screen
  full, // Full style cho budget screen
}

class BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  final BudgetCardVariant variant;

  const BudgetCard({
    super.key,
    required this.budget,
    this.variant = BudgetCardVariant.compact,
  });

  /// Format date range dựa trên budget type
  String _formatDateRange() {
    if (budget.type == 'daily') {
      // Hằng ngày: chỉ hiển thị periodEnd
      return TFormatter.formatDateMonth(budget.periodEnd);
    } else {
      // Các loại khác: hiển thị periodStart - periodEnd
      return '${TFormatter.formatDateMonth(budget.periodStart)} - ${TFormatter.formatDateMonth(budget.periodEnd)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (variant == BudgetCardVariant.compact) {
      return _buildCompactCard(context);
    } else {
      return _buildFullCard(context);
    }
  }

  /// Compact card cho home screen
  Widget _buildCompactCard(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.sm,
        color: isDark ? TColors.darkContainer : TColors.white,
        boxShadow: [
          BoxShadow(
            color: TColors.primary.withOpacity(0.2),
            blurRadius: 3,
            spreadRadius: 2,
            offset: Offset.zero,
          ),
        ],
      ),
      padding: AppPadding.a4.add(AppPadding.h8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: TColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    padding: AppPadding.a2,
                    child: Center(
                      child: Image.asset(
                        'assets/images/icons/budget.png',
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ),
                  AppSpacing.w8,

                  // Name + tag nằm chung 1 dòng
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Budget name
                            Expanded(
                              child: Text(
                                budget.name ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.apply(color: TColors.black),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            AppSpacing.w8,

                            // Tag
                            Container(
                              decoration: BoxDecoration(
                                color: TColors.primary.withOpacity(0.5),
                                borderRadius: AppBorderRadius.xsm,
                              ),
                              padding: AppPadding.v2.add(AppPadding.h8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    mapBudgetType(budget.type),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                            color: TColors.white, fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  AppSpacing.w4,
                                  Text(
                                    '(${_formatDateRange()})',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                            color: TColors.white, fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.h8,
                        BudgetProgressBar(
                          amount: budget.amount?.toDouble() ?? 0.0,
                          spentAmount: budget.spentAmount?.toDouble() ?? 0.0,
                          variant: BudgetProgressBarVariant.compact,
                        ),
                      ],
                    ),
                  ),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  /// Full card cho budget screen
  Widget _buildFullCard(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    return Container(
      margin: AppPadding.a16,
      child: Slidable(
        key: ValueKey(budget.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.42,
          children: [
            SlidableAction(
              onPressed: (_) => _editBudget(context),
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue.shade700,
              icon: Iconsax.edit,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            SlidableAction(
              onPressed: (_) => _deleteBudget(context),
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade700,
              icon: Iconsax.trash,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(40),
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            color: isDark ? TColors.darkContainer : TColors.white,
            boxShadow: [
              BoxShadow(
                color: TColors.primary.withOpacity(0.2),
                blurRadius: 3,
                spreadRadius: 2,
                offset: Offset.zero,
              ),
            ],
          ),
          padding: AppPadding.a16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OverflowMarqueeText(
                        text: budget.name ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.apply(color: TColors.black),
                      ),
                      AppSpacing.h4,
                      Text(
                        mapBudgetType(budget.type),
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.apply(color: TColors.darkerGrey),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: TColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    padding: AppPadding.a2,
                    child: Center(
                      child: Image.asset(
                        'assets/images/icons/budget.png',
                        width: 50,
                        height: 50,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.h4,
              Row(
                children: [
                  const Icon(Iconsax.calendar_1, size: 16, color: TColors.primary),
                  AppSpacing.w4,
                  Text(
                    _formatDateRange(),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.apply(color: TColors.darkGrey),
                  ),
                ],
              ),
              AppSpacing.h16,
              BudgetProgressBar(
                amount: budget.amount?.toDouble() ?? 0.0,
                spentAmount: budget.spentAmount?.toDouble() ?? 0.0,
                variant: BudgetProgressBarVariant.full,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editBudget(BuildContext context) {
    AutoRouter.of(context).push(
      BudgetAddScreenRoute(budget: budget),
    );
  }

  void _deleteBudget(BuildContext context) {
    final budgetBloc = context.read<BudgetBloc>();
    final navigator = Navigator.of(context);

    TLoaders.showConfirmActionSheet(
      context: context,
      title: 'Xác nhận xóa',
      message: 'Bạn có chắc chắn muốn xóa ngân sách "${budget.name}"?',
      onConfirm: () async {
        budgetBloc.add(
          DeleteBudgetSubmitted(budgetId: budget.id!),
        );
        navigator.pop();
      },
      onCancel: () async {
        navigator.pop();
      },
    );
  }
}
