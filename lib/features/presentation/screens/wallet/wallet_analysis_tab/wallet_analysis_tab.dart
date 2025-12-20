import 'package:finance_management_app/constants/app_border_radius.dart';
import 'package:finance_management_app/constants/app_padding.dart';
import 'package:finance_management_app/constants/app_spacing.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/text/price_text.dart';
import '../../../../../features/presentation/blocs/wallet_analysis/wallet_analysis_bloc.dart';
import '../../../../../utils/helpers/category_icon_helper.dart';

class WalletAnalysisTab extends StatefulWidget {
  final String? walletId;

  const WalletAnalysisTab({super.key, this.walletId});

  @override
  State<WalletAnalysisTab> createState() => _WalletAnalysisTabState();
}

enum AnalysisType { expense, income }

class _WalletAnalysisTabState extends State<WalletAnalysisTab> {
  int touchedIndex = -1;
  AnalysisType selectedPieType = AnalysisType.expense;
  AnalysisType selectedLineType = AnalysisType.expense;

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

  @override
  void didUpdateWidget(covariant WalletAnalysisTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Chỉ load khi walletId thay đổi, không load trong initState
    // vì WalletDetailScreen đã load rồi
    if (widget.walletId != oldWidget.walletId && 
        widget.walletId != null && 
        widget.walletId!.isNotEmpty) {
      _loadAnalysis();
    }
  }

  void _loadAnalysis() {
    context.read<WalletAnalysisBloc>().add(
          LoadWalletAnalysisSubmitted(walletId: widget.walletId!),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.walletId == null || widget.walletId!.isEmpty) {
      return const Center(
        child: Text('Vui lòng chọn ví để xem phân tích'),
      );
    }

    return BlocBuilder<WalletAnalysisBloc, WalletAnalysisState>(
      builder: (context, state) {
        if (state is WalletAnalysisLoading || state is WalletAnalysisInitial) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is WalletAnalysisFailure) {
          return Center(
            child: Text('Lỗi: ${state.message}'),
          );
        }

        final analysis = state is WalletAnalysisLoaded
            ? state.analysis
            : state is WalletAnalysisRefreshing
                ? state.analysis
                : null;

        if (analysis == null) {
          return const Center(
            child: Text('Không có dữ liệu phân tích'),
          );
        }

        // Map expenseByCategory từ API
        final expenseCategories = analysis.expenseByCategory
                ?.map((item) => ExpenseCategory(
                      item.categoryName ?? 'Khác',
                      (item.total ?? 0).toDouble(),
                      _getCategoryColor(analysis.expenseByCategory!.indexOf(item)),
                      Iconsax.more,
                      image: item.image,
                    ))
                .toList() ??
            [];

        // Map incomeByCategory từ API
        final incomeCategories = analysis.incomeByCategory
                ?.map((item) => ExpenseCategory(
                      item.categoryName ?? 'Khác',
                      (item.total ?? 0).toDouble(),
                      _getCategoryColor(analysis.incomeByCategory!.indexOf(item)),
                      Iconsax.more,
                      image: item.image,
                    ))
                .toList() ??
            [];

        // Map dailyTrend từ API và sắp xếp theo ngày tăng dần
        final dailyTrend = (analysis.dailyTrend ?? []).toList()
          ..sort((a, b) {
            final dateA = DateTime.tryParse(a.date ?? '');
            final dateB = DateTime.tryParse(b.date ?? '');
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return -1;
            if (dateB == null) return 1;
            return dateA.compareTo(dateB);
          });
        
        final dailyExpenses = dailyTrend.map((item) {
          final date = DateTime.tryParse(item.date ?? '');
          final day = date?.day ?? 1;
          return DailyExpense(day, (item.expense ?? 0).toDouble());
        }).toList();

        final dailyIncomes = dailyTrend.map((item) {
          final date = DateTime.tryParse(item.date ?? '');
          final day = date?.day ?? 1;
          return DailyExpense(day, (item.income ?? 0).toDouble());
        }).toList();

        final currentCategories = selectedPieType == AnalysisType.expense
            ? expenseCategories
            : incomeCategories;

        return Column(
          children: [
            _buildPieChartCard(context, currentCategories),
            AppSpacing.h32,
            _buildLineChartCard(context, dailyExpenses, dailyIncomes),
            AppSpacing.h32,
          ],
        );
      },
    );
  }

  Widget _buildLineChartCard(
    BuildContext context,
    List<DailyExpense> dailyExpenses,
    List<DailyExpense> dailyIncomes,
  ) {
    final currentData =
        selectedLineType == AnalysisType.expense ? dailyExpenses : dailyIncomes;
    if (currentData.isEmpty) {
      return Container(
        width: double.infinity,
        padding: AppPadding.a8,
        decoration: const BoxDecoration(
          color: TColors.white,
          borderRadius: AppBorderRadius.md,
        ),
        child: const Center(
          child: Text('Không có dữ liệu'),
        ),
      );
    }
    final maxY = (currentData
            .map((e) => e.amount)
            .reduce((a, b) => a > b ? a : b) *
        1.2)
        .clamp(1.0, double.infinity); // Đảm bảo maxY >= 1 để tránh lỗi horizontalInterval = 0

    return Container(
      width: double.infinity,
      padding: AppPadding.a8,
      decoration: BoxDecoration(
        color: TColors.white,
        borderRadius: AppBorderRadius.md,
        boxShadow: [
          BoxShadow(
            color: TColors.primary.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedLineType = AnalysisType.expense;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: selectedLineType == AnalysisType.expense
                        ? TColors.primary
                        : TColors.softGrey,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  padding: AppPadding.a8,
                  child: Text(
                    'Chi tiêu',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: selectedLineType == AnalysisType.expense
                              ? TColors.white
                              : TColors.textPrimary,
                          fontWeight: selectedLineType == AnalysisType.expense
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedLineType = AnalysisType.income;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: selectedLineType == AnalysisType.income
                        ? TColors.primary
                        : TColors.softGrey,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  padding: AppPadding.a8,
                  child: Text(
                    'Thu nhập',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: selectedLineType == AnalysisType.income
                              ? TColors.white
                              : TColors.textPrimary,
                          fontWeight: selectedLineType == AnalysisType.income
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.h32,
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: TColors.primary,
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        final dayIndex = touchedSpot.x.toInt();
                        if (dayIndex >= 0 && dayIndex < currentData.length) {
                          return LineTooltipItem(
                            'Ngày ${currentData[dayIndex].day} - ${(touchedSpot.y / 1000000).toStringAsFixed(1)}M',
                            const TextStyle(
                              color: TColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        return LineTooltipItem(
                          '${(touchedSpot.y / 1000000).toStringAsFixed(1)}M đ',
                          const TextStyle(
                            color: TColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: TColors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final dayIndex = value.toInt();
                        if (dayIndex >= 0 &&
                            dayIndex < currentData.length &&
                            dayIndex % 5 == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${currentData[dayIndex].day}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: TColors.darkGrey,
                                  ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Text(
                          '${(value / 1000000).toStringAsFixed(0)}M',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: TColors.darkGrey,
                                  ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: currentData.asMap().entries.map((entry) {
                      final index = entry.key.toDouble();
                      final data = entry.value;
                      return FlSpot(index, data.amount);
                    }).toList(),
                    isCurved: true,
                    color: selectedLineType == AnalysisType.expense
                        ? TColors.primary
                        : Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(
                      show: true,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: (selectedLineType == AnalysisType.expense
                              ? TColors.primary
                              : Colors.green)
                          .withOpacity(0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: maxY,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(
    BuildContext context,
    List<ExpenseCategory> expenseCategories,
  ) {
    if (expenseCategories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: AppPadding.a8,
        decoration: const BoxDecoration(
          color: TColors.white,
          borderRadius: AppBorderRadius.md,
        ),
        child: Center(
          child: Text(
            selectedPieType == AnalysisType.expense
                ? 'Không có dữ liệu chi tiêu'
                : 'Không có dữ liệu thu nhập',
          ),
        ),
      );
    }

    final totalAmount =
        expenseCategories.fold(0.0, (sum, cat) => sum + cat.amount);
    return Container(
      width: double.infinity,
      padding: AppPadding.a8,
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
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedPieType = AnalysisType.expense;
                        touchedIndex = -1;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: selectedPieType == AnalysisType.expense
                            ? TColors.primary
                            : TColors.softGrey,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      padding: AppPadding.a8,
                      child: Text(
                        'Chi tiêu',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: selectedPieType == AnalysisType.expense
                                  ? TColors.white
                                  : TColors.textPrimary,
                              fontWeight:
                                  selectedPieType == AnalysisType.expense
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedPieType = AnalysisType.income;
                        touchedIndex = -1;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: selectedPieType == AnalysisType.income
                            ? TColors.primary
                            : TColors.softGrey,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      padding: AppPadding.a8,
                      child: Text(
                        'Thu nhập',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: selectedPieType == AnalysisType.income
                                  ? TColors.white
                                  : TColors.textPrimary,
                              fontWeight: selectedPieType == AnalysisType.income
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
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
                    sections: _buildPieChartSections(
                        expenseCategories, totalAmount),
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
                children: expenseCategories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  final isTouched = touchedIndex == index;
                  final percentage =
                      (category.amount / totalAmount * 100).toStringAsFixed(1);

                  return Padding(
                    padding: AppPadding.a8,
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (category.image != null && category.image!.isNotEmpty) Image.network(
                                      category.image!,
                                      width: 30,
                                      height: 30,
                                      errorBuilder: (context, error, stackTrace) {
                                        final iconPath = CategoryIconHelper.getIconPath(
                                            category.name, selectedPieType == AnalysisType.expense ? 'expense' : 'income');
                                        return Image.asset(
                                          iconPath,
                                          width: 30,
                                          height: 30,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              category.icon,
                                              size: 30,
                                              color: category.color,
                                            );
                                          },
                                        );
                                      },
                                    ) else Builder(
                                      builder: (context) {
                                        final iconPath = CategoryIconHelper.getIconPath(
                                            category.name, selectedPieType == AnalysisType.expense ? 'expense' : 'income');
                                        return Image.asset(
                                          iconPath,
                                          width: 30,
                                          height: 30,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              category.icon,
                                              size: 30,
                                              color: category.color,
                                            );
                                          },
                                        );
                                      },
                                    ),
                              AppSpacing.w8,
                              Expanded(
                                child: Text(
                                  category.name,
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
                              amount: category.amount.toStringAsFixed(0),
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
    List<ExpenseCategory> expenseCategories,
    double totalAmount,
  ) {
    return expenseCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final isTouched = touchedIndex == index;
      final radius = isTouched ? 70.0 : 60.0;
      final percentage =
          (category.amount / totalAmount * 100).toStringAsFixed(1);

      return PieChartSectionData(
        color: category.color,
        value: category.amount,
        title: '$percentage%',
        radius: radius,
        titleStyle: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: TColors.white),
        badgeWidget: category.image != null && category.image!.isNotEmpty
            ? Image.network(
                category.image!,
                width: 25,
                height: 25,
                errorBuilder: (context, error, stackTrace) {
                  final iconPath = CategoryIconHelper.getIconPath(
                      category.name, selectedPieType == AnalysisType.expense ? 'expense' : 'income');
                  return Image.asset(
                    iconPath,
                    width: 25,
                    height: 25,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        category.icon,
                        size: 25,
                        color: category.color,
                      );
                    },
                  );
                },
              )
            : Builder(
                builder: (context) {
                  final iconPath = CategoryIconHelper.getIconPath(
                      category.name, selectedPieType == AnalysisType.expense ? 'expense' : 'income');
                  return Image.asset(
                    iconPath,
                    width: 25,
                    height: 25,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        category.icon,
                        size: 25,
                        color: category.color,
                      );
                    },
                  );
                },
              ),
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }

}

class ExpenseCategory {
  final String name;
  final double amount;
  final Color color;
  final IconData icon;
  final String? image;

  ExpenseCategory(this.name, this.amount, this.color, this.icon, {this.image});
}

class DailyExpense {
  final int day;
  final double amount;

  DailyExpense(this.day, this.amount);
}
