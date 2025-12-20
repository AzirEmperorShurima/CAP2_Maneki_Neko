import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../../common/widgets/profile/t_circular_image.dart';
import '../../../../../common/widgets/text/price_text.dart';
import '../../../../../constants/app_border_radius.dart';
import '../../../../../constants/app_padding.dart';
import '../../../../../constants/app_spacing.dart';
import '../../../../../constants/colors.dart';
import '../../../../../constants/image_strings.dart';
import '../../../../domain/entities/family_analytics_summary_model.dart';
import '../../../blocs/family/family_bloc.dart';

class FamilyAnalyticsSummaryTab extends StatefulWidget {
  const FamilyAnalyticsSummaryTab({super.key});

  @override
  State<FamilyAnalyticsSummaryTab> createState() =>
      _FamilyAnalyticsSummaryTabState();
}

class _FamilyAnalyticsSummaryTabState extends State<FamilyAnalyticsSummaryTab> {
  FamilyAnalyticsSummaryModel? _cachedData;

  void _ensureDataLoaded() {
    if (_cachedData == null) {
      context.read<FamilyBloc>().add(LoadFamilyAnalyticsSummary());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyBloc, FamilyState>(
      builder: (context, state) {
        // Lưu lại data khi state là Loaded
        if (state is FamilyAnalyticsSummaryLoaded) {
          _cachedData = state.summary;
        }

        // Nếu state không phải là state của tab này
        if (!(state is FamilyAnalyticsSummaryLoading ||
            state is FamilyAnalyticsSummaryLoaded ||
            state is FamilyAnalyticsSummaryFailure)) {
          // Nếu đã có data cache, hiển thị data đó
          if (_cachedData != null) {
            return _buildContent(_cachedData!);
          }
          // Nếu chưa có data, dispatch event để load
          _ensureDataLoaded();
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FamilyAnalyticsSummaryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FamilyAnalyticsSummaryFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Lỗi: ${state.message}',
                  style: const TextStyle(color: Colors.red),
                ),
                AppSpacing.h16,
                ElevatedButton(
                  onPressed: () {
                    _cachedData = null;
                    context
                        .read<FamilyBloc>()
                        .add(LoadFamilyAnalyticsSummary());
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (state is FamilyAnalyticsSummaryLoaded) {
          final summary = state.summary;
          if (summary == null) {
            return const Center(
              child: Text('Không có dữ liệu'),
            );
          }

          return _buildContent(summary);
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildContent(FamilyAnalyticsSummaryModel summary) {
    return SingleChildScrollView(
      padding: AppPadding.a16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Card
          if (summary.period != null)
            _buildPeriodCard(context, summary.period!),
          AppSpacing.h16,

          // Totals Card
          if (summary.totals != null)
            _buildTotalsCard(context, summary.totals!),
          AppSpacing.h16,

          // Member Summary
          if (summary.memberSummary != null &&
              summary.memberSummary!.isNotEmpty) ...[
            _buildSectionTitle(context, 'Tóm tắt thành viên'),
            AppSpacing.h8,
            ...summary.memberSummary!.map((member) => Padding(
                  padding: AppPadding.v4,
                  child: _buildMemberSummaryCard(context, member),
                )),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPeriodCard(BuildContext context, period) {
    final startDate = period.startDate;
    final endDate = period.endDate;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.md,
        color: TColors.primary.withOpacity(0.1),
        border: Border.all(
          color: TColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: AppPadding.a8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Iconsax.calendar,
                color: TColors.primary,
                size: 20,
              ),
              AppSpacing.w8,
              Text(
                'Kỳ báo cáo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: TColors.primary,
                    ),
              ),
            ],
          ),
          AppSpacing.h8,
          if (startDate != null && endDate != null)
            Text(
              '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
              style: Theme.of(context).textTheme.bodyLarge,
            )
          else
            Text(
              'Tất cả thời gian',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(BuildContext context, totals) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.md,
        color: TColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: AppPadding.a16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.h16,
          Row(
            children: [
              Expanded(
                child: _buildTotalItem(
                  context,
                  'Chi tiêu',
                  totals.expense ?? 0,
                  Colors.red,
                ),
              ),
              AppSpacing.w8,
              Expanded(
                child: _buildTotalItem(
                  context,
                  'Thu nhập',
                  totals.income ?? 0,
                  Colors.green,
                ),
              ),
            ],
          ),
          AppSpacing.h8,
          Row(
            children: [
              Expanded(
                child: _buildTotalItem(
                  context,
                  'Số dư',
                  totals.balance ?? 0,
                  totals.balance != null && totals.balance! < 0
                      ? Colors.red
                      : Colors.green,
                ),
              ),
              AppSpacing.w8,
              Expanded(
                child: _buildTotalItem(
                  context,
                  'Giao dịch',
                  totals.transactionCount?.toDouble() ?? 0,
                  TColors.primary,
                  isCount: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalItem(
    BuildContext context,
    String label,
    double value,
    Color color, {
    bool isCount = false,
  }) {
    return Container(
      padding: AppPadding.a8,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppBorderRadius.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TColors.darkerGrey,
                ),
          ),
          AppSpacing.h4,
          if (isCount)
            Text(
              value.toInt().toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            )
          else
            PriceText(
              amount: value.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              currencyStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    decoration: TextDecoration.underline,
                    decorationColor: color,
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberSummaryCard(
    BuildContext context,
    FamilyMemberSummaryModel member,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.md,
        color: TColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: AppPadding.a8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TCircularImage(
                image: (member.avatar != null && member.avatar!.isNotEmpty)
                    ? member.avatar!
                    : TImages.user,
                isNetworkImage:
                    member.avatar != null && member.avatar!.isNotEmpty,
                width: 50,
                height: 50,
                padding: 0,
              ),
              AppSpacing.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.username ?? member.email ?? 'Chưa có tên',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (member.email != null) ...[
                      AppSpacing.h4,
                      Text(
                        member.email!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: TColors.darkerGrey,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.h8,
          Row(
            children: [
              Expanded(
                child: _buildMemberStatItem(
                  context,
                  'Chi tiêu',
                  member.expense ?? 0,
                  Colors.red,
                ),
              ),
              AppSpacing.w8,
              Expanded(
                child: _buildMemberStatItem(
                  context,
                  'Thu nhập',
                  member.income ?? 0,
                  Colors.green,
                ),
              ),
            ],
          ),
          AppSpacing.h8,
          Row(
            children: [
              Expanded(
                child: _buildMemberStatItem(
                  context,
                  'Số dư',
                  member.balance ?? 0,
                  member.balance != null && member.balance! < 0
                      ? Colors.red
                      : Colors.green,
                ),
              ),
              AppSpacing.w8,
              Expanded(
                child: _buildMemberStatItem(
                  context,
                  'Giao dịch',
                  ((member.expenseCount ?? 0) + (member.incomeCount ?? 0))
                      .toDouble() as double,
                  TColors.primary,
                  isCount: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberStatItem(
    BuildContext context,
    String label,
    double value,
    Color color, {
    bool isCount = false,
  }) {
    return Container(
      padding: AppPadding.a8,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppBorderRadius.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: TColors.darkerGrey,
                ),
          ),
          AppSpacing.h4,
          if (isCount)
            Text(
              value.toInt().toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            )
          else
            PriceText(
              amount: value.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              currencyStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    decoration: TextDecoration.underline,
                    decorationColor: color,
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: TColors.black,
          ),
    );
  }
}
