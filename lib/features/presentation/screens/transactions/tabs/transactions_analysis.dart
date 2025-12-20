import 'package:finance_management_app/common/api_builder/analysis_builder.dart';
import 'package:finance_management_app/common/api_builder/category_analysis_builder.dart';
import 'package:finance_management_app/common/widgets/text/price_text.dart';
import 'package:finance_management_app/constants/app_border_radius.dart';
import 'package:finance_management_app/constants/app_padding.dart';
import 'package:finance_management_app/constants/app_spacing.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:finance_management_app/features/domain/entities/category_analysis_model.dart';
import 'package:finance_management_app/utils/helpers/category_icon_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class TransactionsAnalysis extends StatefulWidget {
  const TransactionsAnalysis({super.key});

  @override
  State<TransactionsAnalysis> createState() => _TransactionsAnalysisState();
}

class _TransactionsAnalysisState extends State<TransactionsAnalysis> {
  int touchedIndex = -1;
  String selectedType = 'expense'; // expense hoặc income

  // Màu sắc cho các category
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

  DateTime _getStartDateOfMonth(DateTime month) {
    return DateTime(month.year, month.month, 1);
  }

  DateTime _getEndDateOfMonth(DateTime month) {
    return DateTime(month.year, month.month + 1, 0, 23, 59, 59);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startDate = _getStartDateOfMonth(now);
    final endDate = _getEndDateOfMonth(now);

    return Container(
      color: TColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(context, startDate, endDate),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: AppPadding.h8,
                child: Column(
                  children: [
                    AppSpacing.h16,
                    // Tab switcher để chọn expense/income
                    _buildTypeSwitcher(context),
                    AppSpacing.h16,
                    // Pie Chart - Phân bổ theo danh mục
                    CategoryAnalysisBuilder(
                      type: selectedType,
                      builder: (context, categoryAnalysis) {
                        if (categoryAnalysis == null ||
                            categoryAnalysis.categories == null ||
                            categoryAnalysis.categories!.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return _buildPieChartCard(context, categoryAnalysis);
                      },
                    ),
                    AppSpacing.h16,
                    // Danh sách chi tiết các danh mục
                    CategoryAnalysisBuilder(
                      type: selectedType,
                      builder: (context, categoryAnalysis) {
                        if (categoryAnalysis == null ||
                            categoryAnalysis.categories == null ||
                            categoryAnalysis.categories!.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return _buildCategoryList(context, categoryAnalysis);
                      },
                    ),
                    const SizedBox(height: 100)
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSwitcher(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedType = 'expense';
              });
            },
            child: Container(
              padding: AppPadding.a8,
              decoration: BoxDecoration(
                color: selectedType == 'expense'
                    ? TColors.primary
                    : TColors.softGrey,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Text(
                  'Chi tiêu',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: selectedType == 'expense'
                            ? TColors.white
                            : TColors.textPrimary,
                        fontWeight: selectedType == 'expense'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
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
              });
            },
            child: Container(
              padding: AppPadding.a8,              decoration: BoxDecoration(
                color: selectedType == 'income'
                    ? TColors.primary
                    : TColors.softGrey,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Text(
                  'Thu nhập',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: selectedType == 'income'
                            ? TColors.white
                            : TColors.textPrimary,
                        fontWeight: selectedType == 'income'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context, DateTime startDate, DateTime endDate) {
    return AnalysisBuilder(
      startDate: startDate,
      endDate: endDate,
      builder: (context, analysis) {
        final totalExpense = (analysis?.overall?.expense?.total ?? 0).toDouble();
        final totalIncome = (analysis?.overall?.income?.total ?? 0).toDouble();
        final total = selectedType == 'expense' ? totalExpense : totalIncome;
        final title = selectedType == 'expense' ? 'Tổng chi tiêu' : 'Tổng thu nhập';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 24, bottom: 16, left: 16, right: 16),
          decoration: BoxDecoration(
            color: TColors.primary,
            boxShadow: [
              BoxShadow(
                color: TColors.primary.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
                offset: Offset.zero,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: TColors.white,
                    ),
              ),
              AppSpacing.h4,
              PriceText(
                amount: total.toStringAsFixed(0),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: TColors.white,
                    ),
                currencyStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: TColors.white,
                      color: TColors.white,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPieChartCard(BuildContext context, CategoryAnalysisModel categoryAnalysis) {
    final categories = categoryAnalysis.categories ?? [];
    return Container(
      width: double.infinity,
      padding: AppPadding.a16,
      decoration: BoxDecoration(
        color: TColors.white,
        borderRadius: AppBorderRadius.md,
        boxShadow: [
          BoxShadow(
            color: TColors.primary.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              AppSpacing.h16,
              // Pie Chart ở trên
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
                          touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: _buildPieChartSections(categoryAnalysis),
                  ),
                ),
              ),
              AppSpacing.h16,
              // Header
              Padding(
                padding: AppPadding.h8,
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Tên',
                          style: Theme.of(context).textTheme.bodyLarge),
                    ),
                    Expanded(
                      child: Text('Phần trăm',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text('Số tiền',
                            style: Theme.of(context).textTheme.bodyLarge),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: TColors.softGrey),
              Column(
                children: categories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  final isTouched = touchedIndex == index;
                  final percentage = category.percentage ?? '0';
                  final total = category.total ?? 0.0;
                  final categoryName = category.categoryName ?? 'Khác';
                  final iconPath = CategoryIconHelper.getIconPath(categoryName, selectedType);

                  return Padding(
                    padding: AppPadding.a8,
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Image.asset(
                                iconPath,
                                width: 30,
                                height: 30,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Iconsax.more,
                                    size: 30,
                                    color: _getCategoryColor(index),
                                  );
                                },
                              ),
                              AppSpacing.w8,
                              Expanded(
                                child: Text(
                                  categoryName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: isTouched
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isTouched
                                            ? TColors.primary
                                            : TColors.textPrimary,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '$percentage%',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: isTouched
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isTouched
                                      ? TColors.primary
                                      : TColors.textPrimary,
                                ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: PriceText(
                              amount: total.toStringAsFixed(0),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: isTouched
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isTouched
                                        ? TColors.primary
                                        : TColors.textPrimary,
                                  ),
                              currencyStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    decoration: TextDecoration.underline,
                                    decorationColor: TColors.textPrimary,
                                    fontWeight: isTouched
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isTouched
                                        ? TColors.primary
                                        : TColors.textPrimary,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    CategoryAnalysisModel categoryAnalysis,
  ) {
    final categories = categoryAnalysis.categories ?? [];
    
    return categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final isTouched = touchedIndex == index;
      final radius = isTouched ? 70.0 : 60.0;
      final percentage = category.percentage ?? '0';
      final total = category.total ?? 0.0;
      final categoryName = category.categoryName ?? 'Khác';
      final iconPath = CategoryIconHelper.getIconPath(categoryName, selectedType);

      return PieChartSectionData(
        color: _getCategoryColor(index),
        value: total,
        title: '$percentage%',
        radius: radius,
        titleStyle: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: TColors.white),
        badgeWidget: Image.asset(
          iconPath,
          width: 25,
          height: 25,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Iconsax.more,
              size: 25,
              color: _getCategoryColor(index),
            );
          },
        ),
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }


  Widget _buildCategoryList(BuildContext context, CategoryAnalysisModel categoryAnalysis) {
    final categories = categoryAnalysis.categories ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final percentage = category.percentage ?? '0';
          final total = category.total ?? 0.0;
          final categoryName = category.categoryName ?? 'Khác';
          final iconPath = CategoryIconHelper.getIconPath(categoryName, selectedType);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: AppPadding.a16,
            decoration: BoxDecoration(
              color: TColors.white,
              borderRadius: AppBorderRadius.sm,
              border: Border.all(color: TColors.grey),
              boxShadow: [
                BoxShadow(
                  color: TColors.primary.withOpacity(0.05),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(index).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    iconPath,
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Iconsax.more,
                        color: _getCategoryColor(index),
                        size: 20,
                      );
                    },
                  ),
                ),
                AppSpacing.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      AppSpacing.h4,
                      Text(
                        '$percentage% tổng ${selectedType == 'expense' ? 'chi tiêu' : 'thu nhập'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: TColors.darkGrey,
                            ),
                      ),
                    ],
                  ),
                ),
                PriceText(
                  amount: total.toStringAsFixed(0),
                  color: _getCategoryColor(index),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
