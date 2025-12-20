import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../common/widgets/profile/t_circular_image.dart';
import '../../../../../common/widgets/text/overflow_marquee_text.dart';
import '../../../../../common/widgets/text/price_text.dart';
import '../../../../../constants/app_border_radius.dart';
import '../../../../../constants/app_padding.dart';
import '../../../../../constants/app_spacing.dart';
import '../../../../../constants/colors.dart';
import '../../../../../constants/image_strings.dart';
import '../../../../domain/entities/family_user_breakdown_model.dart';
import '../../../blocs/family/family_bloc.dart';

class FamilyUserBreakdownTab extends StatefulWidget {
  const FamilyUserBreakdownTab({super.key});

  @override
  State<FamilyUserBreakdownTab> createState() => _FamilyUserBreakdownTabState();
}

class _FamilyUserBreakdownTabState extends State<FamilyUserBreakdownTab> {
  int touchedIndex = -1;
  String selectedType = 'expense'; // expense hoặc income
  FamilyUserBreakdownModel? _cachedData;

  static const List<Color> _categoryColors = [
    Colors.orange,
    Colors.pink,
    Colors.blue,
    Colors.purple,
    Colors.green,
    Colors.teal,
    Colors.amber,
    Colors.red,
    Colors.indigo,
    Colors.grey,
  ];

  Color _getCategoryColor(int index) {
    return _categoryColors[index % _categoryColors.length];
  }

  void _ensureDataLoaded() {
    if (_cachedData == null) {
      context.read<FamilyBloc>().add(LoadFamilyUserBreakdown());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyBloc, FamilyState>(
      builder: (context, state) {
        // Lưu lại data khi state là Loaded
        if (state is FamilyUserBreakdownLoaded) {
          _cachedData = state.breakdown;
        }

        // Nếu state không phải là state của tab này
        if (!(state is FamilyUserBreakdownLoading ||
            state is FamilyUserBreakdownLoaded ||
            state is FamilyUserBreakdownFailure)) {
          // Nếu đã có data cache, hiển thị data đó
          if (_cachedData != null) {
            return _buildContent(_cachedData!);
          }
          // Nếu chưa có data, dispatch event để load
          _ensureDataLoaded();
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FamilyUserBreakdownLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FamilyUserBreakdownFailure) {
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
                    context.read<FamilyBloc>().add(LoadFamilyUserBreakdown());
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (state is FamilyUserBreakdownLoaded) {
          final breakdown = state.breakdown;
          if (breakdown == null) {
            return const Center(
              child: Text('Không có dữ liệu'),
            );
          }

          return _buildContent(breakdown);
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildContent(FamilyUserBreakdownModel breakdown) {
    return SingleChildScrollView(
      padding: AppPadding.a16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          if (breakdown.summary != null)
            _buildSummaryCard(context, breakdown.summary!),
          AppSpacing.h16,

          // Type Switcher
          _buildTypeSwitcher(context),
          AppSpacing.h16,

          // Pie Chart
          if (breakdown.charts != null)
            _buildPieChartCard(context, breakdown.charts!, breakdown),
          AppSpacing.h16,

          // Breakdown List
          if (breakdown.breakdown != null &&
              breakdown.breakdown!.isNotEmpty) ...[
            _buildSectionTitle(context, 'Chi tiết thành viên'),
            AppSpacing.h8,
            ...breakdown.breakdown!.map((item) => Padding(
                  padding: AppPadding.v4,
                  child: _buildBreakdownItemCard(context, item),
                )),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, FamilyBreakdownSummaryModel summary) {
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
                child: _buildSummaryItem(
                  context,
                  'Tổng chi tiêu',
                  summary.totalExpense ?? 0,
                  Colors.red,
                ),
              ),
              AppSpacing.w8,
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Tổng thu nhập',
                  summary.totalIncome ?? 0,
                  Colors.green,
                ),
              ),
            ],
          ),
          AppSpacing.h8,
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Số dư',
                  summary.familyBalance ?? 0,
                  summary.familyBalance != null && summary.familyBalance! < 0
                      ? Colors.red
                      : Colors.green,
                ),
              ),
              AppSpacing.w8,
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Thành viên',
                  summary.memberCount?.toDouble() ?? 0,
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

  Widget _buildSummaryItem(
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            )
          else
            PriceText(
              amount: value.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              currencyStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
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

  Widget _buildTypeSwitcher(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.md,
        color: TColors.primary.withOpacity(0.1),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedType = 'expense';
                  touchedIndex = -1;
                });
              },
              child: Container(
                padding: AppPadding.v8,
                decoration: BoxDecoration(
                  color: selectedType == 'expense'
                      ? Colors.red
                      : Colors.transparent,
                  borderRadius: AppBorderRadius.sm,
                ),
                child: Text(
                  'Chi tiêu',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: selectedType == 'expense'
                            ? Colors.white
                            : Colors.black,
                      ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedType = 'income';
                  touchedIndex = -1;
                });
              },
              child: Container(
                padding: AppPadding.v8,
                decoration: BoxDecoration(
                  color: selectedType == 'income'
                      ? Colors.green
                      : Colors.transparent,
                  borderRadius: AppBorderRadius.sm,
                ),
                child: Text(
                  'Thu nhập',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: selectedType == 'income'
                            ? Colors.white
                            : Colors.black,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(
    BuildContext context,
    FamilyBreakdownChartsModel charts,
    FamilyUserBreakdownModel breakdown,
  ) {
    final chartData =
        selectedType == 'expense' ? charts.expense : charts.income;

    if (chartData == null ||
        chartData.data == null ||
        chartData.data!.isEmpty) {
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
        child: Center(
          child: Text(
            'Không có dữ liệu ${selectedType == 'expense' ? 'chi tiêu' : 'thu nhập'}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

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
            chartData.title ?? 'Phân bổ theo thành viên',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.h16,
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _buildPieChartSections(context, chartData.data!),
              ),
            ),
          ),
          AppSpacing.h16,
          // Legend
          ...chartData.data!.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isTouched = touchedIndex == index;
            return Padding(
              padding: AppPadding.v4,
              child: _buildLegendItem(context, item, index, isTouched),
            );
          }),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    BuildContext context,
    List<FamilyBreakdownChartItemModel> data,
  ) {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isTouched = touchedIndex == index;
      final radius = isTouched ? 70.0 : 60.0;
      final percentage = item.percentage ?? 0.0;

      return PieChartSectionData(
        color: _getCategoryColor(index),
        value: item.value ?? 0,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: TColors.white),
      );
    }).toList();
  }

  Widget _buildLegendItem(
    BuildContext context,
    FamilyBreakdownChartItemModel item,
    int index,
    bool isTouched,
  ) {
    final percentage = item.percentage ?? 0.0;
    final value = item.value ?? 0.0;

    return Container(
        padding: AppPadding.v8,
        decoration: BoxDecoration(
          color: isTouched
              ? _getCategoryColor(index).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: AppBorderRadius.sm,
        ),
        child: Row(
          children: [
            // Icon
            SizedBox(
              width: 16,
              child: Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(index),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            AppSpacing.w8,

            // Tên
            Expanded(
              flex: 3,
              child: OverflowMarqueeText(
                text: item.name ?? 'Chưa có tên',
                style: Theme.of(context).textTheme.bodyMedium,
                alignment: Alignment.centerLeft,
              ),
            ),

            AppSpacing.w8,

            // %
            Expanded(
              flex: 1,
              child: Text('${percentage.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.labelLarge),
            ),

            AppSpacing.w8,

            // Tiền (chiếm nhiều nhất)
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: PriceText(
                  amount: value.toString(),
                  style: Theme.of(context).textTheme.labelLarge,
                  currencyStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: TColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ));
  }

  Widget _buildBreakdownItemCard(
    BuildContext context,
    FamilyBreakdownItemModel item,
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
                image: (item.avatar != null && item.avatar!.isNotEmpty)
                    ? item.avatar!
                    : TImages.user,
                isNetworkImage: item.avatar != null && item.avatar!.isNotEmpty,
                width: 50,
                height: 50,
                padding: 0,
              ),
              AppSpacing.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OverflowMarqueeText(
                      text: item.username ?? item.email ?? 'Chưa có tên',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      alignment: Alignment.centerLeft,
                    ),
                    if (item.email != null) ...[
                      AppSpacing.h4,
                      Text(
                        item.email!,
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
                child: _buildItemStat(
                  context,
                  'Chi tiêu',
                  item.expense?.total ?? 0,
                  item.expense?.count ?? 0,
                  Colors.red,
                ),
              ),
              AppSpacing.w8,
              Expanded(
                child: _buildItemStat(
                  context,
                  'Thu nhập',
                  item.income?.total ?? 0,
                  item.income?.count ?? 0,
                  Colors.green,
                ),
              ),
            ],
          ),
          AppSpacing.h8,
          Row(
            children: [
              Expanded(
                child: _buildItemStat(
                  context,
                  'Số dư',
                  item.balance ?? 0,
                  null,
                  item.balance != null && item.balance! < 0
                      ? Colors.red
                      : Colors.green,
                ),
              ),
              AppSpacing.w8,
              Expanded(
                child: _buildItemStat(
                  context,
                  'Giao dịch',
                  item.totalTransactions?.toDouble() ?? 0,
                  null,
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

  Widget _buildItemStat(
    BuildContext context,
    String label,
    double value,
    int? count,
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
          if (count != null && count > 0) ...[
            AppSpacing.h2,
            Text(
              '$count giao dịch',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: TColors.darkerGrey,
                  ),
            ),
          ],
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
